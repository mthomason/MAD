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
#import <MADFoundation/MTDataColumn.h>
#import "MADConstants.h"

#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTQuery.h"
#import "MTQueryCacheAddRow.h"
#import "MTQueryCacheIndexDrop.h"
#import "MTQueryCacheVacuum.h"
#import "MTQueryCacheDropTable.h"
#import "MTQueryCacheDeleteAllFromTable.h"

@interface MTDataTableFast ()

@property (nonatomic, strong) MTDatabaseCache *databaseForInserts;
@property (nonatomic, strong, readwrite) MTDatabaseCache *databaseForSelects;

@property (nonatomic, strong) NSURL *urlFastCache;

@property (nonatomic, assign) bool bulkInsertLoop;
@property (nonatomic, assign) bool sortDescriptorsSet;

@property (nonatomic, strong) NSMutableArray *groupKeys;
@property (nonatomic, strong) NSArray *groupTableNames;

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
    return [self initWithId:objectId fromCache:YES];
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

    if ([self groupTableNames] != nil) {
        NSString *keyGroupTableNames = [MTDataTableFast keyGroupTableNames];
        plist[keyGroupTableNames] = [self groupTableNames];
    }
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
    
    NSArray *groupTableNames = plist[[MTDataTableFast keyGroupTableNames]];
    [self setGroupTableNames:groupTableNames];
    
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
        
        NSArray *groupTableNames = [decoder decodeObjectForKey:[MTDataTableFast keyGroupTableNames]];
        self.groupTableNames = groupTableNames;
        
        [self reopenDbConnection];
    }
    return self;
}

- (NSString *)filenameCacheMadDB {
    NSString *tag = [NSString stringWithFormat:@"%lu", (unsigned long)self.tag];
    return [tag stringByAppendingString:@"maddb"];
}

- (NSURL *)urlFastCache {
    NSString *filename = [self filenameCacheMadDB];
    NSURL *cacheDirectory = self.cacheDelegate == nil ?
                            [[NSFileManager defaultManager] localCacheDirectoryForGroupIdentifier:MADIdentifierGroup] :
                                [self.cacheDelegate cachedFilesDirectory];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (void)setCacheDelegate:(id<MTCacheProtocol>)cacheDelegate {
    super.cacheDelegate = cacheDelegate;
    [super loadFromCacheWithGroupIdentifier:MADIdentifierGroup];
    [self reopenDbConnection];
}

- (void)reopenDbConnection {
    MTDatabaseConnection *connection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:[self urlFastCache]];
    
    MTDatabaseCache *database = [[MTDatabaseSqlite3 alloc] init];
    database.databaseConnection = connection;
    [(MTDatabaseSqlite3 *)database openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
    self.databaseForInserts = database;
    
    MTDatabaseCache *database2 = [MTDatabaseCache databaseFactory:connection];
    self.databaseForSelects = database2;
}

- (NSString *)tableName {
    char buf[19];
    snprintf(buf, 19, "t%lu", (unsigned long)self.tag);
    return @(buf);
}

- (void)addColumn:(MTDataColumn *)column {
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

    NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithCapacity:self.sortDescriptors.count];
    NSArray *sortDescriptors = self.sortDescriptors;
    
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            NSUInteger index = [self.columnKeys indexOfObject: sortDescriptor.key];
            if (index != NSNotFound) {
                NSNumber *columnIndex = @(index);
                [groupKeys addObject:columnIndex];
            }
        }
    }

    self.groupKeys = groupKeys;
    groupKeys = nil;
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

- (MTDataColumn *)idDataColumnForGroupLevel:(NSUInteger)groupLevel {
    NSString *key = [self idColumnKeyForGroupLocation:groupLevel];
    return self.columns[key];
}

