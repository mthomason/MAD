//
//  MADHeadlessDocument.m
//  MAD
//
//  See MADHeadlessDocument.h.  Each accessor here is MADocument's own, without the
//  document lifecycle around it: where MADocument defers to UIDocument for when to
//  read and save, this reads when it is opened and never writes.
//
//  The state is written as ivars and accessors rather than as readwrite
//  redeclarations of MADDocumentDataProtocol's properties, which a class extension
//  may not do -- the protocol is the only declaration of them.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADHeadlessDocument.h"

#import "MADArchiveManager.h"
#import "MADConstants.h"
#import "MADDatabase+Constructor.h"
#import "MADDatabaseConnection+Constructor.h"
#import "MADDocumentRenderDataSource.h"
#import "MADQueryFull.h"
#import "MADReportFormatter.h"
#import "MTPaper.h"
#import "RptqDatabase+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabaseCredentals+MADDatabaseConnection.h"
#import "RptqDocument+Extras.h"
#import "RptqDocument.h"
#import "RptqQuery+Extras.h"
#import "RptqQuery.h"
#import "RptqStoreContext.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADQuery.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/madlog.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>

@implementation MADHeadlessDocument {
	RptqStoreContext *_storeContext;
	RptqDocument *_activeDocumentModel;
	MADQueryFull *_mainQuery;
	MADDatabase *_database;
	MADDataTableFast *_dataTable;
	BOOL _refreshed;
	BOOL _limitResultsDesignMode;
	MADReportFormatter *_reportFormatter;
	MADDocumentRenderDataSource *_renderDataSource;
	MTPaper *_paper;
}

+ (instancetype)documentWithContentsOfURL:(NSURL *)url error:(NSError * __autoreleasing *)error {
	MADHeadlessDocument *document = [[self alloc] initWithFileURL: url];
	if (![document readFromURL: url error: error]) {
		return nil;
	}
	return document;
}

- (instancetype)initWithFileURL:(NSURL *)url {
	if (self = [super init]) {
		_fileURL = [url copy];
		_documentStore = [MADDocumentStore storeForDocumentURL: url];

		MADDataTableFast *dataTable = [[MADDataTableFast alloc] initWithId: self.filename.hash];
		dataTable.cacheDelegate = self;
		_dataTable = dataTable;
	}
	return self;
}

- (NSString *)filename {
	return self.fileURL.lastPathComponent.stringByDeletingPathExtension;
}

#pragma mark - Reading

- (BOOL)readFromURL:(NSURL *)url error:(NSError * __autoreleasing *)error {

	if (![url.pathExtension isEqualToString: MADFileExtentionMobleApplicationDocument]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADHeadlessDocument"
										 code: 1
									 userInfo: @{ NSLocalizedDescriptionKey:
						 [NSString stringWithFormat: @"%@ is not a .mad document.", url.lastPathComponent] }];
		}
		return NO;
	}

	MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.documentStore.gutsURL
																			   archiveURL: url];
	if (![archiveManager unarchive]) {
		os_log_error(GetMadLog(), "%s: Document unarchive failed.", __PRETTY_FUNCTION__);
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADHeadlessDocument"
										 code: 2
									 userInfo: @{ NSLocalizedDescriptionKey:
						 [NSString stringWithFormat: @"Could not unpack %@.", url.lastPathComponent] }];
		}
		return NO;
	}
	return [self.documentStore openWithError: error];
}

#pragma mark - Writing

- (BOOL)writeToURL:(NSURL *)url reproducible:(BOOL)reproducible error:(NSError * __autoreleasing *)outError {

	RptqStoreContext *context = self.storeContext;
	if (context == nil) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain: @"MADHeadlessDocument"
											code: 3
										userInfo: @{ NSLocalizedDescriptionKey: @"The document is not open; nothing to write." }];
		}
		return NO;
	}

	// The store as it stands.  A document that was only read has nothing dirty, so
	// this writes nothing -- the same call the app's save makes.
	NSError *storeError = nil;
	if (![context save: &storeError]) {
		if (outError != NULL) {
			*outError = storeError;
		}
		return NO;
	}

	// The portable store runs journal_mode = DELETE (MADStore.m), so its guts carry no
	// WAL and the checkpoint flag is honestly 1; a guts that does carry one -- nothing
	// writes one today -- gets a real checkpoint attempt and records what happened.
	BOOL checkpointed = YES;
	NSString *storePath = self.documentStore.portableStoreURL.path;
	if (storePath != nil &&
		[[NSFileManager defaultManager] fileExistsAtPath: [storePath stringByAppendingString: @"-wal"]]) {
		checkpointed = [MADDatabaseSqlite3 checkpointStoreAtURL: self.documentStore.portableStoreURL];
	}

	MADArchiveManager *archiveManager = [[MADArchiveManager alloc] initWithFileWrapperURL: self.documentStore.gutsURL
																		   archiveURL: url];
	archiveManager.checkpointed = checkpointed;
	archiveManager.reproducible = reproducible;
	if (![archiveManager archive: YES]) {
		if (outError != NULL) {
			*outError = [NSError errorWithDomain: @"MADHeadlessDocument"
											code: 4
										userInfo: @{ NSLocalizedDescriptionKey:
						 [NSString stringWithFormat: @"Could not write %@.", url.lastPathComponent] }];
		}
		return NO;
	}
	return YES;
}

