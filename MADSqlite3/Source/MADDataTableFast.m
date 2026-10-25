//
#import <Foundation/NSException.h>
//  MADDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import <MADSqlite3/MADDataTableFast.h>
#import <MADFoundation/madlib.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADDataStructures/MADIndex.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSValue.h>
#import <dispatch/dispatch.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>

#import <MADSqlite3/sqlite3.h>
#import <MADSqlite3/MADQueryCacheDeleteAllFromTable.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import <MADAPI/MADDatabaseDataBinding.h>
#import <MADAPI/MADQuery.h>

#import <MADSqlite3/MADQueryCacheSelectLimitOffsetParamaters.h>

#import <MADSqlite3/MADQuerySelectItemsForGroup.h>
#import <MADSqlite3/MADQueryCacheIndexCreate.h>
#import <MADSqlite3/MADQueryCacheSelectLimitOffset.h>
#import <MADSqlite3/MADQueryCacheAddRow.h>
#import <MADSqlite3/MADQueryCacheIndexDrop.h>
#import <MADSqlite3/MADQueryCacheAddColumn.h>
#import <MADSqlite3/MADQueryCacheVacuum.h>
#import <MADSqlite3/MADQueryCacheDropTable.h>
#import <MADSqlite3/MADQueryCacheSelectRowId.h>
#import <MADSqlite3/MADQueryCacheSelectRowIds.h>

#import <MADSqlite3/MADQueryCacheAddRowParameters.h>
#import <MADSqlite3/MADQuerySelectParameters.h>
#import <MADSqlite3/MADQueryCacheIndexDropParameters.h>
#import <MADSqlite3/MADQueryCacheIndexCreateParameters.h>
#import <MADSqlite3/MADQueryParameters.h>

#import <MADSqlite3/MADDataTableObjectEnumerator.h>
#import <MADSqlite3/MADDataTableSingleColumnEnumerator.h>

#import <Foundation/NSNull.h>
#import <Foundation/NSData.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSValue.h>

#import <MADFoundation/madlog.h>
#import <dispatch/dispatch.h>
#import <stdio.h>

static const char * MADQueueBulkAdd = "com.everydayapps.mad.cache.fast";
static os_log_t mlog;

@interface MADDataTableFast () <MADQueryParametersStandardProtocol, MADQueryParametersColumnKeysProtocol, MADQueryParametersColumnMetaProtocol, MADQueryParametersColumnDataProtocol>

#if __APPLE__
@property (nonatomic, readwrite, strong) dispatch_queue_t queueBulkAdd;
#else
// Dispatch objects are plain C pointers off Apple (os/object.h declines ObjC
// support outside Darwin), so ARC cannot own one.
@property (nonatomic, readwrite, assign) dispatch_queue_t queueBulkAdd;
#endif

@property (nonatomic, readwrite, strong) MADDatabaseSqlite3 *databaseForInserts;
@property (nonatomic, readwrite, strong) MADDatabaseSqlite3 *databaseForSelects;

@property (nonatomic, readwrite, strong) MADQueryCacheAddRow *bulkInsertQuery;
@property (nonatomic, readwrite, strong) NSMutableArray <MADDatabaseDataBinding *> *binaryBindings;

@property (nonatomic, readwrite, strong, nullable) NSURL *urlFastCache;
// Set by -initWithId:cacheDirectory: when a caller (a test, say) supplies the cache
// directory itself.  Until then the URL is resolved from the cache delegate.
@property (nonatomic, readwrite, strong, nullable) NSURL *cacheDirectory;
@property (nonatomic, readwrite, strong) NSMutableIndexSet *groupKeyIndexes;
@property (nonatomic, readwrite, strong) MADIndex *lastDataForCacheId;

@property (nonatomic, readwrite, strong) id rowDataLastInserted;

@property (nonatomic, readwrite, assign) BOOL bulkInsertLoop;
@property (nonatomic, readwrite, assign) BOOL sortDescriptorsSet;

// The row insert itself.  -addRow:error: runs this under queueBulkAdd so a running
// bulk insert cannot race -endBulkInsert's teardown of the prepared statement.
- (bool)insertRow:(NSArray<id> *)row error:(NSError * __autoreleasing *)error;
// Asks the cache file how many rows it actually holds.  Falls back to the stored
// counter when the file cannot answer (no table yet, or no connection).
- (NSUInteger)recountRows;

// The directory this table's cache file belongs in: whichever one the caller set,
// else the cache delegate's, else the application group's cache directory.
- (NSURL *)cacheDirectoryURL;
// Turns what a cache plist or keyed archive stored into this table's cache URL.  A
// file name is resolved against -cacheDirectoryURL; a legacy absolute URL is kept
// only while the directory it names still exists.  nil asks -urlFastCache to build
// one.  See the note in -loadWithPlist:error:.
- (NSURL *)cacheUrlForStoredValue:(nullable NSString *)stored;

@end

@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;
	// Prepared, parameterized select per column ("SELECT c<name> FROM t<tag> WHERE
	// rowid = ?"), reused across -dataForRow:column:error: calls so a page draw pays
	// one prepare per column instead of one per cell.  Finalized on dealloc and
	// dropped whenever the connection or the table is rebuilt.
	NSMutableDictionary<NSString *, NSValue *> *_selectStatementsByColumn;
}

+ (void)initialize {
	if (self == [MADDataTableFast self]) {
		NSString *name = NSStringFromClass([MADDataTableFast class]);
		mlog = os_log_create("com.mad", name.UTF8String);
		os_log_debug(mlog, "%@ logging initialized.", name);
	}
}

+ (NSString *)keyUrlFastCache { return NSStringFromSelector(@selector(urlFastCache)); }
+ (NSString *)keyTag { return NSStringFromSelector(@selector(tag)); }
+ (NSString *)keyBulkInsertLoop { return NSStringFromSelector(@selector(bulkInsertLoop)); }
+ (NSString *)keySortDescriptorsSet { return NSStringFromSelector(@selector(sortDescriptorsSet)); }
+ (NSString *)keyGroupKeys { return NSStringFromSelector(@selector(groupKeyIndexes)); }
+ (NSString *)keyColumns { return NSStringFromSelector(@selector(columns)); }

+ (NSDictionary *)newQueryDefinitionSelect: (NSArray *)columnKeys
								 tableName: (NSString *)tableName
						   sortDescriptors: (NSArray *)sortDescriptors {
	NSNumber *keyColumnKeys = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersColumnKeys];
	NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersTableNames];
	NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersSortDesc];
	NSDictionary *definition = [[NSDictionary alloc] initWithObjectsAndKeys:
								columnKeys, keyColumnKeys,
								tableName, keyTableName,
								sortDescriptors, keySortDescriptors,
								nil];
	return definition;
}

+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
								 withLimit:(NSUInteger)limit
								 andOffset:(NSUInteger)offset
								 dropRowid:(BOOL)droprowid {
	NSMutableDictionary *queryDefination = [[NSMutableDictionary alloc] initWithDictionary:queryDefinationSelect];
	NSNumber *limitw = [[NSNumber alloc] initWithUnsignedInteger: limit];
	NSNumber *offsetw = [[NSNumber alloc] initWithUnsignedInteger: offset];
	NSNumber *keyLimit = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersLimit];
	NSNumber *keyOffset = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersOffset];
	queryDefination[keyLimit] = limitw;
	queryDefination[keyOffset] = offsetw;
	if (droprowid) {
		NSNumber *keyDropRow = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersDropRowid];
		queryDefination[keyDropRow] = @YES;
	}
	return  queryDefination;
	
}