- (void)addColumn:(MTDataColumn *)column toTable:(NSString *)table columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    NSNumber *createTable = @(create);
    NSDictionary *queryDefination = @{
                                      @(MTQueryCacheAddColumnDataColumn) : column,
                                      @(MTQueryCacheAddColumnTableName) : table,
                                      @(MTQueryCacheAddColumnColumnName) : columnName,
                                      @(MTQueryCacheAddColumnCreateTable) : createTable,
                                      @(MTQueryCacheAddColumnUnique) : @(unique),
                                      };
    
    bool success = false;
    NSError * __autoreleasing errorQuery = NULL;
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddColumn object:queryDefination];
    success = [self.databaseForInserts executeQuery:query withError:&errorQuery];
}

- (void)addRow:(NSArray *)row {
    self.rowCounter++;
    if (self.groupKeys == nil) {
        [self.groupKeys removeAllObjects];
        [self initalizeGroupKeys];
    }
    
    
    if (self.bulkInsertLoop) {
        @autoreleasepool {

            NSArray *rowData = [NSArray arrayWithArray: row];
            self.bulkInsertQuery.rowData = rowData;
            
            NSString * __strong sql = [[NSString alloc] initWithString:[self.bulkInsertQuery getSqlWithError:nil]];
            NSArray * __strong binaryBindings = [[NSArray alloc] initWithArray:self.bulkInsertQuery.binaryBindings];
            NSArray * __strong fieldKeys = [[NSArray alloc] initWithArray:self.bulkInsertQuery.fieldKeys];
            
            MTDatabaseSqlite3 * dbForInserts = ((MTDatabaseSqlite3 *)self.databaseForInserts);
            struct sqlite3 *db = dbForInserts.database;

            dispatch_queue_t q = self.queueBulkAdd;
            dispatch_async(q, ^{

                [MTDatabaseSqlite3 executeQueryWithSql:sql
                                                      database:db
                                           queryBinaryBindings:binaryBindings
                                                queryFieldKeys:fieldKeys
                                     queryPartOfTransactionSet:YES];

            });

            rowData = nil; // release?
            sql = nil;
            fieldKeys = nil;
            binaryBindings = nil;
       
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
                                [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddRow object:queryDefination];
        
        bool success;
        NSError * __autoreleasing errorQuery = NULL;
        success = [self.databaseForInserts executeQuery:query withError:&errorQuery];

    }
    
    
}

// FIXME: Maybe wrap in autorelease block.
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {

    @autoreleasepool {
        
        NSMutableArray *rowData = [[NSMutableArray alloc] init];
        for (id columnDefKey in self.columnKeys) {
            MTDataColumn *columnDef = self.columns[columnDefKey];
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
                        MTDataColumn * __weak column = self.columns[columnKey];
                        if ([column.fieldName isEqualToString:sortDescriptor.key]) {
                            SEL sortAlgo = [MADDataType selectorForSorting:column.columnType.unsignedIntegerValue];
                            
                            NSSortDescriptor *newSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:columnKey
                                                                                                ascending:sortDescriptor.ascending
                                                                                                 selector:sortAlgo];
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
    NSDictionary * __autoreleasing parameters = @{
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
    MTDataColumn *columnMetaData = self.columns[key];
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
            NSDictionary * __autoreleasing result = [NSDictionary dictionaryWithDictionary:self.lastDataForCacheId.object];
            return result;
        }
    }
    
    NSDictionary * __autoreleasing result = nil;
    
    NSNumber *keyRowId = @(MTQuerySelectRowId);
    NSNumber *keyFieldKey = @(MTQuerySelectFieldKeys);
    NSNumber *keyTableNmae = @(MTQuerySelectTableName);
    NSNumber *keyFieldDef = @(MTQuerySelectFieldDescriptors);
    NSDictionary *options = @{
                              keyRowId : cacheId,
                              keyFieldKey : self.columnKeys,
                              keyTableNmae : [self tableName],
                              keyFieldDef : self.columns
                              };
    
    MTQuery * __autoreleasing query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectRowId object:options];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlUTF8String = sql.UTF8String;
    char *queryString = sqlite3_mprintf((char *) sqlUTF8String);
    bool success = sqlite3_prepare_v2([self.databaseForSelects databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
    
    if (success) {  //Expect success to == NO in normal working conditions.
        success = sqlite3_step(statement) == SQLITE_ROW;
        if (success) {
            result = [NSDictionary dictionaryWithDictionary:[self currentObject:statement]];
            
            MADIndex * __autoreleasing lastDataForCacheId = [[MADIndex alloc] initWithIndex:cacheId.unsignedIntegerValue andObject:result];
            self.lastDataForCacheId = lastDataForCacheId;
            
        } else {
            result = @{};
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);

    return result;
}

- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys {
    [self initalizeGroupKeys];
    NSMutableArray * __autoreleasing whereClause = [[NSMutableArray alloc] initWithCapacity:groupKeys.count];
    NSUInteger groupLevel = 0;
    for (NSString *key in groupKeys) {
        @autoreleasepool {
            NSString *columnLevel = [self idColumnKeyForGroupLocation:groupLevel].copy;
            NSString *gk = key.copy;
            NSDictionary *whereStatement = @{MTQueryKeyPredicateColumn : columnLevel,
                                             MTQueryKeyPredicateValue : gk};
            [whereClause addObject:whereStatement];
            groupLevel++;
        }
    }
    return whereClause;
}

// FIXME: Return error handler... remove credentals
- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys {

    [self initalizeGroupKeys];

    NSMutableArray * __autoreleasing results = [[NSMutableArray alloc] init];
    NSArray *whereClause = [self whereClauseForGroupKeys:groupKeys];
    NSString *tableName = [self tableName];
    NSArray *sortDescriptors = self.sortDescriptors;
    NSDictionary *columns = self.columns;
    NSArray *columnKeys = self.columnKeys;
    NSDictionary *querySelect = @{
                                  @(MTQuerySelectFieldKeys) : columnKeys,
                                  @(MTQuerySelectTableName) : tableName,
                                  @(MTQuerySelectPredicates) : whereClause,
                                  @(MTQuerySelectSortDescriptors) : sortDescriptors,
                                  @(MTQuerySelectFieldDescriptors) : columns
                                  
                                  };
    MTQuery * __autoreleasing query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectItemsForGroupKeys object: querySelect];
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
                NSDictionary *result = [NSDictionary dictionaryWithDictionary:[self currentObject:statement]];
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
    
    NSDictionary *queryDefination = [self queryDefinationSelectWithLimit:limit andOffset:row];
    MTQuery * __autoreleasing query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefination];

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
    if ([self.columns count] > 0) {
        NSDictionary *queryDefination = [self queryDefinationSelect];
        MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefination];

        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:[self urlFastCache]];
        objectEnumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection:databaseConnection
                                                                                       columns:self.columns
                                                                                    columnKeys:self.columnKeys
                                                                                           query:query];
    }
    return objectEnumerator;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending {
    NSAssert([keys count] == groupLevel, @"Need a key for each previous group.");
    
    NSArray *columnKeys = @[[self idColumnKeyForGroupLocation:groupLevel]];
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:[keys count]];

    NSUInteger sortLevel;
    for (NSString *key in keys) {
        sortLevel = groupLevel >= 1 ? groupLevel - 1 : 0;
        NSDictionary *whereStatement = @{@"c" : [self idColumnKeyForGroupLocation:sortLevel],
                                         @"v" : key};
        [whereClause addObject:whereStatement];
    }

    NSDictionary *querySelect = @{
                                  @(MTQuerySelectFieldKeys) : columnKeys,
                                  @(MTQuerySelectTableName) : [self tableName],
                                  @(MTQuerySelectSortAccending) : @(accending),
                                  @(MTQuerySelectPredicates) : whereClause,
                                  @(MTQuerySelectColumns) : self.columns
                                  };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectGroupKeys object: querySelect];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: [self urlFastCache]];
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                             columns: self.columns
                                                                          columnKeys: columnKeys
                                                                               query: query];
    [enumerator setAddRowId:NO];
    [enumerator setSingleColumnNoWrapper:YES];
    return enumerator;
}

