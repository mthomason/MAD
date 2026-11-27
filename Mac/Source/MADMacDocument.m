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
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADSqlite3/MADDataTableFast.h>

NSNotificationName const MADMacDocumentDidMutateNotification = @"MADMacDocumentDidMutateNotification";
NSNotificationName const MADMacDocumentDidRefreshNotification = @"MADMacDocumentDidRefreshNotification";
NSNotificationName const MADMacDocumentDidSelectQueryNotification = @"MADMacDocumentDidSelectQueryNotification";

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

@interface MADMacDocument () {
	RptqQuery *_selectedQuery;
	NSUInteger _selectionVersion;
}

@property (nonatomic, strong, readwrite, nullable) MADHeadlessDocument *headlessDocument;
@property (nonatomic, strong, readwrite) MADDesignerLayout *designerLayout;
@property (nonatomic, strong, readwrite, nullable) MADSectionsLayout *sectionsLayout;
@property (nonatomic, strong) MADOperationQueue *refreshQueue;

- (void)refreshComposedDataWithDocument:(MADHeadlessDocument *)document
					  resolvedCredential:(nullable MADCredential *)resolvedCred
							connection:(MADDatabaseConnection *)connection
							completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)prepareSelectedQueryLayout;
- (void)persistAfterLayoutCreation;
- (void)noteRecentDocumentURL:(nullable NSURL *)url;
- (void)updateWindowRepresentations;

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
	return [self databaseForQuery:self.reportQuery];
}

- (RptqQuery *)rptqQuery {
	return self.reportQuery;
}

- (BOOL)isComposed {
	return self.rptqDocument.rootQuery != nil;
}

- (RptqQuery *)rootQuery {
	return self.rptqDocument.rootQuery;
}

- (RptqQuery *)reportQuery {
	RptqQuery *root = self.rptqDocument.rootQuery;
	if (root != nil) return root;
	return self.rptqDocument.defaultDatabase.hasQueries.anyObject;
}

- (NSArray<RptqQuery *> *)allQueries {
	RptqDocument *doc = self.rptqDocument;
	if (doc == nil) return @[];
	NSMutableArray<RptqQuery *> *queries = [[NSMutableArray alloc] init];
	RptqQuery *root = doc.rootQuery;
	if (root != nil) {
		[queries addObject:root];
	}
	// Sources in a stable order: their databases in hasDatabaseSchemas order, each
	// database's single query.  The root's placeholder database is skipped (it carries
	// no source query).
	for (RptqDatabase *database in doc.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if (query == root) continue;
			if (![queries containsObject:query]) {
				[queries addObject:query];
			}
		}
	}
	// A legacy/ordinary document with no named queries still has one query.
	if (queries.count == 0) {
		RptqQuery *single = doc.defaultDatabase.hasQueries.anyObject;
		if (single != nil) [queries addObject:single];
	}
	return queries;
}

- (RptqQuery *)selectedQuery {
	if (_selectedQuery != nil) return _selectedQuery;
	return self.reportQuery;
}

- (void)setSelectedQuery:(RptqQuery *)query {
	if (query != nil) {
		// A query from another store context is not a selection this document can honour.
		if (self.managedObjectContext == nil || ![self.allQueries containsObject:query]) return;
	}
	RptqQuery *oldEffective = _selectedQuery ?: self.reportQuery;
	_selectedQuery = query;
	RptqQuery *newEffective = query ?: self.reportQuery;
	if (oldEffective == newEffective) {
		return;
	}

	_selectionVersion++;

	// A source query imported from an earlier store has no structural bands until its
	// Designer is first opened.  Creating them is a real store mutation, so it persists;
	// it is not a *selection* mutation, so it does not post the mutate notification.
	[self prepareSelectedQueryLayout];
	[self rebuildSectionsLayout];

	[[NSNotificationCenter defaultCenter] postNotificationName:MADMacDocumentDidSelectQueryNotification
														object:self];
}

- (NSUInteger)selectionVersion {
	return _selectionVersion;
}

- (BOOL)queryIsReportRoot:(nullable RptqQuery *)query {
	RptqQuery *node = query ?: self.selectedQuery;
	if (node == nil) return NO;
	return [node isLayoutRootInDocument:self.rptqDocument];
}