+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
								 withLimit:(NSUInteger)limit
								 andOffset:(NSUInteger)offset {
	return [self newQueryDefinitionSelect:queryDefinationSelect withLimit:limit
								andOffset:offset
								dropRowid:NO];
}

- (void)dealloc {
	if (_statementInsert) {
		sqlite3_finalize(_statementInsert);
		_statementInsert = NULL;
	}
	[self invalidateSelectStatementCache];
}

- (instancetype)initWithId:(NSUInteger)objectId {
	return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId cacheDirectory:(NSURL *)cacheDirectory {
	if (self = [self initWithId:objectId fromCache:YES]) {
		self.cacheDirectory = cacheDirectory;
		if (cacheDirectory != nil) {
			[self reopenDbConnection];
		}
	}
	return self;
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
	if (self = [super initWithId:objectId fromCache:fromCache]) {
		
		dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
		self.queueBulkAdd = queue;
		
		_bulkInsertLoop = NO;
		self.tag = objectId;
		_sortDescriptorsSet = NO;
		
		NSMutableIndexSet *groupKeyIndexes = [[NSMutableIndexSet alloc] init];
		self.groupKeyIndexes = groupKeyIndexes;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		
		dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
		self.queueBulkAdd = queue;
		
		NSString *storedCache = [decoder decodeObjectForKey: [MADDataTableFast keyUrlFastCache]];
		self.urlFastCache = [self cacheUrlForStoredValue: storedCache];
		
		NSNumber *tag = [decoder decodeObjectForKey: [MADDataTableFast keyTag]];
		self.tag = tag.unsignedIntegerValue;
		
		_bulkInsertLoop = [decoder decodeBoolForKey: [MADDataTableFast keyBulkInsertLoop]];
		_sortDescriptorsSet = [decoder decodeBoolForKey: [MADDataTableFast keySortDescriptorsSet]];
		
		NSIndexSet *groupKeysArray = [decoder decodeObjectForKey: [MADDataTableFast keyGroupKeys]];
		NSMutableIndexSet *groupKeys = [[NSMutableIndexSet alloc] initWithIndexSet: groupKeysArray];
		self.groupKeyIndexes = groupKeys;
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	// The file name alone, never the absolute URL: see -copyPlist and docs/project/BUGS.md.
	[encoder encodeObject: self.urlFastCache.lastPathComponent forKey: [MADDataTableFast keyUrlFastCache]];
	
	NSNumber *objid = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
	[encoder encodeObject: objid forKey: [MADDataTableFast keyTag]];
	[encoder encodeBool: _bulkInsertLoop forKey: [MADDataTableFast keyBulkInsertLoop]];
	[encoder encodeBool: _sortDescriptorsSet forKey: [MADDataTableFast keySortDescriptorsSet]];
	
}

- (NSDictionary *)copyPlist {
	NSDictionary *superPlist = [super copyPlist];
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
	
	NSURL *urlFastCache = self.urlFastCache;
	if (urlFastCache == nil) {
		os_log_error(mlog, "urlFastCache is nil.");
	}
	NSAssert(urlFastCache != nil, @"We need a url.");

	// The file name alone.  An absolute URL also names the application's data
	// container, whose UUID changes on reinstall, so a path written today points
	// into a directory that may be gone by the time it is read -- which took the
	// app down on the first document tap.  The container in use is what
	// -cacheUrlForStoredValue: resolves the name against.  See docs/project/BUGS.md.
	NSString *filename = urlFastCache.lastPathComponent;
	NSAssert(filename != nil, @"We need a path.");
	plist[[MADDataTableFast keyUrlFastCache]] = [[NSString alloc] initWithString: filename];
	
	NSNumber *tag = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
	plist[[MADDataTableFast keyTag]] = tag;
	
	NSNumber *bulkInsert = [[NSNumber alloc] initWithBool:_bulkInsertLoop];
	plist[[MADDataTableFast keyBulkInsertLoop]] = bulkInsert;
	
	if (self.groupKeyIndexes != nil) {
		NSError *error = nil;
#if __APPLE__
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.groupKeyIndexes requiringSecureCoding:YES error:&error];
#else
		// GNUstep has no secure coding and the strict archive is nil; the
		// permissive archive is the same coder without the hardening.
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.groupKeyIndexes requiringSecureCoding:NO error:&error];
#endif
		if (error != nil) {
			os_log_error(mlog, "%s: NSKeyedArchiver Error: %@", __PRETTY_FUNCTION__, error);
		} else if (data) {
			[plist setObject:data forKey:[MADDataTableFast keyGroupKeys]];
		}
	} else {
		os_log_error(mlog, "%s: groupKeyIndexes is nil.", __PRETTY_FUNCTION__);
	}
	
	NSNumber *sortSet = [[NSNumber alloc] initWithBool:_sortDescriptorsSet];
	NSString *keySortDescriptorsSet = [MADDataTableFast keySortDescriptorsSet];
	plist[keySortDescriptorsSet] = sortSet;
	return plist;
}

// The file a cache is read from sits beside the .maddb, so its directory is this
// table's cache directory and is what a stored file name is resolved against.  That
// is the container-independence the format fix is for: the name travels, the
// container does not.  See -cacheUrlForStoredValue:.
- (BOOL)loadFromCacheWithUrl:(NSURL *)url error:(NSError * __autoreleasing *)outError {
	NSURL *directory = url.URLByDeletingLastPathComponent;
	if (directory != nil && ![directory isEqual: self.cacheDirectory]) {
		self.cacheDirectory = directory;
		self.urlFastCache = nil;	// resolve again, from the directory just adopted
	}
	return [super loadFromCacheWithUrl: url error: outError];
}

- (BOOL)loadWithPlist:(nonnull NSDictionary *)plist error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
	NSError *plistError = nil;
	BOOL loadSuperResult = [super loadWithPlist:plist error:&plistError];
	if (plistError != nil) {
		os_log_error(mlog, "loadWithPlist Error: %@", plistError);
	}
	if (!loadSuperResult) {
		os_log_error(mlog, "Super loadWithPlist failed.");
	}

	dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
	self.queueBulkAdd = queue;
	
	// What is stored is the file name, which -cacheUrlForStoredValue: resolves
	// against the cache directory in use, so the cache outlives the data container
	// it was written in.  A plist written by an older build still holds an absolute
	// URL; that form is honoured only while the directory it names exists, because
	// SQLITE_OPEN_CREATE cannot create a file inside a directory that is gone, and
	// -openDatabaseWithFlags: asserts when the open fails.  A URL that cannot be
	// used, and a name that cannot be resolved, are both left nil, which asks
	// -urlFastCache to build one.  See docs/project/BUGS.md.
	NSString *storedCache = plist[[MADDataTableFast keyUrlFastCache]];
	if (storedCache.length > 0) {
		self.urlFastCache = [self cacheUrlForStoredValue: storedCache];
	} else {
		os_log_error(mlog, "[MADDataTableFast %p loadWithPlist] urlFastCache string from plist is nil.", self);
	}
	
	NSNumber *tagWrapper = [plist[[MADDataTableFast keyTag]] copy];
	self.tag = tagWrapper.unsignedIntegerValue;
	
	NSNumber *bulkInsertLoopWrapper = plist[[MADDataTableFast keyBulkInsertLoop]];
	_bulkInsertLoop = bulkInsertLoopWrapper.boolValue;
	
	NSData *groupKeysData = plist[[MADDataTableFast keyGroupKeys]];
	NSError *error = nil;
	NSIndexSet * __nullable groupKeysArray = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSIndexSet class]
																			   fromData:groupKeysData
																				  error:&error];
	if (error != nil) {
		os_log_error(mlog, "NSKeyedArchiver Error: %@", error.localizedDescription);
	}

	if (groupKeysArray != nil) {
		self.groupKeyIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:(NSIndexSet *)groupKeysArray];
	} else {
		self.groupKeyIndexes = [[NSMutableIndexSet alloc] init];
	}

	[self reopenDbConnection];
	// The plist carries the row counter but not the rows -- those live in the cache
	// file.  Ask the file, so a counter that drifted from it cannot survive a reload.
	self.rowCounter = [self recountRows];
	return YES;
}