- (MTQuery *)queryForAllItemsAllRows {
    NSDictionary *options = @{
                              @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys) : self.columnKeys,
                              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : self.sortDescriptors,
                              };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:options];
    return query;
}

- (MTQuery *)queryForAllRowsWithKeys:(NSArray *)columnKeys {
    
    NSDictionary *options = @{
                              @(MTQueryCacheSelectLimitOffsetParamatersColumns) : self.columns,
                              @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys) : columnKeys,
                              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : self.sortDescriptors,
                              };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:options];
    return query;
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    
    NSDictionary *options = @{
                              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : self.sortDescriptors,
                              };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:options];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: [self urlFastCache]];
    
    MTDataColumn *rowid = [[MTDataColumn alloc] initWithIdentifier:MADIdentifierROWID];
    [rowid setColumnType:@(MTDataTypeInteger)];
    
    NSDictionary *columns = @{MADIdentifierROWID : rowid};
    NSArray *columnKeys = @[MADIdentifierROWID];
    
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                                              columns: columns
                                                                                                           columnKeys: columnKeys
                                                                                                                query: query];
    [enumerator setAddRowId:NO];
    [enumerator setSingleColumnNoWrapper:YES];
    return enumerator;
}

- (NSArray *)columnKeysForSortDescriptors {
    NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:[self.sortDescriptors count]];
    for (NSSortDescriptor *sortDescriptor in self.sortDescriptors) {
        [columnKeys addObject:[sortDescriptor key]];
    }
    return columnKeys;
}