#pragma mark - The definition

- (RptqStoreContext *)storeContext {
	return self.documentStore.context;
}

- (RptqDocument *)activeDocumentModel {
	if (_activeDocumentModel == nil) {
		_activeDocumentModel = [RptqDocument newDocumentReadFromManagedObjectContext: self.storeContext];
	}
	return _activeDocumentModel;
}

- (MADQueryFull *)mainQuery {
	if (_mainQuery == nil) {
		RptqQuery *query = self.activeDocumentModel.defaultDatabase.defaultQuery;
		if (query != nil) {
			MADQueryFull *mainQuery = [[MADQueryFull alloc] initWithQuery: query
															andQueryLimit: self.limitResultsDesignMode ? 50 : NSUIntegerMax];
			mainQuery.dataDelegate = self;
			// The table's group indexes are built from the query's sort order, so it
			// is applied once here, as MADocument applies it.
			[self.dataTable sortUsingDescriptors: [self readCurrentSortDescriptors]];
			_mainQuery = mainQuery;
		}
	}
	return _mainQuery;
}

- (BOOL)didRefresh {
	return _refreshed;
}

- (void)setRefreshed:(BOOL)refreshed {
	_refreshed = refreshed;
}

- (BOOL)limitResultsDesignMode {
	return _limitResultsDesignMode;
}

- (void)setLimitResultsDesignMode:(BOOL)limitResultsDesignMode {
	_limitResultsDesignMode = limitResultsDesignMode;
}

- (NSURL *)urlDataTableCache {
	NSString *cacheName = [self.dataTable newFilenameMDCache];
	return [self.cachedFilesDirectory URLByAppendingPathComponent: cacheName isDirectory: NO];
}

- (NSURL *)cachedFilesDirectory {
	return self.documentStore.cacheDirectory;
}

#pragma mark - The source database

- (MADDatabase *)database {
	if (_database == nil) {
		RptqDatabase *database = self.activeDocumentModel.hasDatabaseSchemas.anyObject;
		// The credential row conforms through its category
		// (RptqDatabaseCredentals+MADDatabaseConnection.h), which the compiler
		// cannot see from the class alone -- the same cast the app makes.
		NSObject <MADConnectionsPropertiesProtocol> *user = (NSObject <MADConnectionsPropertiesProtocol> *)database.ownedByUser;
		MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: user];
		MADDatabase *db = [MADDatabase newDatabaseWithConnection: connection];
		db.delegate = self;
		self.database = db;
	}
	return _database;
}

- (void)setDatabase:(MADDatabase *)database {
	if (_database != database) {
		_database = database;
		_database.delegate = self;
	}
}

- (void)updateDatabaseWithConnection:(MADDatabaseConnection *)databaseConnection {
	self.database = [MADDatabase newDatabaseWithConnection: databaseConnection];
}

- (NSArray *)sortDescriptors {
	return [self readCurrentSortDescriptors];
}

- (NSArray *)readCurrentSortDescriptors {
	RptqDocument *document = self.activeDocumentModel;
	return [document.defaultDatabase.defaultQuery sortDescriptorsForDatabase: self.database];
}

#pragma mark - The rows

- (MADDataTableFast *)dataTable {
	return _dataTable;
}

- (void)resetCache {
	MADDataTableFast *dataTable = [[MADDataTableFast alloc] initWithId: self.filename.hash];
	dataTable.cacheDelegate = self;
	NSError *error = nil;
	[dataTable loadFromCacheWithUrl: self.urlDataTableCache error: &error];
	// -215 is "no cache file yet", which is the normal state of a document that has
	// never been refreshed where this runs; MADocument filters it the same way.
	if (error != nil && error.code != -215) {
		os_log_error(GetMadLog(), "Error: %@", error);
	}
	_dataTable = dataTable;
}

- (void)dataTableSetDataDelegate:(id <MADDataProtocol>)delegate {
	self.dataTable.dataDelegate = delegate;
}