- (NSUInteger)recountRows {
	MADDatabaseSqlite3 *database = self.databaseForSelects;
	sqlite3 *handle = (database != nil) ? (sqlite3 *)database->_database : NULL;
	if (handle == NULL) {
		return self.rowCounter;
	}

	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT COUNT(*) FROM %@;", [self tableName]];
	sqlite3_stmt *statement = NULL;
	if (sqlite3_prepare_v2(handle, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK || statement == NULL) {
		// No table yet -- a table that has never been populated.  The plist's value
		// is all there is to go on.
		return self.rowCounter;
	}

	NSUInteger rows = self.rowCounter;
	if (sqlite3_step(statement) == SQLITE_ROW) {
		rows = (NSUInteger)sqlite3_column_int64(statement, 0);
	}
	sqlite3_finalize(statement);
	return rows;
}

- (NSString *)filenameCacheMadDB {
	NSString *tag = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.tag];
	return [tag stringByAppendingPathExtension:@"maddb"];
}

// Resolved once and then held: the app delegate is not cheap to ask on every read,
// and the answer only changes when the cache delegate does.
- (NSURL *)urlFastCache {
	NSURL *url = _urlFastCache;
	if (url == nil) {
		url = [self newUrlFastCache];
		_urlFastCache = url;
	}
	return url;
}

// Whichever directory the caller supplied, else the cache delegate's, else the
// application group's.  nil when none of them can answer, which leaves the caller
// without a URL rather than with a wrong one.
- (NSURL *)cacheDirectoryURL {
	NSURL *cacheDirectory = self.cacheDirectory;
	if (cacheDirectory != nil) {
		return cacheDirectory;
	}
	if (self.cacheDelegate != nil) {
		return [self.cacheDelegate cachedFilesDirectory].copy;
	}
	id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
	id groupIdentifier = [appDelegate groupIdentifier].copy;
	return [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier: groupIdentifier];
}

- (NSURL *)cacheUrlForStoredValue:(NSString *)stored {
	if (stored.length == 0) {
		return nil;
	}

	// An absolute URL is the form older caches were written in.  It names the data
	// container as well as the file, so it is only usable while that container --
	// and therefore its directory -- is still there.
	NSURL *url = [NSURL URLWithString: stored];
	if (url.scheme.length > 0) {
		NSURL *directory = url.URLByDeletingLastPathComponent;
		NSString *directoryPath = directory.path;
		if (directoryPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
			return url;
		}
		os_log_error(mlog, "[MADDataTableFast %p] the cache directory %@ is gone; recomputing this cache's url for the container in use.", self, directoryPath ?: stored);
		return nil;
	}

	// A file name, which is what this class writes now.  Anything else is not a
	// path this can resolve and is treated as absent.
	if ([stored containsString: @"/"]) {
		os_log_error(mlog, "[MADDataTableFast %p] the stored cache url %@ names no file; recomputing this cache's url.", self, stored);
		return nil;
	}
	return [[self cacheDirectoryURL] URLByAppendingPathComponent: stored isDirectory: NO];
}

- (NSURL *)newUrlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory = [self cacheDirectoryURL];
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
	NSAssert(NO, @"Not implemented");
	return nil;
}

- (void)setCacheDelegate:(id<MADCacheProtocol>)cacheDelegate {
	// The URL is resolved from the delegate's directory, so a new delegate means a
	// new URL; drop the held one and let the next read resolve it again.
	_urlFastCache = nil;
	_cacheDelegate = cacheDelegate;
	[self reopenDbConnection];
}

- (void)reopenDbConnection {
	// The prepared selects belong to the connection being replaced; drop them
	// before the swap so they are finalized against a still-open database.
	[self invalidateSelectStatementCache];
	NSURL *urlFastCache = self.urlFastCache;
	id <MADCacheProtocol> cacheDelegate = _cacheDelegate;
	MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
	database.databaseConnection = connection;
	[(MADDatabaseSqlite3 *)database openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
	self.databaseForInserts = database;
	
	MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
	MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
	[databaseSelect setDatabaseConnection:connectionSelect];
	[databaseSelect openDatabase];
	databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
	self.databaseForSelects = databaseSelect;
}

- (NSString *)tableName {
	char buf[22];
	buf[0] = 't';
	ultoa(self.tag, (buf+1));
	char *ptr = buf;
	NSString *tableName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
	// The buffer is ASCII "t<decimal>", so the fallback is unreachable; it keeps
	// the nonnull return contract if the conversion ever fails.
	return tableName != nil ? tableName : [[NSString alloc] initWithFormat:@"t%lu", (unsigned long)self.tag];
}

- (NSString *)columnNameForIdentifier:(NSString *)identifier {
	char buf[22];
	buf[0] = 'c';
	ultoa(identifier.hash, (buf+1));
	char *ptr = buf;
	return [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
}

- (NSString *)queryTableName {
	return [self tableName];
}
- (NSArray <NSString *> *)queryColumnKeys {
	return [self columnKeys];
}
- (NSDictionary *)queryColumns {
	return [self columns];
}
- (NSArray *)queryRowData {
	return [self rowDataLastInserted];
}
- (void)addColumn:(MADDataColumn *)column {
	BOOL createTable = self.columnKeys.count == 0;
	char buf[22];
	buf[0] = 'c';
	NSAssert(column.identifier == column.fieldName, @"Column identifier and field name should be the same.");
	ultoa(column.identifier.hash, (buf+1));
	//ultoa(column.fieldName.hash, (buf+1));
	char *ptr = buf;
	NSString *columnName = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
	[self.columnKeys addObject:columnName];
	
	[self addColumn: column
			toTable: [self tableName]
		 columnName: columnName
		createTable: createTable
			 unique: NO];
	self.columns[columnName] = column;
}

- (void)setupGroupKeyIndexes {
	NSArray <NSSortDescriptor *> *sortDescriptors = self.sortDescriptors;
	NSArray <NSString *> *columnKeys = self.columnKeys;
	
	[_groupKeyIndexes removeAllIndexes];
	NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithCapacity: sortDescriptors.count];
	NSUInteger index = NSNotFound;
	for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
		NSString *key = sortDescriptor.key;
		if (key == nil) {
			// -indexOfObject: would raise anyway; make the diagnosis name the cause.
			[NSException raise:NSInvalidArgumentException
						format:@"A sort descriptor used for grouping has no key."];
		}
		index = [columnKeys indexOfObject:key];
		if (index != NSNotFound) {
			NSNumber *columnIndex = [[NSNumber alloc] initWithUnsignedInteger: index];
			[_groupKeyIndexes addIndex:index];
			[groupKeys addObject:columnIndex];
		}
	}
}

