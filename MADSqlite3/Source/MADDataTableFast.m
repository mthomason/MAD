//
//  MADDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

#import <os/log.h>
#import <dispatch/dispatch.h>
#import <stdio.h>

static const char * MADQueueBulkAdd = "com.everydayapps.mad.cache.fast";
static os_log_t mlog;

@interface MADDataTableFast () <MADQueryParametersStandardProtocol, MADQueryParametersColumnKeysProtocol, MADQueryParametersColumnMetaProtocol, MADQueryParametersColumnDataProtocol>

@property (nonatomic, readwrite, strong) dispatch_queue_t queueBulkAdd;

@property (nonatomic, readwrite, strong) MADDatabaseSqlite3 *databaseForInserts;
@property (nonatomic, readwrite, strong) MADDatabaseSqlite3 *databaseForSelects;

@property (nonatomic, readwrite, strong) MADQueryCacheAddRow *bulkInsertQuery;
@property (nonatomic, readwrite, strong) NSMutableArray <MADDatabaseDataBinding *> *binaryBindings;

@property (nonatomic, readwrite, strong) NSURL *urlFastCache;
@property (nonatomic, readwrite, strong) NSMutableIndexSet *groupKeyIndexes;
@property (nonatomic, readwrite, strong) MADIndex *lastDataForCacheId;

@property (nonatomic, readwrite, strong) id rowDataLastInserted;

@property (nonatomic, readwrite, assign) BOOL bulkInsertLoop;
@property (nonatomic, readwrite, assign) BOOL sortDescriptorsSet;

@end

@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;
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
}

- (instancetype)initWithId:(NSUInteger)objectId {
	return [self initWithId:objectId fromCache:YES];
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
		
		NSString *absoluteString = [decoder decodeObjectForKey: [MADDataTableFast keyUrlFastCache]];
		self.urlFastCache = [NSURL URLWithString:absoluteString];
		
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
	
	NSURL *url = [self.urlFastCache copy];
	[encoder encodeObject: url.absoluteString forKey: [MADDataTableFast keyUrlFastCache]];
	
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
	NSString *absoluteString = urlFastCache.absoluteString;
	NSAssert(absoluteString != nil, @"We need a path.");
	NSString *urlFastCacheAbsolute = [[NSString alloc] initWithString: absoluteString];
	plist[[MADDataTableFast keyUrlFastCache]] = urlFastCacheAbsolute;
	
	NSNumber *tag = [[NSNumber alloc] initWithUnsignedInteger: self.tag];
	plist[[MADDataTableFast keyTag]] = tag;
	
	NSNumber *bulkInsert = [[NSNumber alloc] initWithBool:_bulkInsertLoop];
	plist[[MADDataTableFast keyBulkInsertLoop]] = bulkInsert;
	
	if (self.groupKeyIndexes != nil) {
		NSError *error = nil;
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.groupKeyIndexes requiringSecureCoding:YES error:&error];
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
	
	NSString *absoluteString = plist[[MADDataTableFast keyUrlFastCache]];
	if (absoluteString.length > 0) {
		self.urlFastCache = [NSURL URLWithString:absoluteString];
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

	self.groupKeyIndexes = (groupKeysArray != nil) ? [[NSMutableIndexSet alloc] initWithIndexSet: groupKeysArray] : [[NSMutableIndexSet alloc] init];
	
	[self reopenDbConnection];
	return YES;
}

- (NSString *)filenameCacheMadDB {
	NSString *tag = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.tag];
	return [tag stringByAppendingPathExtension:@"maddb"];
}

- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
	NSAssert(NO, @"Not implemented");
	return nil;
}

- (void)setCacheDelegate:(id<MADCacheProtocol>)cacheDelegate {
	_cacheDelegate = cacheDelegate;
	[self reopenDbConnection];
}

- (void)reopenDbConnection {
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
	return [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
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
		index = [columnKeys indexOfObject: sortDescriptor.key];
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
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding]
				}];
				result = false;
			}
		}
		
		// Clear bindings and reset the statement
		if (sqlite3_clear_bindings(_statementInsert) != SQLITE_OK) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3240 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error Clear Bindings", @"Error Clear Bindings"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding]
				}];
				result = false;
			}
		}
		
		if (sqlite3_reset(_statementInsert) != SQLITE_OK) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3240 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error Reset", @"Error Reset"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errmsg(sqlite_database) encoding:NSUTF8StringEncoding]
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

// FIXME: Maybe wrap in autorelease block.
- (void)addRowWithDataForFieldKeys:(NSDictionary <NSString *, id> *)row {
	//@autoreleasepool {
	
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
	
	//}
	
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
}