- (NSEnumerator *)enumeratorForKeyObjectsSorted {
    [self.groupKeys removeAllObjects];
    [self initalizeGroupKeys];
    
    NSEnumerator *enumerator;
    NSArray *columnKeys = [self columnKeysForSortDescriptors];
    if ([columnKeys count] == 0) {
        enumerator = [self enumeratorForAllObjectsSortedRowIdOnly];
    } else {
        MTQuery *query = [self queryForAllRowsWithKeys:columnKeys];
        
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: [self urlFastCache]];
        
        enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                 columns: self.columns
                                                                              columnKeys: columnKeys
                                                                                   query: query];
        [(MTDataTableFastObjectEnumerator *)enumerator setAddRowId:YES];
        [(MTDataTableFastObjectEnumerator *)enumerator setSingleColumnNoWrapper:NO];
    }
    return enumerator;
}

- (NSEnumerator *)enumeratorForAllObjectsSorted {
    
    MTQuery *query = [self queryForAllItemsAllRows];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: [self urlFastCache]];
    
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                                              columns: self.columns
                                                                                                           columnKeys: self.columnKeys
                                                                                                                query: query];
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
        MTDataColumn *column = self.columns[columnKey];
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
        MTDataColumn *dataColumn = self.columns[key];
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
    
    NSNumber *keyRowIds = @(MTQuerySelectRowIds);
    NSNumber *keyTableN = @(MTQuerySelectTableName);
    NSNumber *keySortDe = @(MTQuerySelectSortDescriptors);
    NSNumber *keyColumn = @(MTQuerySelectColumns);
    
    NSString *tableName = [NSString stringWithString:[self tableName]];
    NSArray *sortDescs = [NSArray arrayWithArray:self.sortDescriptors];
    NSDictionary *columns = [NSDictionary dictionaryWithDictionary:self.columns];
    
    NSDictionary *options = @{
                                keyRowIds : cacheIds,
                                keyTableN : tableName,
                                keySortDe : sortDescs,
                                keyColumn : columns
                              };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectRowIds object:options];
    
    NSArray *columnKeys = self.columnKeys;
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:[self urlFastCache]];
    NSEnumerator *data = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection:databaseConnection
                                                                                     columns:columns
                                                                                  columnKeys:columnKeys
                                                                                       query:query];
    return data;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"Table name: "];
    [description appendString:[self tableName]];
    [description appendFormat:@"\nColumn keys: %@", self.columnKeys];
    return description;
}

@end