- (void)addColumn:(MADDataColumn *)column
		  toTable:(NSString *)table
	   columnName:(NSString *)columnName
	  createTable:(BOOL)create
		   unique:(BOOL)unique {

	// Creating or altering the table bumps its schema cookie, so any prepared
	// select against it is stale from here on.
	[self invalidateSelectStatementCache];

	NSString *columnAffinity = [MADDatabaseSqlite3 sqlite3NativeType: column.type];
	MADQueryCache *query = [[MADQueryCacheAddColumn alloc] initWithTableName: table
																  columnName: columnName
																	  column: column
																 createTable: create
															uniqueColumnHack: unique
															  columnAffinity: columnAffinity];
	query.database = _databaseForInserts;

	NSError *errorQuery = nil;
	BOOL insertSuccess = [_databaseForInserts executeQuery:query withError:&errorQuery];
	if (!insertSuccess) {
		if (!_databaseForInserts) {
			os_log_error(OS_LOG_DEFAULT, "Database for inserts is null: %s", __PRETTY_FUNCTION__);
		} else {
			os_log_error(OS_LOG_DEFAULT, "%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
		}
	}
	if (errorQuery != nil) {
		os_log_error(mlog, "Error: %@", errorQuery);
	}
}

- (NSMutableArray <MADDatabaseDataBinding *> *)binaryBindings {
	if (self.binaryBindings == nil) {
		NSMutableArray <MADDatabaseDataBinding *> *binaryBindings = [[NSMutableArray alloc] init];
		self.binaryBindings = binaryBindings;
	}
	return self.binaryBindings;
}

- (bool)addRow:(NSArray<id> *)row error:(NSError * __autoreleasing *)error {
	__block bool result = true;
	__block NSError *rowError = nil;
	void (^insert)(void) = ^{
		NSError *insertError = nil;
		result = [self insertRow:row error:&insertError];
		rowError = insertError;
	};

	// queueBulkAdd is nil only for a table that never finished initializing; anything
	// constructed normally has one, so the insert is serialized against
	// -endBulkInsert's barrier as a rule rather than an accident.
	dispatch_queue_t queue = self.queueBulkAdd;
	if (queue != nil) {
		dispatch_sync(queue, insert);
	} else {
		insert();
	}

	if (rowError != nil && error != NULL) {
		*error = rowError;
	}
	return result;
}

- (bool)insertRow:(NSArray<id> *)row error:(NSError * __autoreleasing *)error {
	bool result = true;
	_rowDataLastInserted = row;
	self.rowCounter++;
	
	if (self.groupKeyIndexes == nil) {
		[self setupGroupKeyIndexes];
	}
	
	sqlite3 *sqlite_database = _databaseForInserts->_database;
	
	if (_bulkInsertLoop) {
		[self.bulkInsertQuery update];
		
		BOOL success = YES;
		
		if (_statementInsert == NULL) {

			NSString *sql = [[NSString alloc] initWithString:[_bulkInsertQuery getSql:nil]];
			char *csql = sqlite3_mprintf("%s", sql.UTF8String);
			int prepare_result = sqlite3_prepare_v2(sqlite_database, csql, -1, &_statementInsert, NULL);
			NSAssert(prepare_result == SQLITE_OK, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(sqlite_database));
			success = prepare_result == SQLITE_OK;
			sqlite3_free(csql);
			csql = NULL;
			
		}
		
		NSUInteger columnCounter = 0;
		for (id docObject in row) {
			NSString *fieldName = self.columnKeys[columnCounter];
			MADDataColumn *column = self.queryColumns[fieldName];
			
			MADDatabaseDataBinding *databinding = [[MADDatabaseDataBinding alloc] initWithDataType: column.type
																						fieldIndex: columnCounter
																							 value: docObject];
			[_databaseForInserts bindStatement:(void **)&_statementInsert withBindings:databinding];
			columnCounter++;
		}
		
		NSAssert(success, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(sqlite_database));
		
		// Execute the statement
		if (sqlite3_step(_statementInsert) != SQLITE_DONE) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3239 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding] ?: @""
				}];
				result = false;
			}
		}
		
		// Clear bindings and reset the statement
		if (sqlite3_clear_bindings(_statementInsert) != SQLITE_OK) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3240 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error Clear Bindings", @"Error Clear Bindings"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding] ?: @""
				}];
				result = false;
			}
		}
		
		if (sqlite3_reset(_statementInsert) != SQLITE_OK) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3240 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error Reset", @"Error Reset"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding] ?: @""
				}];
				result = false;
			}
		}
	} else {
		MADQuery *query = [[MADQueryCacheAddRow alloc] initWithObject:self];
		NSError * __autoreleasing errorQuery = NULL;
		
		__unused BOOL success = [_databaseForInserts executeQuery:query withError:&errorQuery];
		NSAssert(success, @"%s at %s", sqlite3_errmsg(sqlite_database),
				 __PRETTY_FUNCTION__);
	}
	return result;
}

// A bulk insert reaches here once per row, and the insert path autoreleases per row -- the
// binding statement does.  A caller that drains only at the end of its own loop holds the
// whole result set instead of one row of it: at 200000 rows that measured 256 bytes per row,
// about 49 MB, which is the footprint a large report gets killed for.  The pool belongs here
// because this is the only place that knows a row has ended, and because the caller is a
// generic row loop over a <MADDataTableWriting> with no reason to know it needs one.
- (void)addRowWithDataForFieldKeys:(NSDictionary <NSString *, id> *)row {
	@autoreleasepool {

		NSArray <NSString *> *columnKeys = self.columnKeys;
		NSMutableArray *rowData = [[NSMutableArray alloc] initWithCapacity:columnKeys.count];
		for (NSString *columnDefKey in columnKeys) {

			MADDataColumn *columnDef = self.columns[columnDefKey];
			id obj = row[columnDef.fieldName];
			if (obj == nil) obj = [NSNull null];
			[rowData addObject:obj];

		}
		NSError * __autoreleasing error = nil;
		[self addRow:rowData error:&error];

	}
}

- (void)sortUsingDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors {
	[_groupKeyIndexes removeAllIndexes];
	
	if (self.columnKeys.count > 0 && self.columns.count > 0 && sortDescriptors.count > 0) {
		
		NSMutableArray <__kindof NSSortDescriptor *> *newSortDescriptors = [[NSMutableArray <__kindof NSSortDescriptor *> alloc] initWithCapacity:sortDescriptors.count];
		
		for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
			NSUInteger groupKeyCounter = 0;
			
			for (NSString *columnKey in self.columnKeys) {
				MADDataColumn *column = self.columns[columnKey];
				NSString *key = sortDescriptor.key;
				if (key.length > 0 && [column.fieldName isEqualToString: key]) {
					
					SEL sortAlgo = MADDataTypeSelectorForSorting(column.type);
					NSSortDescriptor *newSortDescriptor;
					newSortDescriptor = [[NSSortDescriptor alloc] initWithKey: columnKey
																	ascending: sortDescriptor.ascending
																	 selector: sortAlgo];
					[newSortDescriptors addObject:newSortDescriptor];
					
					[_groupKeyIndexes addIndex:groupKeyCounter];
					
					break;
				}
				groupKeyCounter++;
			}
			if (newSortDescriptors.count == sortDescriptors.count) {
				_sortDescriptorsSet = YES;
				self.sortDescriptors = newSortDescriptors;
			}
		}
		
	} else {
		NSMutableArray *sd = [[NSMutableArray alloc] initWithArray:sortDescriptors];
		self.sortDescriptors = sd;
	}
}

