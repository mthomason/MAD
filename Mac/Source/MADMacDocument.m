//
//  MADMacDocument.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacDocument.h"
#import "MADMacWindowController.h"

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADSqlite3/MADDataTableFast.h>

NSNotificationName const MADMacDocumentDidMutateNotification = @"MADMacDocumentDidMutateNotification";
NSNotificationName const MADMacDocumentDidRefreshNotification = @"MADMacDocumentDidRefreshNotification";

@interface MADMacCredentialsOperation : MADOperation <MADOperationHoldsCredentialsProtocol>
@property (nonatomic, strong, nullable) MADCredential *credentials;
@property (nonatomic, assign) BOOL gotCredentials;
@property (nonatomic, assign) BOOL manuallyInputtedCredentials;
- (instancetype)initWithCredentials:(nullable MADCredential *)credentials;
@end

@implementation MADMacCredentialsOperation

- (instancetype)initWithCredentials:(nullable MADCredential *)credentials {
	if (self = [super init]) {
		_credentials = [credentials copy];
		_gotCredentials = (credentials != nil && (credentials.username.length > 0 || credentials.password.length > 0));
		_manuallyInputtedCredentials = NO;
	}
	return self;
}

- (void)execute {
	[self finish];
}

@end

@interface MADMacDocument ()

@property (nonatomic, strong, readwrite, nullable) MADHeadlessDocument *headlessDocument;
@property (nonatomic, strong, readwrite) MADDesignerLayout *designerLayout;
@property (nonatomic, strong, readwrite, nullable) MADSectionsLayout *sectionsLayout;
@property (nonatomic, strong) MADOperationQueue *refreshQueue;

@end

@implementation MADMacDocument

- (instancetype)init {
	if (self = [super init]) {
		_designerLayout = [[MADDesignerLayout alloc] init];
		_designerLayout.delegate = self;
		_refreshQueue = [[MADOperationQueue alloc] init];
		_refreshQueue.maxConcurrentOperationCount = 1;
	}
	return self;
}

+ (BOOL)autosavesInPlace {
	return NO;
}

#pragma mark - MADocumentDesignerProtocol

- (RptqStoreContext *)managedObjectContext {
	return _headlessDocument.storeContext;
}

#pragma mark - Model Accessors

- (RptqDocument *)rptqDocument {
	RptqStoreContext *context = self.managedObjectContext;
	if (context == nil) return nil;
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	if (doc == nil) {
		doc = [RptqDocument newDocumentForManagedObjectContext:context];
	}
	return doc;
}

- (RptqDatabase *)rptqDatabase {
	return self.rptqDocument.hasDatabaseSchemas.anyObject;
}

- (RptqQuery *)rptqQuery {
	return self.rptqDatabase.hasQueries.anyObject;
}

#pragma mark - NSDocument Lifecycle

- (void)makeWindowControllers {
	MADMacWindowController *windowController = [[MADMacWindowController alloc] initWithDocument:self];
	[self addWindowController:windowController];
}

- (void)adoptHeadlessDocument:(MADHeadlessDocument *)headlessDocument {
	_headlessDocument = headlessDocument;
	if (headlessDocument.fileURL != nil) {
		self.fileURL = headlessDocument.fileURL;
	}
	[self rebuildSectionsLayout];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *) __unused typeName error:(NSError * __autoreleasing *)outError {
	MADHeadlessDocument *doc = [MADHeadlessDocument documentWithContentsOfURL:url error:outError];
	if (doc == nil) {
		return NO;
	}
	_headlessDocument = doc;
	[self rebuildSectionsLayout];
	return YES;
}

- (BOOL)writeToURL:(NSURL *)url
			ofType:(NSString *) __unused typeName
  forSaveOperation:(NSSaveOperationType) __unused saveOperation
