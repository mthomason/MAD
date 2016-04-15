//
//  MTDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTableFast.h"

#import <MADDataStructures/MADIndex.h>
#import <MADFoundation/MADDataColumn.h>


#import <MAD/MADConstants.h>

#import <MAD/MTDataTableFastObjectEnumerator.h>
#import <MAD/MTDatabaseSqlite3.h>
#import <MAD/MTDatabaseConnectionSqlite3.h>
#import <MAD/MTQuery.h>
#import <MAD/MTQueryCacheAddRow.h>
#import <MAD/MTQueryCacheIndexDrop.h>
#import <MAD/MTQueryCacheAddColumn.h>
#import <MAD/MTQueryCacheVacuum.h>
#import <MAD/MTQueryCacheDropTable.h>
#import <MAD/MTQueryCacheDeleteAllFromTable.h>
#import <MAD/MTQuerySelectItemsForGroup.h>
#import <MAD/MTQueryCacheSelectLimitOffset.h>
#import <MAD/MTQueryCacheSelectGroupKeys.h>
#import <MAD/MTQueryCacheSelectRowId.h>
#import <MAD/MTQueryCacheSelectRowIds.h>

@interface MTDataTableFast ()

    @property (nonatomic, strong) MTDatabaseSqlite3 *databaseForInserts;
    @property (nonatomic, strong, readwrite) MTDatabaseSqlite3 *databaseForSelects;

    @property (nonatomic, strong) NSURL *urlFastCache;

    @property (nonatomic, assign) bool bulkInsertLoop;
    @property (nonatomic, assign) bool sortDescriptorsSet;

    @property (nonatomic, strong) NSMutableArray <__kindof NSNumber *> *groupKeys;

    @property (nonatomic, strong) MADIndex *lastDataForCacheId;

    @property (nonatomic, strong) MTQueryCacheAddRow *bulkInsertQuery;

    @property (nonatomic, strong) dispatch_queue_t queueBulkAdd;

@end

@implementation MTDataTableFast

MTDataType mad_sqlite3_datatype_for_sqlite3_type(int sqlite3type);
MTDataType mad_sqlite3_datatype_for_sqlite3_type(int sqlite3type) {
    switch (sqlite3type) {
        case SQLITE_INTEGER:
            return MTDataTypeInteger;
            break;
        case SQLITE_TEXT:
            return MTDataTypeString;
            break;
        case SQLITE_BLOB:
            return MTDataTypeBlob;
            break;
        case SQLITE_NULL:
            return MTDataTypeNull;
            break;
        case SQLITE_FLOAT:
            return MTDataTypeFloat;
            break;
        default:
            return MTDataTypeString;
            break;
    }
}

- (instancetype)initWithId:(NSUInteger)objectId {
    if (self = [super initWithId:objectId fromCache:YES]) {
        self.bulkInsertLoop = false;
        self.tag = objectId;
        self.sortDescriptorsSet = false;
        _queueBulkAdd = nil;
    }
    return self;
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    if (self = [super initWithId:objectId fromCache:fromCache]) {
        self.bulkInsertLoop = false;
        self.tag = objectId;
        self.sortDescriptorsSet = false;
        _queueBulkAdd = nil;
    }
    return self;
}

- (void)dealloc {
    if (_queueBulkAdd != nil) {
        dispatch_suspend(_queueBulkAdd);
        _queueBulkAdd = nil;
    }
    
}

- (NSDictionary *)plist {
    
    NSDictionary *superPlist = [super plist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    
    NSString *keyUrlFastCache = [MTDataTableFast keyUrlFastCache];
    NSString *keyTag = [MTDataTableFast keyTag];
    NSString *keyBulkInsertLoop = [MTDataTableFast keyBulkInsertLoop];

    plist[keyUrlFastCache] = [[self urlFastCache] absoluteString];
    plist[keyTag] = @([self tag]);
    plist[keyBulkInsertLoop] = @(self.bulkInsertLoop ? YES : NO);
    
    NSString *keyGroupKeys = [MTDataTableFast keyGroupKeys];
    NSString *keySortDescriptorsSet = [MTDataTableFast keySortDescriptorsSet];

    if (self.groupKeys != nil) {
        plist[keyGroupKeys] = self.groupKeys;
    }
    plist[keySortDescriptorsSet] = @(self.sortDescriptorsSet ? YES : NO);
    _queueBulkAdd = nil;
    return plist;
}

- (void)loadWithPlist:(NSDictionary *)plist {
    [super loadWithPlist:plist];
    
    _queueBulkAdd = nil;
    NSString *absoluteString = plist[[MTDataTableFast keyUrlFastCache]];
    NSURL *url = [NSURL URLWithString:absoluteString];
    [self setUrlFastCache: url];
    
    NSNumber *tagWrapper = plist[[MTDataTableFast keyTag]];
    self.tag = tagWrapper.unsignedIntegerValue;
    
    NSNumber *bulkInsertLoopWrapper = plist[[MTDataTableFast keyBulkInsertLoop]];
    self.bulkInsertLoop = bulkInsertLoopWrapper.boolValue ? true : false;
    
    NSArray *groupKeysArray = plist[[MTDataTableFast keyGroupKeys]];
    NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithArray: groupKeysArray];
    [self setGroupKeys:groupKeys];
    
    [self reopenDbConnection];
    
}