- (void)dropTable {
	[self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
	BOOL success;
	NSError * __autoreleasing errorQuery = NULL;
	MADQuery *queryDropTable = [[MADQueryCacheDropTable alloc] initWithObject:tableName];
	success = [self.databaseForInserts executeQuery: queryDropTable
										  withError: &errorQuery];
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database), __PRETTY_FUNCTION__);
}

- (void)deleteAll {
	BOOL success;
	NSError * __autoreleasing errorQuery = NULL;
	NSString *tableName = [self tableName];
	MADQuery *queryDeleteAllFromTable;
	queryDeleteAllFromTable = [[MADQueryCacheDeleteAllFromTable alloc] initWithObject:tableName];
	success = [self.databaseForInserts executeQuery: queryDeleteAllFromTable
										  withError: &errorQuery];
	NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts->_database),
			 __PRETTY_FUNCTION__);
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
	NSArray<NSString *> *columnKeys = [[NSArray alloc] initWithObjects:columnName, nil];
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
	NSString *tableName = [[self tableName] copy];
	
	NSNumber *keyRowId = [[NSNumber alloc] initWithShort:MADQuerySelectRowId];
	NSNumber *keyFieldKey = [[NSNumber alloc] initWithShort:MADQuerySelectFieldKeys];
	NSNumber *keyTableName = [[NSNumber alloc] initWithShort:MADQuerySelectTableName];
	
	NSNumber *cacheID = [[NSNumber alloc] initWithUnsignedInteger:rowID];
	NSDictionary<NSNumber *, id> *options = [[NSDictionary alloc] initWithObjectsAndKeys:
											 cacheID, keyRowId,
											 columnKeys, keyFieldKey,
											 tableName, keyTableName,
											 nil];
	MADQuery *query = [[MADQueryCacheSelectRowId alloc] initWithObject:options];
	sqlite3_stmt *statement = NULL;
	NSError * __autoreleasing errorSQL = nil;
	NSString *sql = [[query getSql:&errorSQL] copy];
	
	const char *sqlUTF8String = [sql UTF8String];
	char *queryString = sqlite3_mprintf("%s", sqlUTF8String);
	
	MADDatabaseSqlite3 *databaseForSelects = self.databaseForSelects;
	
	int sqlite3_prepare = sqlite3_prepare_v2(databaseForSelects->_database, queryString, -1, &statement, NULL);
	if (sqlite3_prepare == SQLITE_OK) {
		
		int stepResult = sqlite3_step(statement);
		if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
			result = [self newCurrentObject:statement fieldKey:columnName];
		} else {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:8927 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errstr(stepResult) encoding:NSUTF8StringEncoding]
				}];
			}
			result = [[NSDictionary alloc] init];
		}
	} else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-782 userInfo:@{
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3_errstr(sqlite3_prepare) encoding:NSUTF8StringEncoding]
			}];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(queryString);
	
	return result;
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
			return [[NSDictionary alloc] initWithDictionary:self.lastDataForCacheId.object];
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
					NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3message encoding:NSUTF8StringEncoding]
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
				NSLocalizedDescriptionKey: [NSString stringWithCString:sqlite3message encoding:NSUTF8StringEncoding]
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
	NSMutableArray <NSDictionary <NSString *, MADResult *> *> *whereClause = [[NSMutableArray alloc] initWithCapacity:groupKeys.count];
	for (NSUInteger i = 0; i < groupKeys.count; i++) {
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
	
	char *queryString = sqlite3_mprintf(sql.UTF8String);
	
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
																		 columns: nil];
	NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:limit];
	
	if (row != NSNotFound && limit > 0) {
		sqlite3_stmt *statement = NULL;
		
		NSError *error = nil;
		NSString *sql = [[query getSql:&error] copy];
		const char *sqlc = sql.UTF8String;
		char *queryString = sqlite3_mprintf((char *) sqlc);
		
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
																		 columns:nil];
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
																		 columns: nil];
	
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
	
	MADQuery *query = [[MADQueryCacheSelectLimitOffset alloc] initWithColumnKeys:columnKeys
																	   tableName:[self tableName]
																 sortDescriptors:self.sortDescriptors
																		   limit:NSNotFound
																		  offset:NSNotFound
																	   dropRowID:NO
																		 columns:nil];
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
																		 columns:nil];
	
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
	char *queryString = sqlite3_mprintf((char *) sqlc);
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
	
	sqlite3_finalize(_statementInsert);
	_statementInsert = NULL;
	
	__block MADDataTableFast *myself = self;
	__block BOOL internalBulkInsertLoop = _bulkInsertLoop;
	dispatch_barrier_sync(self.queueBulkAdd, ^{
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