originalContentsURL:(NSURL *) __unused absoluteOriginalContentsURL
			 error:(NSError * __autoreleasing *)outError {
	if (_headlessDocument == nil) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:1
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No active report store to write.", @"Error: the document has no open report store.") }];
		}
		return NO;
	}
	[_headlessDocument invalidateQueryAndModelCaches];
	return [_headlessDocument writeToURL:url reproducible:NO error:outError];
}

#pragma mark - Sections & Mutation

- (void)rebuildSectionsLayout {
	RptqStoreContext *context = self.managedObjectContext;
	if (context == nil) return;
	Class dbClass = _headlessDocument.database ? [_headlessDocument.database class] : Nil;
	_sectionsLayout = [[MADSectionsLayout alloc] initWithManagedObjectContext:context
																databaseClass:dbClass];
}

- (void)notifyDocumentMutated {
	[self updateChangeCount:NSChangeDone];
	[_headlessDocument invalidateQueryAndModelCaches];
	[self rebuildSectionsLayout];
	NSError *saveError = nil;
	[self.managedObjectContext save:&saveError];
	[[NSNotificationCenter defaultCenter] postNotificationName:MADMacDocumentDidMutateNotification
														object:self];
}

- (NSArray<RptqDocumentSection *> *)orderedSections {
	RptqDocument *doc = self.rptqDocument;
	if (doc == nil) return @[];

	NSMutableArray<RptqDocumentSection *> *sections = [[NSMutableArray alloc] init];
	if (doc.hasReportHeaderSection != nil) {
		[sections addObject:doc.hasReportHeaderSection];
	}
	if (doc.hasPageHeaderSection != nil) {
		[sections addObject:doc.hasPageHeaderSection];
	}

	RptqQuery *query = self.rptqQuery;
	NSArray<RptqQueryGroup *> *groups = [query sortedQueryGroups] ?: @[];
	for (RptqQueryGroup *group in groups) {
		RptqDocumentSection *header = [RptqDocumentSection headerSectionInSections:group.hasSection];
		if (header != nil) {
			[sections addObject:header];
		}
	}

	if (doc.hasDetailSection != nil) {
		[sections addObject:doc.hasDetailSection];
	}

	for (RptqQueryGroup *group in [groups reverseObjectEnumerator]) {
		RptqDocumentSection *footer = [RptqDocumentSection footerSectionInSections:group.hasSection];
		if (footer != nil) {
			[sections addObject:footer];
		}
	}

	if (doc.hasPageFooterSection != nil) {
		[sections addObject:doc.hasPageFooterSection];
	}
	if (doc.hasReportFooterSection != nil) {
		[sections addObject:doc.hasReportFooterSection];
	}
	return sections;
}

- (NSString *)displayTitleForSection:(RptqDocumentSection *)section {
	if (section == nil) return @"";
	switch (section.type) {
		case MADDocumentSectionTypeReportHeader:
			return NSLocalizedString(@"Report Header", @"Report band name; matches the designer's band list.");
		case MADDocumentSectionTypePageHeader:
			return NSLocalizedString(@"Page Header", @"Report band name; matches the designer's band list.");
		case MADDocumentSectionTypeBody:
			return NSLocalizedString(@"Report Detail", @"Report band name; the repeated detail band.");
		case MADDocumentSectionTypePageFooter:
			return NSLocalizedString(@"Page Footer", @"Report band name; matches the designer's band list.");
		case MADDocumentSectionTypeReportFooter:
			return NSLocalizedString(@"Report Footer", @"Report band name; matches the designer's band list.");
		case MADDocumentSectionTypeGroupHeader: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0
				? [[NSString alloc] initWithFormat:NSLocalizedString(@"Group Header (%@)", @"Report band name with the grouping field, e.g. Group Header (Region)."), field]
				: NSLocalizedString(@"Group Header", @"Report band name; matches the designer's band list.");
		}
		case MADDocumentSectionTypeGroupFooter: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0
				? [[NSString alloc] initWithFormat:NSLocalizedString(@"Group Footer (%@)", @"Report band name with the grouping field, e.g. Group Footer (Region)."), field]
				: NSLocalizedString(@"Group Footer", @"Report band name; matches the designer's band list.");
		}
		default:
			return [section localizedDisplayName] ?: NSLocalizedString(@"Section", @"Generic report band name.");
	}
}