+ (NSString *)keyUrlFastCache {
    SEL sel = @selector(urlFastCache);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyTag {
    SEL sel = @selector(tag);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyBulkInsertLoop {
    SEL sel = @selector(bulkInsertLoop);
    return NSStringFromSelector(sel);
}

+ (NSString *)keySortDescriptorsSet {
    return NSStringFromSelector(@selector(sortDescriptorsSet));
}

+ (NSString *)keyGroupKeys {
    return NSStringFromSelector(@selector(groupKeys));
}

+ (NSString *)keyGroupTableNames {
    return NSStringFromSelector(@selector(groupTableNames));
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];

    NSString *absStr = _urlFastCache.absoluteString;
    [encoder encodeObject:  absStr                              forKey: [MTDataTableFast keyUrlFastCache]];
    NSNumber *objid = @(self.tag);
    [encoder encodeObject: objid                                forKey: [MTDataTableFast keyTag]];
    [encoder encodeBool: _bulkInsertLoop ? YES : NO             forKey: [MTDataTableFast keyBulkInsertLoop]];
    [encoder encodeBool: _sortDescriptorsSet ? YES : NO         forKey: [MTDataTableFast keySortDescriptorsSet]];
    _queueBulkAdd = nil;

}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        
        _queueBulkAdd = nil;
        NSString *absoluteString = [decoder decodeObjectForKey: [MTDataTableFast keyUrlFastCache]];
        NSURL *url = [NSURL URLWithString:absoluteString];
        self.urlFastCache = url;
        
        NSNumber *tag = [decoder decodeObjectForKey: [MTDataTableFast keyTag]];
        self.tag = tag.unsignedIntegerValue;

        _bulkInsertLoop = [decoder decodeBoolForKey: [MTDataTableFast keyBulkInsertLoop]] ? true : false;
        _sortDescriptorsSet = [decoder decodeBoolForKey: [MTDataTableFast keySortDescriptorsSet]] ? true : false;
        
        NSArray *groupKeysArray = [decoder decodeObjectForKey: [MTDataTableFast keyGroupKeys]];
        NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithArray: groupKeysArray];
        self.groupKeys = groupKeys;
        
        [self reopenDbConnection];
    }
    return self;
}

- (NSString *)filenameCacheMadDB {
    NSString *tag = [NSString stringWithFormat:@"%lu", (unsigned long)self.tag];
    return [tag stringByAppendingPathExtension:@"maddb"];
}