- (void)removeAllObjects {
	[self reopenDbConnection];
	[self dropIndex];
	[self dropTable];
	[self vacuumCacheDb];
	
	self.lastDataForCacheId = nil;
	[self.columnKeys removeAllObjects];
	[self.columns removeAllObjects];
	self.rowCounter = 0;
	
}

- (NSArray *)sortDescriptorIndexGroupsForSortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors {
	if (sortDescriptors.count == 0) {
		return @[];
	}
	NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count + 1];
	[results addObject:sortDescriptors];
	for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
		NSArray *group = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[results addObject:group];
	}
	return results;
}

- (NSArray <NSString *> *)columnKeysForSortDescriptors {
	NSArray *sortDescriptors = self.sortDescriptors;
	NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
	for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
		NSString *key = [sortDescriptor.key copy];
		[columnKeys addObject:key];
	}
	return columnKeys;
}

- (NSString *)cacheTableNameForGroupLevel:(NSUInteger)groupLevel {
	char buf[22];
	buf[0] = 's';
	ultoa(groupLevel, (buf+1));
	char *ptr = buf;
	return [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
}

- (NSString *)indexNameForGroupLevel:(NSUInteger)groupLevel andIndex:(NSUInteger)index {
	char buf[22];
	buf[0] = 'i';
	ultoa(groupLevel, (buf+1));
	ultoa(index, (buf+1));
	char *ptr = buf;
	return [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
}

- (void)createIndex {
	id <MADDataProtocol> dataDelegate = self.dataDelegate;
	
	NSArray <NSSortDescriptor *> *sortDescriptors = [dataDelegate sortDescriptors];
	[self.sortDescriptors setArray:sortDescriptors];
	[self sortUsingDescriptors:self.sortDescriptors];
	
	NSUInteger sortDescCtr = self.sortDescriptors.count;
	NSArray *sortDescriptorGroups = [self sortDescriptorIndexGroupsForSortDescriptors: self.sortDescriptors];
	
	NSUInteger groupCounter = 0;
	NSMutableArray *queries = [[NSMutableArray alloc] initWithCapacity:sortDescriptorGroups.count];
	
	MADQueryCacheIndexCreateParameters *parameters = [[MADQueryCacheIndexCreateParameters alloc] init];
	parameters.columns = self.columns;
	parameters.tableName = [self.tableName copy];
	
	for (NSArray *sortDescriptorGroup in sortDescriptorGroups) {
		
		if (sortDescriptorGroup.count > 0) {
			parameters.sortDescriptors = sortDescriptorGroup;
			parameters.groupName = [self indexNameForGroupLevel: sortDescCtr
													   andIndex: groupCounter];
			
			MADQuery <MADQueryDataDelegateProtocol> *queryCreateIndex = [[MADQueryCacheIndexCreate alloc] initWithObject:parameters];
			queryCreateIndex.dataDelegate = dataDelegate;
			
			NSError *sqlError = nil;
			NSString *sqlResult = [queryCreateIndex getSql: &sqlError];
			if (sqlError != nil) {
				os_log_error(mlog, "%s SQL Error: %@", __PRETTY_FUNCTION__, sqlError);
			}
			if (sqlResult.length > 0) {
				queries[groupCounter] = [sqlResult copy];
			}
			groupCounter++;
		}
	}
	NSString *queryString = [queries componentsJoinedByString:@";\n"];
	char *zErr = NULL;
	int exec_result = sqlite3_exec(self.databaseForInserts.databaseHandle, queryString.UTF8String, NULL, NULL, &zErr);
	NSAssert(exec_result != SQLITE_ABORT, @"%s at %s", sqlite3_errmsg(self.databaseForInserts.databaseHandle), __PRETTY_FUNCTION__);
}

- (void)dropIndex {
	NSUInteger sortDescCtr = self.sortDescriptors.count;
	NSUInteger groupCounter = 0;
	for (NSUInteger i = 0; i<sortDescCtr; i++) {
		NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
		NSNumber *key = [[NSNumber alloc] initWithUnsignedInteger: MADQueryCacheIndexDropIndexName];
		NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys: groupName, key, nil];
		NSError *errorQuery = nil;
		MADQuery *query = [[MADQueryCacheIndexDrop alloc] initWithObject:parameters];
		BOOL success = [self.databaseForInserts executeQuery:query withDataTable:self andError:&errorQuery];
		if (errorQuery != nil) {
			os_log_error(mlog, "%s SQL Error: %@", __PRETTY_FUNCTION__, errorQuery);
		}
		NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
		errorQuery = NULL;
	}
}

- (void)vacuumCacheDb {
	NSError * __autoreleasing errorQuery = NULL;
	MADQuery *queryVacuum = [[MADQueryCacheVacuum alloc] init];
	BOOL success = [self.databaseForInserts executeQuery:queryVacuum withError:&errorQuery];
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
	// VACUUM rewrites the file but keeps every row, so the counter still describes it.
	// Deliberately not zeroed: -removeAllObjects is the only caller that wants an empty
	// table, and it zeroes the counter itself.
}

- (void)dropTable {
	// Drops this table by name, so -dropTableName: zeroes the counter below.
	[self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
	BOOL success;
	NSError * __autoreleasing errorQuery = NULL;
	MADQuery *queryDropTable = [[MADQueryCacheDropTable alloc] initWithObject:tableName];
	success = [self.databaseForInserts executeQuery: queryDropTable
										  withError: &errorQuery];
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
	// Only zero the counter when the table that went away is this one.  The method
	// takes any name, and dropping a foreign table must not touch this count.
	if ([tableName isEqualToString:[self tableName]]) {
		self.rowCounter = 0;
	}
}

- (void)deleteAll {
	BOOL success;
	NSError * __autoreleasing errorQuery = NULL;
	NSString *tableName = [self tableName];
	MADQuery *queryDeleteAllFromTable;
	// -initWithObject: expects the parameters dictionary and subscripts it, so passing
	// the table name there raises on the first row; -initWithTableName: is the one that
	// takes a name.  Same call the sqlite driver makes in -beginBulkInsert.
	queryDeleteAllFromTable = [[MADQueryCacheDeleteAllFromTable alloc] initWithTableName:tableName];
	success = [self.databaseForInserts executeQuery: queryDeleteAllFromTable
										  withError: &errorQuery];
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
			 __PRETTY_FUNCTION__);
	self.rowCounter = 0;
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) {
		return nil;
	}
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) {
		return nil;
	}
	// -newCurrentObject: keys the row by MADDataColumn.identifier.
	return objForRow[columnMetaData.identifier];
}

- (NSDictionary *)objectAtRow:(NSUInteger)row {
	NSArray *objectAtRow = [self objectAtRow:row limit:1];
	return objectAtRow.firstObject;
}

- (NSDictionary *)queryDefinationSelect {
	return [self.class newQueryDefinitionSelect:self.columnKeys
									  tableName:[self tableName]
								sortDescriptors:self.sortDescriptors];
}