#pragma mark - Connection & Credentials

- (void)updateDatabaseConnection:(MADDatabaseConnection *)connection
					 credentials:(nullable MADCredential *)credentials
				  saveToKeychain:(BOOL)saveToKeychain {
	if (connection == nil || _headlessDocument == nil) {
		return;
	}
	[_headlessDocument applyDatabaseConnection:connection];
	self.sessionCredentials = credentials;

	if ([connection requiresCredentials] && credentials != nil) {
		NSString *key = connection.connectionString;
		if (saveToKeychain && key.length > 0) {
			if (credentials.username.length > 0 && credentials.password.length > 0) {
				[MADKeyChain saveUsername:credentials.username andPassword:credentials.password forKey:key];
			} else if (credentials.username.length > 0) {
				[MADKeyChain saveUsername:credentials.username forKey:key];
			}
		}
	}
	[self notifyDocumentMutated];
}

- (nullable MADCredential *)resolvedCredentialsForDatabaseConnection:(nullable MADDatabaseConnection *)connection {
	MADDatabaseConnection *conn = connection ?: _headlessDocument.database.databaseConnection;
	NSString *username = self.sessionCredentials.username;
	NSString *password = self.sessionCredentials.password;

	RptqDatabaseCredentals *credRow = self.rptqDatabase.ownedByUser;
	NSMutableArray<NSString *> *candidateKeys = [[NSMutableArray alloc] init];
	if (conn.connectionString.length > 0) {
		[candidateKeys addObject:conn.connectionString];
	}
	if (credRow.key.length > 0 && ![candidateKeys containsObject:credRow.key]) {
		[candidateKeys addObject:credRow.key];
	}
	if (conn.identifier.length > 0 && ![candidateKeys containsObject:conn.identifier]) {
		[candidateKeys addObject:conn.identifier];
	}

	for (NSString *key in candidateKeys) {
		if (username.length == 0) {
			NSString *savedUser = [MADKeyChain usernameForKey:key];
			if (savedUser.length > 0) {
				username = savedUser;
			}
		}
		if (password.length == 0) {
			NSString *savedPass = [MADKeyChain passwordForKey:key];
			if (savedPass.length > 0) {
				password = savedPass;
			}
		}
		if (username.length > 0 && password.length > 0) {
			break;
		}
	}

	if (username.length == 0 && password.length == 0) {
		return nil;
	}
	return [[MADCredential alloc] initWithUsername:username ?: @"" andPassword:password ?: @""];
}

#pragma mark - Refresh & Export