- (BOOL)queryShowsReportColumns:(nullable RptqQuery *)query {
	RptqQuery *node = query ?: self.selectedQuery;
	if (node == nil) return NO;
	// `isComposing` is upstream-table based, so an empty Result reads as a leaf; a
	// composition's root identity covers that case.  A Standard Report's single query is
	// also the layout root, but it is a leaf: its fields carry no output keys.
	return (self.isComposed && [self queryIsReportRoot:node]) || [node isComposing];
}

- (nullable MADDataResult *)resultForQuery:(nullable RptqQuery *)query {
	RptqQuery *node = query ?: self.selectedQuery;
	if (node == nil || _headlessDocument == nil) return nil;
	if ([self queryIsReportRoot:node]) {
		return _headlessDocument.currentResult;
	}
	return _headlessDocument.nodeResults[@(node.identifier)];
}

- (void)prepareSelectedQueryLayout {
	RptqStoreContext *context = self.managedObjectContext;
	RptqQuery *query = self.selectedQuery;
	if (context == nil || query == nil) return;
	if ([self queryIsReportRoot:query]) return;

	NSUInteger before = query.hasLayoutSections.count;
	[query ensureStructuralSectionsInContext:context];
	if (query.hasLayoutSections.count == before) return;
	[self persistAfterLayoutCreation];
}

- (void)persistAfterLayoutCreation {
	[self updateChangeCount:NSChangeDone];
	[_headlessDocument invalidateQueryAndModelCaches];
	NSError *saveError = nil;
	if ([self requiresComposedStore]) {
		[self.managedObjectContext saveComposed:&saveError];
	} else {
		[self.managedObjectContext save:&saveError];
	}
}

- (nullable RptqDatabase *)databaseForQuery:(nullable RptqQuery *)query {
	if (query == nil) return nil;
	return query.inDatabase;
}

- (BOOL)requiresComposedStore {
	RptqDocument *doc = self.rptqDocument;
	if (doc == nil) return NO;
	if (doc.rootQuery != nil) return YES;
	if (doc.hasDatabaseSchemas.count > 1) return YES;
	for (RptqDatabase *database in doc.hasDatabaseSchemas) {
		for (RptqQuery *query in database.hasQueries) {
			if (query.name.length > 0) return YES;
		}
	}
	return NO;
}

#pragma mark - Composition Authoring

- (nullable RptqQuery *)addSourceQueryNamed:(NSString *)name
							 withConnection:(MADDatabaseConnection *)connection
								credentials:(nullable MADCredential *)credentials
									  error:(NSError * _Nullable __autoreleasing *)error {
	if (name.length == 0 || connection == nil || _headlessDocument == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										  code:7
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"A query name and a database connection are required to add a source query.", @"Error: a source query was added without its name or connection.") }];
		}
		return nil;
	}

	RptqStoreContext *context = self.managedObjectContext;
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	if (context == nil || doc == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										  code:8
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No open report store to add a source query to.", @"Error: a source query was added with no open store.") }];
		}
		return nil;
	}

	MADDatabase *database = [MADDatabase newDatabaseWithConnection:connection];
	NSError *connectError = nil;
	id handle = [database connectWithConnection:connection credentals:credentials connectionError:&connectError];
	if (handle == nil || connectError != nil) {
		if (error != NULL) *error = connectError;
		return nil;
	}

	NSError *tablesError = nil;
	NSArray<MADDatabaseTable *> *tables = [database getTablesFromConnection:handle error:&tablesError];
	if (tables == nil || tablesError != nil) {
		[database closeConnection:handle];
		if (error != NULL) *error = tablesError;
		return nil;
	}

	NSMutableDictionary<NSString *, NSArray<MADDatabaseField *> *> *fieldsByTable = [[NSMutableDictionary alloc] init];
	for (MADDatabaseTable *table in tables) {
		if (table.name.length == 0) continue;
		NSArray<MADDatabaseField *> *fields = [database fieldsForTable:table.name connection:handle error:NULL];
		if (fields != nil) fieldsByTable[table.name] = fields;
	}
	[database closeConnection:handle];

	NSSet<RptqDatabase *> *before = [doc.hasDatabaseSchemas copy];
	[doc storeDatabaseConnectionDefination:database forManagedObjectContext:context];

	RptqDatabase *newDatabase = nil;
	for (RptqDatabase *candidate in doc.hasDatabaseSchemas) {
		if (![before containsObject:candidate]) {
			newDatabase = candidate;
			break;
		}
	}
	if (newDatabase == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										  code:9
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Could not register the new source database.", @"Error: a source query's database was not added to the document.") }];
		}
		return nil;
	}

	RptqQuery *newQuery = newDatabase.hasQueries.anyObject;
	newQuery.name = name;

	for (MADDatabaseTable *table in tables) {
		NSArray<MADDatabaseField *> *fields = fieldsByTable[table.name];
		if (fields.count == 0) continue;
		RptqDatabaseSchemaTable *schemaTable =
			[RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context andTable:table];
		[newDatabase addHasTablesObject:schemaTable];
		NSMutableArray<RptqDatabaseSchemaField *> *schemaFields = [[NSMutableArray alloc] initWithCapacity:fields.count];
		for (MADDatabaseField *field in fields) {
			RptqDatabaseSchemaField *schemaField =
				[RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context andField:field];
			[schemaFields addObject:schemaField];
		}
		schemaTable.hasFields = [NSOrderedSet orderedSetWithArray:schemaFields];
	}

	[self notifyDocumentMutated];
	return newQuery;
}