- (void)dataTableSort:(RptqQuery *)query {
	[self.dataTable sortUsingDescriptors: [query sortDescriptorsForDatabase: self.database]];
}

- (BOOL)dataTableMakeCache {
	NSError *error = nil;
	BOOL result = [self.dataTable cacheWithUrl: self.urlDataTableCache error: &error];
	if (error != nil) {
		os_log_error(GetMadLog(), "Error: %@", error);
	}
	return result;
}

- (NSUInteger)numberOfResults {
	return self.dataTable.rowCounter;
}

#pragma mark - The render half

// MADDocumentRenderProtocol, the same half MADocument carries and the same code:
// -prepareForQuery and -format are the sequence the viewer's reload runs, the
// formatter is the one MADReportFormatter, and every read below is
// MADDocumentRenderDataSource's (MAD_LINUX.md §9 Phase E).  What is absent is what
// only a document with a window has -- the designer's section layout managers, and
// the printing formatter the app's print dialog builds.

- (void)prepareForQuery {
	NSArray *sortDescriptors = [self readCurrentSortDescriptors];
	[self.dataTable sortUsingDescriptors:sortDescriptors];
}

- (void)format {
	[self.reportFormatter format: self.paperSize contentChanged: NO];
}

- (MTPaper *)paper {
	if (_paper == nil) {
		_paper = [[MTPaper alloc] initWithType: self.activeDocumentModel.paperType];
	}
	return _paper;
}

- (CGSize)paperSize {
	return self.paper.paperSize;
}

- (MADReportFormatter *)reportFormatter {
	if (_reportFormatter == nil) {
		_reportFormatter = [[MADReportFormatter alloc] initWithDocument: self
																options: MADReportFormatterOptionsNone];
	}
	return _reportFormatter;
}

- (void)setReportFormatter:(MADReportFormatter *)reportFormatter {
	_reportFormatter = reportFormatter;
}

- (void)resetSectionLayoutManagers {
	// The designer's per-section collection-view layout managers have no headless
	// counterpart; the formatter asks for the reset so a re-pagination cannot be
	// drawn from a stale layout, and there is nothing here to be stale.
}

- (MADDocumentRenderDataSource *)renderDataSource {
	if (_renderDataSource == nil) {
		_renderDataSource = [[MADDocumentRenderDataSource alloc] initWithDocument: self];
	}
	return _renderDataSource;
}

#pragma mark MADReportFormatterDataSource

- (NSEnumerator *)enumeratorForReportData { return [self.renderDataSource enumeratorForReportData]; }

- (BOOL)cacheExist { return [self.renderDataSource cacheExist]; }

- (NSDictionary *)dataForRow:(NSUInteger)rowID { return [self.renderDataSource dataForRow: rowID]; }

#pragma mark MADPrintPageRendererDataSourceProtocol

- (NSDictionary *)dataForRow:(NSUInteger)rowID error:(NSError *__autoreleasing *)outError {
	return [self.renderDataSource dataForRow: rowID error: outError];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error {
	return [self.renderDataSource dataForRow: rowID column: columnKey error: error];
}

- (NSArray <NSString *> *)groupLevelKeyNames { return [self.renderDataSource groupLevelKeyNames]; }

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID { return [self.renderDataSource groupLevelKeys: rowID]; }

- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber {
	return [self.renderDataSource groupKeys: rowID groupNumber: groupNumber];
}

- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys groupID:(int64_t)groupID {
	return [self.renderDataSource dataForGroups: groupKeys groupID: groupID];
}

- (MADResult *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys
				  function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy {
	return [self.renderDataSource dataForRows: rowIDs column: columnKey groups: groupKeys function: function groupBy: groupBy];
}

- (NSUInteger)rowIDFirstOfReport { return [self.renderDataSource rowIDFirstOfReport]; }

- (NSUInteger)rowIDLastOfReport { return [self.renderDataSource rowIDLastOfReport]; }

- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page { return [self.renderDataSource rowIDFirstOfPage: page]; }

- (NSUInteger)rowIDLastOfPage:(NSUInteger)page { return [self.renderDataSource rowIDLastOfPage: page]; }

- (NSDictionary *)dataForRowReportFirst { return [self.renderDataSource dataForRowReportFirst]; }

- (NSDictionary *)dataForRowReportLast { return [self.renderDataSource dataForRowReportLast]; }

- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex { return [self.renderDataSource dataForRowPageFirst: pageIndex]; }

- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex { return [self.renderDataSource dataForRowPageLast: pageIndex]; }

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex { return [self.renderDataSource rowIDsForPage: pageIndex]; }

- (void)updatePrintingReportFormatter {
	// The app's print dialog builds a second formatter through this.  There is no
	// dialog headless, and nothing here prints.
}

@end