- (NSDictionary *)queryDefinationSelectWithLimit:(NSUInteger)limit
									   andOffset:(NSUInteger)offset {
	return [self.class newQueryDefinitionSelect:[self queryDefinationSelect]
									  withLimit:limit
									  andOffset:offset];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error {
	NSString *columnName = [self columnNameForIdentifier:columnKey];
	if (![self.columnKeys containsObject:columnName]) {
		os_log_error(mlog, "[MADDataTableFast %p dataForRow:%lu column:%@] Column not found", self, (unsigned long)rowID, columnKey);
		if (error != NULL) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:8927 userInfo:@{
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing results", @"Missing results")
			}];
		}
		return nil;
	}

	NSDictionary *result = nil;
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	sqlite3_stmt *statement = [self selectStatementForColumn:columnName
													database:databaseForSelects
													   error:error];
	if (statement == NULL) {
		return nil;
	}

	sqlite3_bind_int64(statement, 1, (sqlite3_int64)rowID);
	int stepResult = sqlite3_step(statement);
	if (stepResult == SQLITE_SCHEMA) {
		// The table was rebuilt or extended under the cached statement.  The
		// prepare-per-call code this replaced never saw a stale statement, so
		// re-prepare once and retry to keep that behaviour.
		[self dropSelectStatementForColumn:columnName];
		statement = [self selectStatementForColumn:columnName
										  database:databaseForSelects
											 error:error];
		if (statement == NULL) {
			return nil;
		}
		sqlite3_bind_int64(statement, 1, (sqlite3_int64)rowID);
		stepResult = sqlite3_step(statement);
	}
	if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
		result = [self newCurrentObject:statement fieldKey:columnName];
	} else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:8927 userInfo:@{
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errstr(stepResult) encoding:NSUTF8StringEncoding] ?: @""
			}];
		}
		result = [[NSDictionary alloc] init];
	}
	sqlite3_reset(statement);
	sqlite3_clear_bindings(statement);

	return result;
}

/// The cached per-column select, prepared against the selects connection on the
/// first read.  The SQL is parameterized ("WHERE rowid = ?") so one statement
/// serves every row; the caller binds, steps, and resets.  Returns NULL after
/// setting *error (code -782) when the statement cannot be prepared -- the same
/// failure the prepare-per-call code reported.
- (sqlite3_stmt *)selectStatementForColumn:(NSString *)columnName
								  database:(MADDatabaseSqlite3 *)databaseForSelects
									 error:(NSError * __autoreleasing *)error {
	NSValue *cached = _selectStatementsByColumn[columnName];
	sqlite3_stmt *statement = cached.pointerValue;
	if (statement != NULL) {
		return statement;
	}

	NSString *tableName = [self tableName];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@ WHERE rowid = ?", columnName, tableName];
	char *queryString = sqlite3_mprintf("%s", sql.UTF8String);

	int prepareResult = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1, &statement, NULL);
	sqlite3_free(queryString);
	if (prepareResult != SQLITE_OK) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-782 userInfo:@{
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errstr(prepareResult) encoding:NSUTF8StringEncoding] ?: @""
			}];
		}
		return NULL;
	}

	if (_selectStatementsByColumn == nil) {
		_selectStatementsByColumn = [[NSMutableDictionary alloc] init];
	}
	_selectStatementsByColumn[columnName] = [NSValue valueWithPointer:statement];
	return statement;
}

- (void)dropSelectStatementForColumn:(NSString *)columnName {
	sqlite3_stmt *statement = _selectStatementsByColumn[columnName].pointerValue;
	[_selectStatementsByColumn removeObjectForKey:columnName];
	if (statement != NULL) {
		sqlite3_finalize(statement);
	}
}

- (void)invalidateSelectStatementCache {
	NSMutableDictionary *cache = _selectStatementsByColumn;
	_selectStatementsByColumn = nil;
	for (NSValue *value in cache.allValues) {
		sqlite3_finalize((sqlite3_stmt *)value.pointerValue);
	}
}

- (void)beginReadTransaction {
	// A table with no cache directory or delegate has no selects connection at all;
	// there is nothing to begin, so the pair is a no-op rather than a crash.
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	if (databaseForSelects == nil) {
		return;
	}
	sqlite3 *database = databaseForSelects->_database;
	if (database == NULL) {
		return;
	}
	int resultCode = sqlite3_exec(database, "BEGIN", NULL, NULL, NULL);
	if (resultCode != SQLITE_OK) {
		os_log_debug(mlog, "[MADDataTableFast %p beginReadTransaction] BEGIN failed: %s", self, sqlite3_errstr(resultCode));
	}
}

- (void)commitReadTransaction {
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	if (databaseForSelects == nil) {
		return;
	}
	sqlite3 *database = databaseForSelects->_database;
	if (database == NULL) {
		return;
	}
	int resultCode = sqlite3_exec(database, "COMMIT", NULL, NULL, NULL);
	if (resultCode != SQLITE_OK) {
		os_log_debug(mlog, "[MADDataTableFast %p commitReadTransaction] COMMIT failed: %s", self, sqlite3_errstr(resultCode));
	}
}

// FIXME: Return error handler... remove credentals
/**
 * @param cacheId The cache ID or the row ID
 * @param outError An error pointer
 * @return A dictionary with the column names as keys and the values as value
 * Values are like NSNumber, NSNull, NSString, NSData, NSDate...
 */
- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
												 error:(NSError * __autoreleasing *)outError {
	if (self.lastDataForCacheId != nil) {
		if (cacheId == self.lastDataForCacheId.index) {
			id cached = self.lastDataForCacheId.object;
			if (cached != nil) {
				return [[NSDictionary alloc] initWithDictionary:cached];
			}
			// A nil cached object is an invariant violation, not a normal miss.
			// Log it once per process; the query below still answers correctly.
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				os_log_error(mlog, "[MADDataTableFast %p] the last-row cache held a nil object; requerying.", self);
			});
		}
	}
	
	NSDictionary * result = nil;
	NSString *tableName = [[self tableName] copy];
	
	NSNumber *keyRowId = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
	NSNumber *keyFieldKey = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
	NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
	NSNumber *cacheID = [[NSNumber alloc] initWithUnsignedInteger:cacheId];
	
	MADQuery * query = [[MADQueryCacheSelectRowId alloc] initWithObject: @{
		keyRowId: cacheID,
		keyFieldKey: self.columnKeys,
		keyTableName: tableName
	}];
	
	sqlite3_stmt *statement = NULL;
	NSError *error = nil;
	NSString *sql = [[query getSql:&error] copy];
	if (sql == nil) {
		if (outError != NULL) {
			*outError = error;
		}
		return nil;
	}

	char *queryString = sqlite3_mprintf("%s", sql.UTF8String);

	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	int sqlite3_prepare = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1, &statement, NULL);
	if (sqlite3_prepare == SQLITE_OK) {
		int stepResult = sqlite3_step(statement);
		if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
			result = [self newCurrentObject:statement];
			
			MADIndex * lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId
																  andObject:result];
			self.lastDataForCacheId = lastDataForCacheId;
			
		} else {
			const char *sqlite3message = sqlite3_errstr(stepResult);
			[NSString stringWithCString:sqlite3message encoding:NSUTF8StringEncoding];
			NSString *message = [NSString stringWithFormat:@"%s", sqlite3message];
			if (outError != NULL) {
				*outError = [NSError errorWithDomain:NSStringFromClass([self class]) code:-782 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3message encoding:NSUTF8StringEncoding] ?: @""
				}];
			}
			os_log_error(mlog, "[MADDataTableFast %p dataForRow:%lu] Error: %@", self, (unsigned long)cacheId, message);
			result = [[NSDictionary alloc] init];
		}
	} else {
		const char *sqlite3message = sqlite3_errstr(sqlite3_prepare);
		if (outError != NULL) {
			*outError = [NSError errorWithDomain:NSStringFromClass([self class]) code:-782 userInfo:@{
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3message encoding:NSUTF8StringEncoding] ?: @""
			}];
		}
		os_log_error(mlog, "[MADDataTableFast %p dataForRow:%lu] Prepare failed: %s",
					 self, (unsigned long)cacheId, sqlite3message);
	}

	sqlite3_finalize(statement);
	sqlite3_free(queryString);
	
	return result;
}