- (nullable RptqQuery *)addRootQueryNamed:(NSString *)name
									error:(NSError * _Nullable __autoreleasing *)error {
	RptqStoreContext *context = self.managedObjectContext;
	RptqDocument *doc = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	if (context == nil || doc == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										  code:10
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"No open report store to add a root query to.", @"Error: a root query was added with no open store.") }];
		}
		return nil;
	}

	RptqQuery *root = (RptqQuery *)[context insertObjectForEntity:NSStringFromClass([RptqQuery class]) identifier:0];
	root.name = (name.length > 0 ? name : @"root");
	// The root's database is a placeholder (the refresh coordinator resolves each source
	// from its own inDatabase); point it at the first source so ordinary accessors that
	// walk query.inDatabase still resolve.
	root.inDatabase = doc.hasDatabaseSchemas.anyObject;
	doc.rootQuery = root;

	[self notifyDocumentMutated];
	return root;
}

- (void)renameQuery:(RptqQuery *)query to:(NSString *)name {
	if (query == nil) return;
	query.name = name;
	[self notifyDocumentMutated];
}

- (nullable RptqQuery *)importChildFromURL:(NSURL *)sourceURL
									  name:(nullable NSString *)name
									  error:(NSError * _Nullable __autoreleasing *)error {
	if (sourceURL == nil || _headlessDocument == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADMacDocument"
										  code:11
									  userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"A source report is required to import a child.", @"Import error: no source report.") }];
		}
		return nil;
	}
	MADHeadlessDocument *source = [MADHeadlessDocument documentWithContentsOfURL:sourceURL error:error];
	if (source == nil) return nil;
	RptqStoreContext *sourceContext = source.storeContext;
	if (sourceContext == nil || ![sourceContext loadAllWithError:error]) return nil;
	RptqQuery *imported = [self.managedObjectContext importQueryGraphFromContext:sourceContext
														   relativePathBaseURL:sourceURL
																		  error:error];
	if (imported == nil) return nil;
	if (name.length > 0) imported.name = name;
	[self notifyDocumentMutated];
	return imported;
}

- (nullable RptqQuery *)convertToCompositionWithChildName:(nullable NSString *)childName
													 error:(NSError * _Nullable __autoreleasing *)error {
	RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext:self.managedObjectContext];
	if (document == nil) return nil;
	RptqQuery *root = [document convertToCompositionWithChildName:childName error:error];
	if (root != nil) [self notifyDocumentMutated];
	return root;
}

- (nullable RptqQueryTable *)addChildQuery:(RptqQuery *)child
									  error:(NSError * _Nullable __autoreleasing *)error {
	RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext:self.managedObjectContext];
	if (document == nil) return nil;
	RptqQueryTable *table = [document addChildQuery:child error:error];
	if (table != nil) [self notifyDocumentMutated];
	return table;
}

#pragma mark - NSDocument Lifecycle

- (void)makeWindowControllers {
	MADMacWindowController *windowController = [[MADMacWindowController alloc] initWithDocument:self];
	[self addWindowController:windowController];
}