- (NSURL *)urlFastCache {
    NSString *filename = [self filenameCacheMadDB];
    NSURL *cacheDirectory = self.cacheDelegate == nil ?
                            [MADFileUtilities localCacheDirectoryForGroupIdentifier:MADIdentifierGroup] :
                                [self.cacheDelegate cachedFilesDirectory];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (void)setCacheDelegate:(id<MTCacheProtocol>)cacheDelegate {
    _cacheDelegate = cacheDelegate;
    [self reopenDbConnection];
}

- (void)reopenDbConnection {
    MTDatabaseConnection *connection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:[self urlFastCache]];
    
    MTDatabaseSqlite3 *database = [[MTDatabaseSqlite3 alloc] init];
    database.databaseConnection = connection;
    [(MTDatabaseSqlite3 *)database openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
    self.databaseForInserts = database;
    
    MTDatabaseSqlite3 *database2 = [MTDatabaseSqlite3 newDatabaseWithConnection:connection];
    self.databaseForSelects = database2;
}

- (NSString *)tableName {
    char buf[19];
    snprintf(buf, 19, "t%lu", (unsigned long)self.tag);
    return @(buf);
}

- (void)addColumn:(MADDataColumn *)column {
    NSUInteger columnId = [[column identifier] hash];
    BOOL createTable = [self.columnKeys count] == 0;
    char buf[19];
    snprintf(buf, 19, "c%lu", (unsigned long)columnId);
    NSString *columnName = @(buf);
    self.columns[columnName] = column;
    [self.columnKeys addObject:columnName];
    
    [self addColumn:column toTable:[self tableName] columnName:columnName createTable:createTable unique:NO];
}

- (void)initalizeGroupKeys {

    if (self.groupKeys == nil) {
        NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithCapacity:self.sortDescriptors.count];
        self.groupKeys = groupKeys;
    } else {
        [self.groupKeys removeAllObjects];
    }
    
    NSArray *sortDescriptors = self.sortDescriptors;
    NSUInteger index = NSNotFound;
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            if (((index = [self.columnKeys indexOfObject: sortDescriptor.key])) != NSNotFound) {
                NSNumber *columnIndex = [[NSNumber alloc] initWithUnsignedInteger:index];
                [self.groupKeys addObject:columnIndex];
            }
        }
    }
}

- (NSString *)idColumnKeyForGroupLocation:(NSUInteger)groupLevel {
    NSString *result = nil;
    if (self.groupKeys.count > groupLevel) {
        NSNumber *level = self.groupKeys[groupLevel];
        result = self.columnKeys[level.unsignedIntegerValue];
        NSString *rval = [NSString stringWithString:result];
        return rval;
    } else {
        return nil;
    }
}

- (MADDataColumn *)idDataColumnForGroupLevel:(NSUInteger)groupLevel {
    NSString *key = [self idColumnKeyForGroupLocation:groupLevel];
    return self.columns[key];
}

- (void)addColumn:(MADDataColumn *)column toTable:(NSString *)table columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    bool success = false;
    NSError * __autoreleasing errorQuery = NULL;
    MTQueryCacheAddColumn *query = [[MTQueryCacheAddColumn alloc] initWithTableName:table columnName:columnName column:column createTable:create ? true : false uniqueColumnHack:unique ? true : false];
    query.database = _databaseForInserts;
    success = [_databaseForInserts executeQuery:query withError:&errorQuery];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_databaseForInserts.databaseHandle), __PRETTY_FUNCTION__);

}

- (void)addRow:(NSArray *)row {
    self.rowCounter++;
    if (self.groupKeys == nil) {
        [self initalizeGroupKeys];
    }
    
    
    if (self.bulkInsertLoop) {
        @autoreleasepool {
/*
            NSArray *rowData = [NSArray arrayWithArray: row];
            self.bulkInsertQuery.rowData = rowData;
            NSString *sql = [[NSString alloc] initWithString:[self.bulkInsertQuery getSqlWithError:nil]];
            NSArray *binaryBindings = [[NSArray alloc] initWithArray:self.bulkInsertQuery.binaryBindings];
            NSArray *fieldKeys = [[NSArray alloc] initWithArray:self.bulkInsertQuery.fieldKeys];
            
            MTDatabaseSqlite3 * dbForInserts = ((MTDatabaseSqlite3 *)self.databaseForInserts);
            struct sqlite3 *db = dbForInserts.database;
*/

            NSArray *rowData = [NSArray arrayWithArray: row];
            self.bulkInsertQuery.rowData = rowData;
            NSString *sql = [self.bulkInsertQuery getSqlWithError:nil];
            NSArray * __weak binaryBindings = self.bulkInsertQuery.binaryBindings;
            NSArray * __weak fieldKeys = self.bulkInsertQuery.fieldKeys;

            MTDataTableFast * __weak weakself = self;
            dispatch_async(self.queueBulkAdd, ^{

                [MTDatabaseSqlite3 executeQueryWithSql: sql database: ((MTDatabaseSqlite3 *)weakself.databaseForInserts).database
                                   queryBinaryBindings: binaryBindings queryFieldKeys: fieldKeys queryPartOfTransactionSet: YES];
            });
        }
        
    } else {


        NSNumber *keyKeys = @(MTQueryCacheAddRowColumnKeys);
        NSNumber *keyColumns = @(MTQueryCacheAddRowColumns);
        NSNumber *keyData = @(MTQueryCacheAddRowData);
        NSNumber *keyTableName = @(MTQueryCacheAddRowTableName);
        NSString *tableName = [self tableName];
        NSDictionary *columns = self.columns;
        NSArray *columKeys = self.columnKeys;
        NSDictionary *queryDefination = @{
                                          keyKeys : columKeys,
                                          keyColumns : columns,
                                          keyData : row,
                                          keyTableName : tableName
                                          };

        MTQuery *query = self.bulkInsertLoop ? self.bulkInsertQuery :
                                                [[MTQueryCacheAddRow alloc] initWithObject:queryDefination];
        
        query.database = _databaseForInserts;
        bool success;
        NSError * __autoreleasing errorQuery = NULL;
        success = [_databaseForInserts executeQuery:query withError:&errorQuery];

    }
    
    
}

- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {

    @autoreleasepool {
        
        NSMutableArray *rowData = [[NSMutableArray alloc] init];
        for (id columnDefKey in self.columnKeys) {
            MADDataColumn *columnDef = self.columns[columnDefKey];
            id obj = row[columnDef.fieldName];
            if (obj == nil) obj = [NSNull null];
            [rowData addObject:obj];
        }
        [self addRow:rowData];
        
    }
    
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {

    [self.groupKeys removeAllObjects];
    if (self.columnKeys.count > 0 && self.columns.count > 0) {
        
        if (sortDescriptors.count > 0 /*&& self.sortDescriptorsSet == NO*/) {
            
            NSMutableArray *newSortDescriptors = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
            NSInteger i;
            
            for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
                i = 0;

                NSArray *columnKeys = self.columnKeys;
                for (NSString *columnKey in columnKeys) {
                    
                    @autoreleasepool {
                        MADDataColumn * __weak column = self.columns[columnKey];
                        if ([column.fieldName isEqualToString:sortDescriptor.key]) {
                            SEL sortAlgo = [MADDataType selectorForSorting:column.columnType];
                            
                            NSSortDescriptor *newSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:columnKey ascending:sortDescriptor.ascending selector:sortAlgo];
                            [newSortDescriptors addObject:newSortDescriptor];
                            
                            NSNumber *groupKey = @(i);
                            [self.groupKeys addObject:groupKey];
                            
                            break;
                        }
                    }
                    i++;
                }
                if (newSortDescriptors.count == sortDescriptors.count) {
                    self.sortDescriptorsSet = true;
                    self.sortDescriptors = newSortDescriptors;
                }
            }
        }
    } else {
        NSMutableArray *sd = [[NSMutableArray alloc] initWithArray:sortDescriptors];
        [self setSortDescriptors:sd];
    }
    
    // FIXME: reset cache after setting the sort descriptors    
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

- (NSArray *)sortDescriptorIndexGroupsForSortDescriptors:(NSArray *)sortDescriptors {

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count + 1];
    [results addObject:sortDescriptors];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        NSArray *group = @[sortDescriptor];
        [results addObject:group];
    }
    return results;
}

- (NSString *)cacheTableNameForGroupLevel:(NSInteger)groupLevel {
    return [NSString stringWithFormat:@"s%ld", (long)groupLevel];
}

- (NSString *)indexNameForGroupLevel:(NSUInteger)groupLevel andIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"i%ld%ld", (long)groupLevel, (long)index];
}

- (NSDictionary *)createIndexParametersForIndexName:(NSString *)indexName tableName:(NSString *)tableName andSortDescriptors:(NSArray *)sortDescriptors {
    NSDictionary *columns = [NSDictionary dictionaryWithDictionary: self.columns];
    NSDictionary * parameters = @{
                                                  @(MTQueryCacheIndexCreateIndexName)         : indexName,
                                                  @(MTQueryCacheIndexCreateTableName)         : tableName,
                                                  @(MTQueryCacheIndexCreateSortDescriptors)   : sortDescriptors,
                                                  @(MTQueryCacheIndexCreateColumns)           : columns
                                                  };
    return parameters;
}

- (void)createIndex {
    
    NSArray *sortDescriptors = [[self dataDelegate] sortDescriptors];
    [self.sortDescriptors setArray:sortDescriptors];
    [self sortUsingDescriptors:self.sortDescriptors];
    
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSArray *sortDescriptorGroups = [self sortDescriptorIndexGroupsForSortDescriptors:self.sortDescriptors];
    
    NSUInteger groupCounter = 0;
    for (NSArray *sortDescriptors in sortDescriptorGroups) {

        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSString *tableName = [self tableName];
        NSDictionary *parametersCreateIndex = [self createIndexParametersForIndexName:groupName
                                                                            tableName:tableName
                                                                   andSortDescriptors:sortDescriptors];
  
        MTQuery *queryCreateIndex = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheIndexCreateParameters
                                                                object: parametersCreateIndex];
        bool success;
        NSError * __autoreleasing errorQuery = NULL;
        success = [self.databaseForInserts executeQuery:queryCreateIndex withError:&errorQuery];

        groupCounter++;
    }

    
}

