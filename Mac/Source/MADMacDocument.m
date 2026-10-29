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
#import <MADFoundation/MADOperationQueue.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADSqlite3/MADDataTableFast.h>

NSNotificationName const MADMacDocumentDidMutateNotification = @"MADMacDocumentDidMutateNotification";
NSNotificationName const MADMacDocumentDidRefreshNotification = @"MADMacDocumentDidRefreshNotification";

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
										userInfo:@{ NSLocalizedDescriptionKey: @"No active report store to write." }];
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
			return @"Report Header";
		case MADDocumentSectionTypePageHeader:
			return @"Page Header";
		case MADDocumentSectionTypeBody:
			return @"Report Detail";
		case MADDocumentSectionTypePageFooter:
			return @"Page Footer";
		case MADDocumentSectionTypeReportFooter:
			return @"Report Footer";
		case MADDocumentSectionTypeGroupHeader: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0 ? [NSString stringWithFormat:@"Group Header (%@)", field] : @"Group Header";
		}
		case MADDocumentSectionTypeGroupFooter: {
			NSString *field = [section.inGroup fieldNameNice];
			return field.length > 0 ? [NSString stringWithFormat:@"Group Footer (%@)", field] : @"Group Footer";
		}
		default:
			return [section localizedDisplayName] ?: @"Section";
	}
}

#pragma mark - Refresh & Export

- (void)refreshDataWithPassword:(nullable NSString *)passwordOverride
					 completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
	MADHeadlessDocument *doc = _headlessDocument;
	if (doc == nil) {
		if (completion) {
			NSError *err = [NSError errorWithDomain:@"MADMacDocument"
											   code:2
										   userInfo:@{ NSLocalizedDescriptionKey: @"No document is open." }];
			completion(NO, err);
		}
		return;
	}

	[doc invalidateQueryAndModelCaches];
	RptqQuery *query = self.rptqQuery;
	RptqDatabaseCredentals *credRow = query.inDatabase.ownedByUser;
	if (passwordOverride.length > 0 && credRow.key.length > 0) {
		[MADKeyChain savePassword:passwordOverride forKey:credRow.key];
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

	__weak typeof(self) weakSelf = self;
	refreshOp.completionBlock = ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			typeof(self) strongSelf = weakSelf;
			if (strongSelf == nil) return;
			BOOL ok = doc.refreshed;
			NSError *err = nil;
			if (!ok) {
				err = [NSError errorWithDomain:@"MADMacDocument"
										  code:3
									  userInfo:@{ NSLocalizedDescriptionKey: @"Could not refresh report data. Check the query and database connection settings." }];
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
	[_refreshQueue addOperation:refreshOp];
}

- (BOOL)exportToURL:(NSURL *)url
			 format:(NSString *)format
			  error:(NSError * _Nullable __autoreleasing *)error {
	if (_headlessDocument == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:4
									 userInfo:@{ NSLocalizedDescriptionKey: @"No active document to export." }];
		}
		return NO;
	}
	Class<MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat:format];
	if (exporterClass == Nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:5
									 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unknown export format '%@'.", format] }];
		}
		return NO;
	}
	if (![exporterClass isAvailable]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										 code:6
									 userInfo:@{ NSLocalizedDescriptionKey: [exporterClass unavailableReason] ?: @"Exporter unavailable." }];
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