- (void)refreshDataWithPassword:(nullable NSString *)passwordOverride
					 completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
	MADHeadlessDocument *doc = _headlessDocument;
	if (doc == nil) {
		if (completion) {
			NSError *err = [NSError errorWithDomain:@"MADMacDocument"
											   code:2
										   userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No document is open.", @"Error: an action needs an open report.") }];
			completion(NO, err);
		}
		return;
	}

	[doc invalidateQueryAndModelCaches];
	doc.refreshed = NO;

	// Ensure doc.database is initialized before checking requiresCredentials.
	MADDatabase *db = doc.database;
	MADDatabaseConnection *conn = db.databaseConnection;
	RptqQuery *query = self.rptqQuery;
	RptqDatabaseCredentals *credRow = query.inDatabase.ownedByUser ?: self.rptqDatabase.ownedByUser;

	MADCredential *resolvedCred = nil;
	if ([conn requiresCredentials]) {
		resolvedCred = [self resolvedCredentialsForDatabaseConnection:conn];
		if (passwordOverride.length > 0) {
			NSString *user = resolvedCred.username ?: @"";
			resolvedCred = [[MADCredential alloc] initWithUsername:user andPassword:passwordOverride];
			self.sessionCredentials = resolvedCred;
			NSString *key = conn.connectionString.length > 0 ? conn.connectionString : credRow.key;
			if (key.length > 0) {
				if (user.length > 0) {
					[MADKeyChain saveUsername:user andPassword:passwordOverride forKey:key];
				} else {
					[MADKeyChain savePassword:passwordOverride forKey:key];
				}
			}
		}
	}

	MADOperationRefreshInitializeMainDataTable *initTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument:doc];
	MADOperationRefreshInitialize *initOp =
		[[MADOperationRefreshInitialize alloc] initWithDocument:doc];
	[initOp addDependency:initTable];

	MADOperationRefresh *refreshOp =
		[[MADOperationRefresh alloc] initWithDocument:doc];
	[refreshOp addDependency:initTable];
	[refreshOp addDependency:initOp];

	MADMacCredentialsOperation *credOp = nil;
	if ([conn requiresCredentials] && resolvedCred != nil &&
		(resolvedCred.username.length > 0 || resolvedCred.password.length > 0)) {
		credOp = [[MADMacCredentialsOperation alloc] initWithCredentials:resolvedCred];
		[refreshOp addDependency:credOp];
	}

	__weak typeof(self) weakSelf = self;
	__weak MADOperationRefresh *weakRefreshOp = refreshOp;
	__weak MADOperationRefreshInitialize *weakInitOp = initOp;
	__weak MADOperationRefreshInitializeMainDataTable *weakInitTable = initTable;
	refreshOp.completionBlock = ^{
		MADOperationRefresh *strongRefreshOp = weakRefreshOp;
		MADOperationRefreshInitialize *strongInitOp = weakInitOp;
		MADOperationRefreshInitializeMainDataTable *strongInitTable = weakInitTable;
		NSArray<NSError *> *refreshErrors = [strongRefreshOp.errors copy];
		NSError *firstErr = refreshErrors.firstObject
			?: strongInitOp.errors.firstObject
			?: strongInitTable.errors.firstObject;
		dispatch_async(dispatch_get_main_queue(), ^{
			typeof(self) strongSelf = weakSelf;
			if (strongSelf == nil) return;
			BOOL ok = doc.refreshed && refreshErrors.count == 0 && firstErr == nil;
			NSError *err = firstErr;
			if (!ok && err == nil) {
				err = [NSError errorWithDomain:@"MADMacDocument"
										  code:3
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Could not refresh report data. Check the query and database connection settings.", @"Error: the report refresh failed with no more specific reason.") }];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:MADMacDocumentDidRefreshNotification
																object:strongSelf];
			if (completion) {
				completion(ok, err);
			}
		});
	};

	[_refreshQueue addOperation:initTable];
	[_refreshQueue addOperation:initOp];
	if (credOp != nil) {
		[_refreshQueue addOperation:credOp];
	}
	[_refreshQueue addOperation:refreshOp];
}

- (BOOL)exportToURL:(NSURL *)url
			 format:(NSString *)format
			  error:(NSError * _Nullable __autoreleasing *)error {
	if (_headlessDocument == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:4
									 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No active document to export.", @"Error: an export was requested with no open report.") }];
		}
		return NO;
	}
	Class<MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat:format];
	if (exporterClass == Nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:5
									 userInfo:@{ NSLocalizedDescriptionKey: [[NSString alloc] initWithFormat:NSLocalizedString(@"Unknown export format '%@'.", @"Error: the export format identifier is not registered. %@ is the identifier."), format] }];
		}
		return NO;
	}
	if (![exporterClass isAvailable]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:6
									 userInfo:@{ NSLocalizedDescriptionKey: [exporterClass unavailableReason] ?: NSLocalizedString(@"Exporter unavailable.", @"Error: the chosen export format is not available on this system.") }];
		}
		return NO;
	}
	id<MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	return [exporter exportDocument:_headlessDocument
							  toURL:url
							options:MADReportExportOptionsNone
							  error:error];
}

@end