- (void)dropIndex {
    NSUInteger sortDescCtr = self.sortDescriptors.count;
    NSUInteger groupCounter = 0;
    bool success;
    for (NSUInteger i = 0; i<sortDescCtr; i++) {
        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSDictionary *parameters = @{
                                     @(MTQueryCacheIndexDropIndexName) : groupName,
                                     };
        NSError * __autoreleasing errorQuery = NULL;
        MTQuery *query = [[MTQueryCacheIndexDrop alloc] initWithObject:parameters];
        success = [self.databaseForInserts executeQuery:query withError:&errorQuery];
        errorQuery = NULL;
    }
}

- (void)vacuumCacheDb {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    MTQuery *queryVacuum = [[MTQueryCacheVacuum alloc] init];
    success = [self.databaseForInserts executeQuery:queryVacuum withError:&errorQuery];
}

- (void)dropTable {
    [self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    MTQuery *queryDropTable = [[MTQueryCacheDropTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery:queryDropTable withError:&errorQuery];
}

- (void)deleteAll {
    bool success;
    NSError * __autoreleasing errorQuery = NULL;
    NSString *tableName = [self tableName];
    MTQuery *queryDeleteAllFromTable = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:tableName];
    success = [self.databaseForInserts executeQuery:queryDeleteAllFromTable withError:&errorQuery];
}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    // FIXME: Query just this field.
    NSDictionary *objForRow = [self objectAtRow:row];
    NSString *key = self.columnKeys[0];
    MADDataColumn *columnMetaData = self.columns[key];
    NSString *fieldName = [columnMetaData fieldName];
    return objForRow[fieldName];
}

- (NSDictionary *)objectAtRow:(NSUInteger)row {
    NSArray *objectAtRow = [self objectAtRow:row limit:1];
    return objectAtRow.firstObject;
}

- (NSDictionary *)queryDefinationSelect {
    return [MTQuery queryDefinitionSelect:self.columnKeys tableName:[self tableName] sortDescriptors:self.sortDescriptors];
}

- (NSDictionary *)queryDefinationSelectWithLimit:(NSUInteger)limit andOffset:(NSUInteger)offset {
    return [MTQuery queryDefinitionSelect:[self queryDefinationSelect] withLimit:limit andOffset:offset];
}