- (void)adoptHeadlessDocument:(MADHeadlessDocument *)headlessDocument {
	_headlessDocument = headlessDocument;
	_selectedQuery = nil;
	if (headlessDocument.fileURL != nil) {
		self.fileURL = headlessDocument.fileURL;
		[self noteRecentDocumentURL:headlessDocument.fileURL];
	}
	[self rebuildSectionsLayout];
	[self updateWindowRepresentations];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *) __unused typeName error:(NSError * __autoreleasing *)outError {
	MADHeadlessDocument *doc = [MADHeadlessDocument documentWithContentsOfURL:url error:outError];
	if (doc == nil) {
		return NO;
	}
	_headlessDocument = doc;
	_selectedQuery = nil;
	[self rebuildSectionsLayout];
	[self noteRecentDocumentURL:url];
	[self updateWindowRepresentations];
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
	BOOL wrote = [_headlessDocument writeToURL:url reproducible:NO error:outError];
	if (wrote) {
		[self noteRecentDocumentURL:url];
	}
	return wrote;
}

#pragma mark - Rename & Recent Documents

- (void)noteRecentDocumentURL:(nullable NSURL *)url {
	if (url == nil || !url.isFileURL) return;
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
}

/// Keeps the window title bar and its proxy icon in step with the document's file URL.
- (void)updateWindowRepresentations {
	NSURL *url = self.fileURL;
	NSString *title = self.displayName;
	for (NSWindowController *controller in self.windowControllers) {
		NSWindow *window = controller.window;
		if (window == nil) continue;
		if (url != nil) {
			window.representedURL = url;
		}
		if (title.length > 0) {
			window.title = title;
		}
	}
}

- (BOOL)renameToURL:(NSURL *)newURL error:(NSError * _Nullable __autoreleasing *)outError {
	if (newURL == nil || !newURL.isFileURL) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:12
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"The new name is not a valid file location.", @"Rename error: the destination is not a file URL.") }];
		}
		return NO;
	}
	NSURL *oldURL = self.fileURL;
	if (oldURL == nil) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:13
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"This report has not been saved yet, so it cannot be renamed.", @"Rename error: the document has no file on disk.") }];
		}
		return NO;
	}
	if ([newURL isEqual:oldURL]) {
		return YES;
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:newURL.path]) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:14
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"A file with that name already exists. Choose a different name.", @"Rename error: the destination file exists.") }];
		}
		return NO;
	}
	if (_headlessDocument == nil) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:15
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"There is no open report to rename.", @"Rename error: the document has no open store.") }];
		}
		return NO;
	}

	// Write the current contents at the new location first; only then remove the old
	// file, so a failed write leaves the document exactly where it was.
	NSError *writeError = nil;
	if (![self writeToURL:newURL ofType:self.fileType forSaveOperation:NSSaveOperation originalContentsURL:nil error:&writeError]) {
		if (outError != NULL) *outError = writeError;
		return NO;
	}
	[[NSFileManager defaultManager] removeItemAtURL:oldURL error:NULL];

	self.fileURL = newURL;
	self.displayName = newURL.lastPathComponent;
	[self updateChangeCount:NSChangeCleared];
	[self noteRecentDocumentURL:newURL];
	[self updateWindowRepresentations];
	return YES;
}

- (BOOL)renameToDisplayName:(nullable NSString *)displayName error:(NSError * _Nullable __autoreleasing *)outError {
	NSString *trimmed = [displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmed.length == 0) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:16
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Enter a name for the report.", @"Rename error: the new name is empty.") }];
		}
		return NO;
	}
	NSURL *current = self.fileURL;
	if (current == nil) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:@"MADMacDocument"
											code:13
										userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"This report has not been saved yet, so it cannot be renamed.", @"Rename error: the document has no file on disk.") }];
		}
		return NO;
	}
	NSString *extension = current.pathExtension.length > 0 ? current.pathExtension : @"mad";
	NSString *file = trimmed.lastPathComponent;
	if (![[file.pathExtension lowercaseString] isEqualToString:[extension lowercaseString]]) {
		file = [file stringByAppendingPathExtension:extension];
	}
	NSURL *destination = [[current URLByDeletingLastPathComponent] URLByAppendingPathComponent:file];
	return [self renameToURL:destination error:outError];
}

- (IBAction)renameDocument:(nullable id)sender {
	MADMacWindowController *controller = (MADMacWindowController *)self.windowControllers.firstObject;
	if ([controller respondsToSelector:@selector(presentRenameSheet:)]) {
		[controller presentRenameSheet:sender];
		return;
	}
	[super renameDocument:sender];
}

#pragma mark - Sections & Mutation

- (void)rebuildSectionsLayout {
	RptqStoreContext *context = self.managedObjectContext;
	if (context == nil) return;
	Class dbClass = _headlessDocument.database ? [_headlessDocument.database class] : Nil;
	int64_t queryIdentifier = self.selectedQuery != nil ? self.selectedQuery.identifier : 0;
	_sectionsLayout = [[MADSectionsLayout alloc] initWithManagedObjectContext:context
																databaseClass:dbClass
															  queryIdentifier:queryIdentifier];
}