- (NSArray <NSDictionary <NSString *, MADResult *> *> *)whereClauseForGroupKeys:(NSArray <MADResult *> *)groupKeys {
	if (groupKeys.count == 0) {
		return @[];
	}
	[self setupGroupKeyIndexes];
	// The pairing is positional: the descriptor names the column a group key's value
	// filters on.  A key with no descriptor at its index cannot be named, so it is
	// left out and reported rather than walked off the end of the array.
	NSUInteger pairCount = MIN(groupKeys.count, self.sortDescriptors.count);
	if (pairCount < groupKeys.count) {
		os_log_error(mlog, "[MADDataTableFast %p whereClauseForGroupKeys:] %lu group keys but %lu sort descriptors; the tail is unmatched.",
					 self, (unsigned long)groupKeys.count, (unsigned long)self.sortDescriptors.count);
	}
	NSMutableArray <NSDictionary <NSString *, MADResult *> *> *whereClause = [[NSMutableArray alloc] initWithCapacity:pairCount];
	for (NSUInteger i = 0; i < pairCount; i++) {
		NSString *groupKeyName = [self.sortDescriptors[i].key copy];
		NSString *gk = [((NSString *)groupKeys[i]) copy];
		NSDictionary <NSString *, MADResult *> *whereStatement = [[NSDictionary alloc] initWithObjectsAndKeys:
																  groupKeyName, MADQueryKeyPredicateColumn,
																  gk, MADQueryKeyPredicateValue, nil];
		[whereClause addObject:whereStatement];
	}
	return whereClause;
}

- (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys {
	
	NSArray *whereClause = [[self whereClauseForGroupKeys:groupKeys] copy];
	
	NSNumber *selectFieldKeys = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
	NSNumber *selectTableName = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
	NSNumber *selectPredicates = [[NSNumber alloc] initWithShort: MADQuerySelectPredicates];
	NSNumber *selectSortDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
	NSNumber *selectFieldDescriptors = [[NSNumber alloc] initWithShort: MADQuerySelectFieldDescriptors];
	
	NSDictionary *querySelect = [[NSDictionary alloc] initWithObjectsAndKeys:
								 self.columnKeys,         selectFieldKeys,
								 self.tableName,          selectTableName,
								 whereClause,        selectPredicates,
								 self.sortDescriptors,    selectSortDescriptors,
								 self.columns,            selectFieldDescriptors,
								 nil];
	
	MADQuery <MADQueryDataBindingProtocol> *query = [[MADQuerySelectItemsForGroup alloc] initWithObject:querySelect];
	
	sqlite3_stmt *statement = NULL;
	NSError *error = nil;
	
	NSString *sql = [[query getSql:&error] copy];
	if (error != nil) {
		os_log_error(mlog, "%s SQL Error: %@", __PRETTY_FUNCTION__, error);
	}
	
	char *queryString = sqlite3_mprintf("%s", sql.UTF8String);
	
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	int sqlite3_prepare = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1, &statement, NULL);
	
	for (MADDatabaseDataBinding *dataBinding in query.binaryBindings) {
		[databaseForSelects bindStatement: (void **)&statement withBindings: dataBinding];
	}
	
	NSMutableArray <__kindof NSDictionary *> *results = [[NSMutableArray alloc] init];
	if (sqlite3_prepare == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSDictionary *result = [self newCurrentObject:statement];
			[results addObject:result];
		}
	}
	NSAssert(sqlite3_prepare == SQLITE_OK, @"%s at %s", sqlite3_errmsg(databaseForSelects->_database), __PRETTY_FUNCTION__);
	sqlite3_clear_bindings(statement);
	sqlite3_finalize(statement);
	sqlite3_free(queryString);
	return results;
}

// FIXME: Return error handler... remove credentals
- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys: self.columnKeys
																	   tableName: [self tableName]
																 sortDescriptors: self.sortDescriptors
																		   limit: limit
																		  offset: row
																	   dropRowID: NO
																		 columns: self.columns];
	NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:limit];
	
	if (row != NSNotFound && limit > 0) {
		sqlite3_stmt *statement = NULL;
		
		NSError *error = nil;
		NSString *sql = [[query getSql:&error] copy];
		const char *sqlc = sql.UTF8String;
		char *queryString = sqlite3_mprintf("%s", sqlc);
		
		MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
		
		int prepareResult = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1, &statement, NULL);

		NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database));
		if (prepareResult == SQLITE_OK) {

			while (sqlite3_step(statement) == SQLITE_ROW) {
				NSDictionary *currentObject = [self newCurrentObject:statement];
				[results addObject:currentObject];
			}
		}
		
		sqlite3_finalize(statement);
		sqlite3_free(queryString);
	}
	return results;
}

- (NSEnumerator *)columnsEnumerator {
	return self.columns.keyEnumerator;
}

- (NSEnumerator *)objectEnumerator {
	if (self.columns.count <= 0) {
		os_log_error(mlog, "[MADDataTableFast %p objectEnumerator] No columns.", self);
		return nil;
	}
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:self.columnKeys
																	   tableName:[self tableName]
																 sortDescriptors:self.sortDescriptors
																		   limit:NSNotFound
																		  offset:NSNotFound
																	   dropRowID:NO
																		 columns:self.columns];
	MADDatabaseConnection *databaseConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: self.urlFastCache];
	NSEnumerator *objectEnumerator = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
																							  columns: self.columns
																						   columnKeys: self.columnKeys
																								query: query];
	
	return objectEnumerator;
}