// FIXME: Return error handler... remove credentals
- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    
    
    if (self.lastDataForCacheId != nil) {
        if (cacheId.unsignedIntegerValue == self.lastDataForCacheId.index) {
            NSDictionary *result = [NSDictionary dictionaryWithDictionary:self.lastDataForCacheId.object];
            return result;
        }
    }
    
    NSDictionary * result = nil;
    
    NSString *tableName = [self tableName];
    MTQuery *query = [[MTQueryCacheSelectRowId alloc] initWithTableName:tableName rowID:cacheId.unsignedIntegerValue columnKeys:self.columnKeys];
    
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlUTF8String = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlUTF8String);
    bool success = sqlite3_prepare_v2([self.databaseForSelects databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
    
    if (success) {  //Expect success to == NO in normal working conditions.
        switch (sqlite3_step(statement)) {
            case SQLITE_OK:
            case SQLITE_ROW:
            case SQLITE_DONE: {
                result = [[NSDictionary alloc] initWithDictionary:[self currentObject:statement]];
                MADIndex * lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId.unsignedIntegerValue andObject:result];
                self.lastDataForCacheId = lastDataForCacheId;
                break;
            }
            default:
                result = @{};
                break;
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);

    return result;
}

- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys {
    [self initalizeGroupKeys];
    NSMutableArray * whereClause = [[NSMutableArray alloc] initWithCapacity:groupKeys.count];
    NSUInteger groupLevel = 0;
    for (NSString *key in groupKeys) {
        @autoreleasepool {
            NSString *columnLevel = [self idColumnKeyForGroupLocation:groupLevel].copy;
            NSAssert(columnLevel != nil, @"This can't be null.");
            if (columnLevel != nil) {
                NSString *gk = key.copy;
                NSDictionary *whereStatement = @{MTQueryKeyPredicateColumn : columnLevel,
                                                 MTQueryKeyPredicateValue : gk};
                [whereClause addObject:whereStatement];
                groupLevel++;
            }
        }
    }
    return whereClause;
}

// FIXME: Return error handler... remove credentals
- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys {

    [self initalizeGroupKeys];

    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSArray *whereClause = [self whereClauseForGroupKeys:groupKeys];
    NSString *tableName = [self tableName];
    
    MTQuerySelectItemsForGroup *query = [[MTQuerySelectItemsForGroup alloc] initWithTableName:tableName sortDescriptors:self.sortDescriptors
                                                                                   columnKeys:self.columnKeys whereClause:whereClause
                                                                                      columns:self.columns];
    
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    sqlite3 *databaseHandle = [self.databaseForSelects databaseHandle];
    
    BOOL success = sqlite3_prepare_v2(databaseHandle, queryString, -1, &statement, NULL) == SQLITE_OK;
    
    NSArray *queryBinaryBindings = query.binaryBindings;
    for (MTDatabaseDataBinding *dataBinding in queryBinaryBindings) {
        [MTDatabaseSqlite3 bindStatement:&statement withBindings:dataBinding];
    }

    if (success) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            @autoreleasepool {
                NSDictionary * __weak currentObject = [self currentObject:statement];
                NSDictionary *result = [[NSDictionary alloc] initWithDictionary:currentObject];
                [results addObject:result];
            }
        }
    }
    NSAssert(success, @"%s at %s", sqlite3_errmsg(databaseHandle), __PRETTY_FUNCTION__);
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return results;
}

// FIXME: Return error handler... remove credentals
- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit {
    
    MTQueryCacheSelectLimitOffset *query = [[MTQueryCacheSelectLimitOffset alloc] initWithLimit:limit offset:row tableName:[self tableName]
                                                                                      dropRowID:false columnKeys:self.columnKeys sortDescriptors:self.sortDescriptors columns:nil whereClause:nil];

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:limit];
    if (row != NSNotFound && limit > 0) {
        sqlite3_stmt *statement = NULL;
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        const char *sqlc = [sql UTF8String];
        char *queryString = sqlite3_mprintf((char *) sqlc);
        BOOL success = sqlite3_prepare_v2([self.databaseForSelects databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
        NSAssert(success, @"%s", sqlite3_errmsg([self.databaseForSelects databaseHandle]));
        if (success) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                @autoreleasepool {
                    NSDictionary * __weak currentObject = [NSDictionary dictionaryWithDictionary:[self currentObject:statement]];
                    [results addObject:currentObject];
                }
            }
        }
        
        sqlite3_finalize(statement);
        sqlite3_free(queryString);
    }
    return results;
}

- (NSEnumerator *)columnsEnumerator {
    // FIXME: Implement this.
    return self.columns.keyEnumerator;
}

- (NSEnumerator *)objectEnumerator {
    NSEnumerator *objectEnumerator = nil;
    if (self.columns.count > 0) {
    
        MTQueryCacheSelectLimitOffset *query = [[MTQueryCacheSelectLimitOffset alloc] initWithLimit:NSUIntegerMax offset:NSUIntegerMax tableName:[self tableName]
                                                                                          dropRowID:false columnKeys:self.columnKeys sortDescriptors:self.sortDescriptors columns:nil whereClause:nil];
        
        NSURL *urlFastCache = [self urlFastCache];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
        objectEnumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                       columns: self.columns columnKeys: self.columnKeys
                                                                                         query: query];
    }
    return objectEnumerator;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert(keys.count == groupLevel, @"Need a key for each previous group.");
    
    NSString *idColumnKeyForGroupLocation = [self idColumnKeyForGroupLocation:groupLevel].copy;
    NSAssert(idColumnKeyForGroupLocation != nil, @"This can't be nil (%s)", __PRETTY_FUNCTION__);
    if (idColumnKeyForGroupLocation == nil) { return nil; }
    
    NSArray <__kindof NSString *> *columnKeys = @[idColumnKeyForGroupLocation];
    
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:keys.count];

    NSUInteger sortLevel;
    for (NSString *key in keys) {
        @autoreleasepool {
            sortLevel = groupLevel >= 1 ? groupLevel - 1 : 0;
            NSString *idColumnKeyForGroupLocation = [self idColumnKeyForGroupLocation:sortLevel].copy;
            NSString *keyPredicateValue = key.copy;
            NSDictionary *whereStatement = [[NSDictionary alloc] initWithObjectsAndKeys: idColumnKeyForGroupLocation, MTQueryKeyPredicateColumn, keyPredicateValue, MTQueryKeyPredicateValue, nil];
            [whereClause addObject:whereStatement];
        }
    }
    
    MTQuery *query = [[MTQueryCacheSelectGroupKeys alloc] initWithTableName:[self tableName] selectPredicates:whereClause fieldNames:columnKeys accending:accending ? true : false columns:self.columns];

    NSURL *urlFastCache = [self urlFastCache];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection columns: self.columns columnKeys: columnKeys
                                                                                                                query: query];
    enumerator.addRowId = NO;
    enumerator.singleColumnNoWrapper = YES;
    return enumerator;
}