- (void)notifyDocumentMutated {
	[self updateChangeCount:NSChangeDone];
	[_headlessDocument invalidateQueryAndModelCaches];
	[self rebuildSectionsLayout];
	NSError *saveError = nil;
	if ([self requiresComposedStore]) {
		[self.managedObjectContext saveComposed:&saveError];
	} else {
		[self.managedObjectContext save:&saveError];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:MADMacDocumentDidMutateNotification
														object:self];
}

- (NSArray<RptqDocumentSection *> *)orderedSections {
	RptqDocument *doc = self.rptqDocument;
	RptqQuery *query = self.selectedQuery;
	if (doc == nil || query == nil) return @[];
	// The selected node's bands.  For the report root (the explicit composed root, or a
	// Standard Report's single query) this is the document's five sections plus its groups,
	// so the ordinary report path is unchanged.
	return [query orderedLayoutSectionsForDocument:doc] ?: @[];
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

- (void)updateDatabaseConnection:(MADDatabaseConnection *)connection
						forQuery:(nullable RptqQuery *)query
					  credentials:(nullable MADCredential *)credentials
					saveToKeychain:(BOOL)saveToKeychain {
	RptqDatabase *rptqDB = [self databaseForQuery:query];
	if (connection == nil || rptqDB == nil) {
		return;
	}

	RptqStoreContext *context = self.managedObjectContext;
	RptqDatabaseCredentals *credRow = rptqDB.ownedByUser;
	if (credRow == nil) {
		credRow = [RptqDatabaseCredentals newDatabaseCredental:context];
		rptqDB.ownedByUser = credRow;
	}
	rptqDB.databaseDriverTypeEnum = connection.databaseType;
	credRow.driverID = [connection.identifier copy];
	credRow.key = [connection.connectionString copy];
	switch (connection.databaseType) {
		case MADDatabaseTypeSqlite3: {
			NSURL *sqliteURL = ((id<MADDatabaseConnectionsPropertiesURL>)connection).databaseUrl;
			credRow.dbname = [sqliteURL.path.lastPathComponent copy];
			credRow.host = [sqliteURL.path copy];
			credRow.server = nil;
			credRow.port = 0;
			break;
		}
		case MADDatabaseTypeMySQL:
		case MADDatabaseTypePostgres:
		case MADDatabaseTypeTDS: {
			MADDatabaseConnection<MADConnectionsPropertiesProtocol> *conn =
				(MADDatabaseConnection<MADConnectionsPropertiesProtocol> *)connection;
			credRow.port = conn.port;
			credRow.host = conn.host.length > 0 ? [conn.host copy] : [conn.server copy];
			credRow.server = [conn.server copy];
			credRow.dbname = [conn.database copy];
			break;
		}
		default:
			break;
	}

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

	// A composed document (one with an explicit root) refreshes through the engine's
	// multi-source coordinator; the ordinary single-query chain below is only for the
	// ordinary report.
	if ([MADOperationRefresh documentUsesComposedRefresh: doc]) {
		[self refreshComposedDataWithDocument:doc
							resolvedCredential:resolvedCred
								  connection:conn
								  completion:completion];
		return;
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

- (void)refreshComposedDataWithDocument:(MADHeadlessDocument *)doc
					  resolvedCredential:(nullable MADCredential *)resolvedCred
							connection:(MADDatabaseConnection *)conn
							completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
	MADOperationRefreshComposed *refreshOp =
		[[MADOperationRefreshComposed alloc] initWithDocument:doc];

	MADMacCredentialsOperation *credOp = nil;
	if ([conn requiresCredentials] && resolvedCred != nil &&
		(resolvedCred.username.length > 0 || resolvedCred.password.length > 0)) {
		credOp = [[MADMacCredentialsOperation alloc] initWithCredentials:resolvedCred];
		[refreshOp addDependency:credOp];
	}

	__weak typeof(self) weakSelf = self;
	__weak MADOperationRefreshComposed *weakRefreshOp = refreshOp;
	refreshOp.completionBlock = ^{
		MADOperationRefreshComposed *strongRefreshOp = weakRefreshOp;
		NSArray<NSError *> *refreshErrors = [strongRefreshOp.errors copy];
		NSError *firstErr = refreshErrors.firstObject;
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