- (NSEnumerator<__kindof NSObject <NSCopying, NSSecureCoding> *> *)enumeratorForAllObjectsSortedRowIdOnly {
	
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys: @[]
																	   tableName: [self tableName]
																 sortDescriptors: self.sortDescriptors
																		   limit: NSNotFound
																		  offset: NSNotFound
																	   dropRowID: NO
																		 columns: self.columns];
	
	MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: self.urlFastCache];
	
	MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
	rowid.type = MADDataTypeInteger;
	
	NSDictionary <__kindof NSString *, __kindof MADDataColumn *> *columns = [[NSDictionary alloc] initWithObjectsAndKeys: rowid, MADIdentifierROWID, nil];
	NSArray <__kindof NSString *> *columnKeys = [[NSArray alloc] initWithObjects: MADIdentifierROWID, nil];
	NSEnumerator<__kindof NSObject <NSCopying, NSSecureCoding> *> *enumerator = [[MADDataTableSingleColumnEnumerator alloc] initWithDatabaseConnection: connection
																																			   columns: columns
																																			columnKeys: columnKeys
																																				 query: query];
	return enumerator;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
	[self setupGroupKeyIndexes];
	NSArray <NSString *> *columnKeys = [self columnKeysForSortDescriptors];
	if (columnKeys.count == 0) {
		return [self enumeratorForAllObjectsSortedRowIdOnly];
	}
	
	// The query is handed the cache's columns so the ORDER BY picks each key's
	// collation from its own MADDataType: text keys sort under LSASC, which is
	// the same comparison the report formatter finds group boundaries with
	// (docs/project/BUGS.md, "The cache's ORDER BY ignores column types").
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:columnKeys
																	   tableName:[self tableName]
																 sortDescriptors:self.sortDescriptors
																		   limit:NSNotFound
																		  offset:NSNotFound
																	   dropRowID:NO
																		 columns:self.columns];
	MADDatabaseConnection *dbConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: self.urlFastCache];
	return [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: dbConnection
																	columns: self.columns
																 columnKeys: columnKeys
																	  query: query];
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:self.columnKeys
																	   tableName:[self tableName]
																 sortDescriptors:self.sortDescriptors
																		   limit:NSNotFound
																		  offset:NSNotFound
																	   dropRowID:NO
																		 columns:self.columns];
	
	MADDatabaseConnection *dbConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: self.urlFastCache];
	return [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: dbConnection
																	columns: self.columns
																 columnKeys: self.columnKeys
																	  query: query];
}

- (NSArray *)allObjects {
	if (self.columnKeys.count == 0) {
		return @[];
	}
	return [self objectAtRow:0 limit:self.numberOfRows];
}

- (NSUInteger)count {
	return [self numberOfRows];
}

- (NSUInteger)numberOfColumns { return  self.columnKeys.count; }

- (NSUInteger)numberOfRows { return self.rowCounter; }

- (nullable NSString *)columnKeyForColumnName:(NSString *)columnName {
	for (NSString *columnKey in self.columnKeys) {
		MADDataColumn *column = self.columns[columnKey];
		if ([column.fieldName isEqualToString:columnName]) {
			return [NSString stringWithString: columnKey];
			break;
		}
	}
	//NSAssert(false, @"Should not get here.");
	return nil;
}

- (NSObject <NSCopying, NSSecureCoding> *)runSelectQuery:(MADQuery <MADQueryDataBindingProtocol> *)query {
	NSObject <NSCopying, NSSecureCoding> *result = nil;
	sqlite3_stmt *statement = NULL;
	NSError *error = nil;
	NSString *sql = [[query getSql:&error] copy];
	if (error != nil) {
		os_log_error(mlog, "Error: %@", error);
	}
	const char *sqlc = sql.UTF8String;
	char *queryString = sqlite3_mprintf("%s", sqlc);
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	
	BOOL success = sqlite3_prepare_v2(databaseForSelects->_database,
									  queryString, -1, &statement, NULL) == SQLITE_OK;
	
	NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));
	
	for (MADDatabaseDataBinding *dataBinding in query.binaryBindings) {
		[databaseForSelects bindStatement:(void **)&statement withBindings:dataBinding];
	}
	
	if (success && sqlite3_step(statement) == SQLITE_ROW) {
		result = [MADDatabaseSqlite3 databaseResultValue: statement
											columnNumber: 0];
	}
	NSAssert(success, @"%s", sqlite3_errmsg(databaseForSelects->_database));
	
	sqlite3_clear_bindings(statement);
	sqlite3_finalize(statement);
	sqlite3_free(queryString);
	return result;
}

//- (NSUInteger)columnIndexForKey:(NSString *)key {
//	return [self.columnKeys indexOfObject:key];
//}

- (id)newCurrentObject:(sqlite3_stmt *)statement fieldKey:(NSString *)fieldKey {
	NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:2];
	NSObject <NSCopying, NSSecureCoding> *columnValue = [MADDatabaseSqlite3 databaseResultValue: statement
																				   columnNumber: 0];
	if (columnValue != nil) {
		MADDataColumn *dataColumn = self.columns[fieldKey];
		[currentObject setValue: columnValue
						 forKey: dataColumn.identifier];
	}
	NSNumber *rowid = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, 1)];
	[currentObject setValue:rowid forKey:MADIdentifierROWID];
	return currentObject;
}

- (NSDictionary <NSString *, MADResult *> *)newCurrentObject:(sqlite3_stmt *)statement {
	NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:self.columns.count + 1];
	int columnCounter = 0;
	for (NSString *key in self.columnKeys) {
		//@autoreleasepool {
		MADResult *columnValue = [MADDatabaseSqlite3 databaseResultValue: statement
															columnNumber: columnCounter];
		if (columnValue != nil) {
			MADDataColumn *dataColumn = self.columns[key];
			[currentObject setValue: columnValue
							 forKey: dataColumn.identifier];
		}
		columnCounter++;
		//}
	}
	if (sqlite3_column_count(statement) >= columnCounter) {
		NSNumber *rowid = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, columnCounter)];
		[currentObject setValue:rowid forKey:MADIdentifierROWID];
	}
	return currentObject;
}

/*! Call before bulk insert of data. */

- (void)beginBulkInsert {
	_bulkInsertLoop = YES;
	[self reopenDbConnection];
	_sortDescriptorsSet = NO;
	[self createIndex];
	[self.databaseForInserts beginBulkInsert];
	
	MADQueryCacheAddRow *bulkInsertQuery = [[MADQueryCacheAddRow alloc] initWithObject: self];
	self.bulkInsertQuery = bulkInsertQuery;
	
	if (self.queueBulkAdd == nil) {
		dispatch_queue_t queue = dispatch_queue_create(MADQueueBulkAdd, DISPATCH_QUEUE_SERIAL);
		self.queueBulkAdd = queue;
	}
	
}

/*! Call right after bulk insert of data. */

- (void)endBulkInsert {

	__block MADDataTableFast *myself = self;
	__block BOOL internalBulkInsertLoop = _bulkInsertLoop;
	dispatch_barrier_sync(self.queueBulkAdd, ^{
		// The barrier is the only point at which no -addRow: is running, so the
		// cached statement may only be torn down inside it.
		sqlite3_finalize(myself->_statementInsert);
		myself->_statementInsert = NULL;
		internalBulkInsertLoop = NO;
		[(MADDatabaseSqlite3 *)myself.databaseForInserts endBulkInsert];
	});
	_bulkInsertLoop = internalBulkInsertLoop;
}

- (NSEnumerator *)enumeratorForRowIds:(NSArray *)cacheIds { //Note, software currently usues
	//  NSArray for row ids
	NSDictionary <NSString *, MADDataColumn *> *columns = [NSDictionary dictionaryWithDictionary:self.columns];
	
	MADQuery *query = [[MADQueryCacheSelectRowIds alloc] initWithRowIDs:cacheIds
															  tableName:[self tableName]
														sortDescriptors:self.sortDescriptors
																columns:self.columns];
	MADDatabaseConnection *databaseConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: self.urlFastCache];
	NSEnumerator *data = [[MADDataTableObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
																				  columns: columns
																			   columnKeys: self.columnKeys
																					query: query];
	return data;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] initWithString:@"Table name: "];
	[description appendString:[self tableName]];
	[description appendFormat:@"\nColumn keys: %@", self.columnKeys];
	return description;
}

@end