- (MTQuery *)queryForAllItemsAllRows {
    
    MTQueryCacheSelectLimitOffset *query = [[MTQueryCacheSelectLimitOffset alloc] initWithLimit:NSUIntegerMax offset:NSUIntegerMax tableName:[self tableName]
                                                                                      dropRowID:false columnKeys:self.columnKeys sortDescriptors:self.sortDescriptors columns:nil whereClause:nil];
    return query;
}

- (MTQuery *)queryForAllRowsWithKeys:(NSArray *)columnKeys {
    
    MTQueryCacheSelectLimitOffset *query = [[MTQueryCacheSelectLimitOffset alloc] initWithLimit:NSUIntegerMax offset:NSUIntegerMax tableName:[self tableName]
                                                                                      dropRowID:false columnKeys:columnKeys sortDescriptors:self.sortDescriptors columns:self.columns whereClause:nil];

    return query;
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    
    MTQueryCacheSelectLimitOffset *query = [[MTQueryCacheSelectLimitOffset alloc] initWithLimit:NSUIntegerMax offset:NSUIntegerMax tableName:[self tableName]
                                                                                      dropRowID:false columnKeys:nil sortDescriptors:self.sortDescriptors columns:nil whereClause:nil];


    NSURL *urlFastCache = [self urlFastCache];

    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];

    MADDataColumn *rowid = [[MADDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
    rowid.columnType = MTDataTypeInteger;
    
    NSDictionary *columns = @{MADIdentifierROWID : rowid};
    NSArray <__kindof NSString *> *columnKeys = @[MADIdentifierROWID];
    
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection columns: columns
                                                                                                           columnKeys: columnKeys query: query];
    [enumerator setAddRowId:NO];
    [enumerator setSingleColumnNoWrapper:YES];
    return enumerator;
}

- (NSArray <__kindof NSString *> *)columnKeysForSortDescriptors {
    NSArray *sortDescriptors = self.sortDescriptors;
    NSMutableArray <__kindof NSString *> *columnKeys = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            NSString *key = sortDescriptor.key.copy;
            [columnKeys addObject:key];
        }
    }
    return columnKeys;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    [self.groupKeys removeAllObjects];
    [self initalizeGroupKeys];
    
    NSEnumerator *enumerator;
    NSArray <__kindof NSString *> *columnKeys = [self columnKeysForSortDescriptors];
    if (columnKeys.count == 0) {
    
        enumerator = [self enumeratorForAllObjectsSortedRowIdOnly];
        
    } else {
    
        MTQuery *query = [self queryForAllRowsWithKeys:columnKeys];
        
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
        enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection columns: self.columns
                                                                              columnKeys: columnKeys query: query];
        [(MTDataTableFastObjectEnumerator *)enumerator setAddRowId:YES];
        [(MTDataTableFastObjectEnumerator *)enumerator setSingleColumnNoWrapper:NO];
    }
    return enumerator;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    
    MTQuery *query = [self queryForAllItemsAllRows];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: self.urlFastCache];
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection columns: self.columns
                                                                                                           columnKeys: self.columnKeys query: query];
    [enumerator setAddRowId:YES];
    [enumerator setSingleColumnNoWrapper:NO];
    return enumerator;
}

- (NSArray *)allObjects {
    // FIXME: Implement this.
    return nil;
}

- (NSUInteger)count {
    return [self numberOfRows];
}

- (NSUInteger)numberOfColumns { return  self.columnKeys.count; }

- (NSUInteger)numberOfRows { return self.rowCounter; }

- (NSString *)columnKeyForColumnName:(NSString *)columnName {
    NSString *key;
    for (NSString *columnKey in self.columnKeys) {
        MADDataColumn *column = self.columns[columnKey];
        if ([[column fieldName] isEqualToString:columnName]) {
            key = [NSString stringWithString: columnKey];
            break;
        }
    }
    return key;
}

- (id)runSelectQuery:(MTQuery *)query {
    id result = nil;
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    sqlite3 *databaseHandle = [self.databaseForSelects databaseHandle];
    
    BOOL success = sqlite3_prepare_v2(databaseHandle, queryString, -1, &statement, NULL) == SQLITE_OK;
    
    for (MTDatabaseDataBinding *dataBinding in [query binaryBindings]) {
        [MTDatabaseSqlite3 bindStatement:&statement withBindings:dataBinding];
    }
    
    if (success && sqlite3_step(statement) == SQLITE_ROW) {
        result = [self objectOfUnknownType:statement forColumnNumber:0];
    }
    NSAssert(success, @"%s", sqlite3_errmsg(databaseHandle));
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return result;
}

- (NSUInteger)columnIndexForKey:(NSString *)key {
    return [self.columnKeys indexOfObject:key];
}

- (id)objectOfUnknownType:(sqlite3_stmt *)statement forColumnNumber:(int)columnIndex {
    //MTDataType aggregateResultType = mad_sqlite3_datatype_for_sqlite3_type(sqlite3_column_type(statement, columnIndex));
    return [MTDatabaseSqlite3 valueForStatement:statement columnNumber:columnIndex];
}

- (id)currentObject:(sqlite3_stmt *)statement {
    NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:self.columns.count];
    int columnCounter = 0;
    for (NSString *key in self.columnKeys) {
        MADDataColumn *dataColumn = self.columns[key];
        id columnValue = [MTDatabaseSqlite3 valueForStatement:statement columnNumber:columnCounter];
        if (columnValue != nil) {
            [currentObject setValue:columnValue forKey:[dataColumn identifier]];
        }
        columnCounter++;
    }
    if (sqlite3_column_count(statement) >= columnCounter) {
        NSNumber *rowid = @(sqlite3_column_int(statement, columnCounter));
        [currentObject setValue:rowid forKey:MADIdentifierROWID];
    }
    return currentObject;
}

/*! Call before bulk insert of data. */

- (void)beginBulkInsert {
    self.bulkInsertLoop = true;
    
    [self reopenDbConnection];
    
    self.sortDescriptorsSet = false;
    [self createIndex];
    
    [self.databaseForInserts beginBulkInsert];

    NSString *tableName = [self tableName];
    NSDictionary *columns = self.columns;
    NSArray *columnKeys = self.columnKeys;
    
    MTQueryCacheAddRow *bulkInsertQuery = [[MTQueryCacheAddRow alloc] initWithColumnKeys:columnKeys columns:columns andTableName:tableName];
    bulkInsertQuery.database = self.databaseForInserts;
    self.bulkInsertQuery = bulkInsertQuery;
    
    if (self.queueBulkAdd == nil) {
        dispatch_queue_t queue = dispatch_queue_create("mad.cache", DISPATCH_QUEUE_SERIAL);
        self.queueBulkAdd = queue;
    }
    
}

/*! Call right after bulk insert of data. */

- (void)endBulkInsert {
    __block typeof(self) myself = self;
    dispatch_barrier_sync(self.queueBulkAdd, ^{
        myself.bulkInsertLoop = false;
        [(MTDatabaseSqlite3 *)myself.databaseForInserts endBulkInsert];
    });
}

#pragma mark - Unused

- (NSEnumerator *)enumeratorForRowIds:(NSArray *)cacheIds {  //Note, software currently usues NSArray for row ids
    
    NSString *tableName = [self tableName];
    MTQuery *query = [[MTQueryCacheSelectRowIds alloc] initWithTableName:tableName rowIDs:cacheIds sortDescriptors:self.sortDescriptors columns:self.columns];
    
    NSArray <__kindof NSString *> *columnKeys = self.columnKeys;
    NSURL *urlFastCache = [self urlFastCache];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl: urlFastCache];
    NSEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection columns: self.columns
                                                                                        columnKeys: columnKeys query: query];
    return enumerator;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"Table name: "];
    [description appendString:[self tableName]];
    [description appendFormat:@"\nColumn keys: %@", self.columnKeys];
    return description;
}

@end
