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
#import "NSFileManager+Common.h"
#import "MTQuery.h"
#import "MTDataColumn.h"
#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseSqlite3.h"
#import "MTPair.h"
#import "MTDatabaseConnectionSqlite3.h"

@interface MTDataTableFast ()

@property (nonatomic, strong) MTDatabaseCache *databaseForInserts;
@property (nonatomic, strong) MTDatabaseCache *databaseForSelects;

@property (nonatomic, strong) NSURL *urlFastCache;
@property (nonatomic, assign) BOOL bulkInsertLoop;
@property (nonatomic, assign) BOOL sortDescriptorsSet;

@property (nonatomic, strong) NSMutableArray *groupKeys;
@property (nonatomic, strong) NSArray *groupTableNames;

@property (nonatomic, strong) MTPair *lastDataForCacheId;

@end

@implementation MTDataTableFast

- (void)dealloc {
    
}

- (NSDictionary *)plist {
    
    NSDictionary *superPlist = [super plist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    
    NSString *keyUrlFastCache = [MTDataTableFast keyUrlFastCache];
    NSString *keyTag = [MTDataTableFast keyTag];
    NSString *keyBulkInsertLoop = [MTDataTableFast keyBulkInsertLoop];

    plist[keyUrlFastCache] = [[self urlFastCache] absoluteString];
    plist[keyTag] = @([self tag]);
    plist[keyBulkInsertLoop] = @([self bulkInsertLoop]);
    
    NSString *keyGroupKeys = [MTDataTableFast keyGroupKeys];
    NSString *keySortDescriptorsSet = [MTDataTableFast keySortDescriptorsSet];

    if ([self groupTableNames] != nil) {
        NSString *keyGroupTableNames = [MTDataTableFast keyGroupTableNames];
        plist[keyGroupTableNames] = [self groupTableNames];
    }
    if (self.groupKeys != nil) {
        plist[keyGroupKeys] = self.groupKeys;
    }
    plist[keySortDescriptorsSet] = @([self sortDescriptorsSet]);
    
    return plist;
}

- (void)loadWithPlist:(NSDictionary *)plist {
    [super loadWithPlist:plist];
    
    NSString *absoluteString = plist[[MTDataTableFast keyUrlFastCache]];
    NSURL *url = [NSURL URLWithString:absoluteString];
    [self setUrlFastCache: url];
    
    NSNumber *tagWrapper = plist[[MTDataTableFast keyTag]];

     NSUInteger tag = [tagWrapper integerValue];
    [self setTag:tag];
    
    NSNumber *bulkInsertLoopWrapper = plist[[MTDataTableFast keyBulkInsertLoop]];
    BOOL bulkInsertLoop = [bulkInsertLoopWrapper boolValue];
    [self setBulkInsertLoop:bulkInsertLoop];
    
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


- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];

    [encoder encodeObject:  [_urlFastCache absoluteString]      forKey: [MTDataTableFast keyUrlFastCache]];
    NSNumber *objid = @(self.tag);
    [encoder encodeObject: objid                                forKey: [MTDataTableFast keyTag]];
    [encoder encodeBool: _bulkInsertLoop                        forKey: [MTDataTableFast keyBulkInsertLoop]];
    [encoder encodeBool:_sortDescriptorsSet forKey:[MTDataTableFast keySortDescriptorsSet]];

}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        
        NSString *absoluteString = [decoder decodeObjectForKey: [MTDataTableFast keyUrlFastCache]];
        NSURL *url = [NSURL URLWithString:absoluteString];
        [self setUrlFastCache: url];
        
        NSNumber *tag = [decoder decodeObjectForKey: [MTDataTableFast keyTag]];
        [self setTag:tag.unsignedIntegerValue];

        BOOL bulkInsertLoop = [decoder decodeBoolForKey: [MTDataTableFast keyBulkInsertLoop]];;
        [self setBulkInsertLoop:bulkInsertLoop];

        BOOL sortDescriptorsSet = [decoder decodeBoolForKey: [MTDataTableFast keySortDescriptorsSet]];;
        [self setSortDescriptorsSet:sortDescriptorsSet];
        
        NSArray *groupKeysArray = [decoder decodeObjectForKey: [MTDataTableFast keyGroupKeys]];
        NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithArray: groupKeysArray];
        [self setGroupKeys:groupKeys];
        
        NSArray *groupTableNames = [decoder decodeObjectForKey:[MTDataTableFast keyGroupTableNames]];
        [self setGroupTableNames:groupTableNames];
        
        [self reopenDbConnection];
    }
    return self;
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}

- (instancetype)initWithId:(NSUInteger)objectId {
    return [self initWithId:objectId fromCache:YES];
}

- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache {
    self = [super initWithId:objectId fromCache:fromCache];
    if (self) {
        [self setBulkInsertLoop:NO];
        [self setTag:objectId];
        [self setSortDescriptorsSet:NO];
        //[self reopenDbConnection];
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
                            [NSFileManager localCacheDirectory] :
                                [[self cacheDelegate] cachedFilesDirectory];
    return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (void)setCacheDelegate:(id<MTCacheProtocol>)cacheDelegate {
    super.cacheDelegate = cacheDelegate;
    [super loadFromCache];
    [self reopenDbConnection];
}

- (void)reopenDbConnection {
    //MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:[self urlFastCache]];
    MTDatabaseConnection *connection = [[MTDatabaseConnectionSqlite3 alloc] initWithUrl:[self urlFastCache]];
    MTDatabaseCache *database = [[MTDatabaseSqlite3 alloc] init];
    [database setDatabaseConnection:connection];
    [(MTDatabaseSqlite3 *)database openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX];
    //MTDatabaseCache *database = [MTDatabaseCache databaseFactory:connection];
    [self setDatabaseForInserts:database];
    MTDatabaseCache *database2 = [MTDatabaseCache databaseFactory:connection];
    [self setDatabaseForSelects:database2];
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
        NSMutableArray *groupKeys = [[NSMutableArray alloc] initWithCapacity:[[self sortDescriptors] count]];
        for (NSSortDescriptor *sortDescriptor in [self sortDescriptors]) {
            NSUInteger index = [self.columnKeys indexOfObject: [sortDescriptor key]];
            if (index != NSNotFound) {
                NSNumber *columnIndex = @(index);
                [groupKeys addObject:columnIndex];
            }
        }
        [self setGroupKeys:groupKeys];
        groupKeys = nil;
}

- (NSString *)idColumnKeyForGroupLocation:(NSInteger)groupLevel {
    NSString *result = nil;
    if ([self.groupKeys count] > groupLevel) {
        NSInteger loc = [self.groupKeys[groupLevel] integerValue];
        result = self.columnKeys[loc];
    }
    return result;
}

- (MTDataColumn *)idDataColumnForGroupLevel:(NSInteger)groupLevel {
    NSString *key = [self idColumnKeyForGroupLocation:groupLevel];
    return self.columns[key];
}

- (void)addRow:(NSArray *)row {
    self.rowCounter++;
    if (self.groupKeys == nil) {
        [self.groupKeys removeAllObjects];
        [self initalizeGroupKeys];
    }

    [self addRow:row toTable:[self tableName] withColumns:self.columns andColumnKeys:self.columnKeys];
}

- (void)addColumn:(MTDataColumn *)column toTable:(NSString *)table
       columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    NSNumber *createTable = @(create);
    NSDictionary *queryDefination = @{
                                      @(MTQueryCacheAddColumnDataColumn) : column,
                                      @(MTQueryCacheAddColumnTableName) : table,
                                      @(MTQueryCacheAddColumnColumnName) : columnName,
                                      @(MTQueryCacheAddColumnCreateTable) : createTable,
                                      @(MTQueryCacheAddColumnUnique) : @(unique),
                                      };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddColumn object:queryDefination];
    
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)addRow:(NSArray *)row toTable:(NSString *)tableName withColumns:(NSDictionary *)columns andColumnKeys:(NSArray *)columnKeys {
    NSNumber *keyKeys = @(MTQueryCacheAddRowColumnKeys);
    NSNumber *keyColumns = @(MTQueryCacheAddRowColumns);
    NSNumber *keyData = @(MTQueryCacheAddRowData);
    NSNumber *keyTableName = @(MTQueryCacheAddRowTableName);
    NSDictionary *queryDefination = @{
                                      keyKeys : columnKeys,
                                      keyColumns : columns,
                                      keyData : row,
                                      keyTableName : tableName
                                      };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddRow object:queryDefination];
    
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}


- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {
    NSMutableArray *rowData = [[NSMutableArray alloc] init];
    for (id columnDefKey in self.columnKeys) {
        MTDataColumn *columnDef = self.columns[columnDefKey];
        id obj = row[[columnDef fieldName]];
        if (obj == nil) obj = [NSNull null];
        [rowData addObject:obj];
    }
    [self addRow:rowData];
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {

    [self.groupKeys removeAllObjects];
    if ([self.columnKeys count] > 0 && [self.columns count] > 0) {
        
        if ([sortDescriptors count] > 0 /*&& self.sortDescriptorsSet == NO*/) {
            
            NSMutableArray *newSortDescriptors = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
            NSSortDescriptor *sortDescriptor, *newSortDescriptor;
            NSInteger i;
            SEL sortAlgo;
            NSString *columnKey;
            MTDataColumn *column;
            NSNumber *groupKey;
            
            for (sortDescriptor in sortDescriptors) {
                i = 0;
                for (columnKey in self.columnKeys) {
                    column = self.columns[columnKey];
                    if ([column.fieldName isEqualToString:sortDescriptor.key]) {
                        sortAlgo = [MTDataTypeObject selectorForSorting:column.columnType.integerValue];
                        newSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:columnKey
                                                                          ascending:sortDescriptor.ascending
                                                                           selector:sortAlgo];
                        [newSortDescriptors addObject:newSortDescriptor];
                        groupKey = @(i);
                        [self.groupKeys addObject:groupKey];
                        break;
                    }
                    i++;
                }
                if (newSortDescriptors.count == sortDescriptors.count) {
                    self.sortDescriptorsSet = YES;
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

    NSInteger sortDescCtr = [sortDescriptors count];
    NSUInteger capacity = sortDescCtr + 1;
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:capacity];
    [results addObject:sortDescriptors];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        @autoreleasepool {
            NSArray *group = @[sortDescriptor];
            [results addObject:group];
        }
    }
    return results;
}

- (NSString *)cacheTableNameForGroupLevel:(NSInteger)groupLevel {
    return [NSString stringWithFormat:@"s%ld", (long)groupLevel];
}

- (NSString *)indexNameForGroupLevel:(NSInteger)groupLevel andIndex:(NSInteger)index {
    return [NSString stringWithFormat:@"i%ld%ld", (long)groupLevel, (long)index];
}

- (NSDictionary *)createIndexParametersForIndexName:(NSString *)indexName tableName:(NSString *)tableName andSortDescriptors:(NSArray *)sortDescriptors {
    return @{
             @(MTQueryCacheIndexCreateIndexName)         : indexName,
             @(MTQueryCacheIndexCreateTableName)         : tableName,
             @(MTQueryCacheIndexCreateSortDescriptors)   : sortDescriptors,
             @(MTQueryCacheIndexCreateColumns)           : self.columns
             };
}

- (void)createIndex {
    
    NSArray *sortDescriptors = [[self dataDelegate] sortDescriptors];
    [[self sortDescriptors] setArray:sortDescriptors];
    [self sortUsingDescriptors:[self sortDescriptors]];
    
    NSInteger sortDescCtr = [[self sortDescriptors] count];
    NSArray *sortDescriptorGroups = [self sortDescriptorIndexGroupsForSortDescriptors:[self sortDescriptors]];
    
    NSInteger groupCounter = 0;
    for (NSArray *sortDescriptors in sortDescriptorGroups) {

        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSDictionary *parametersCreateIndex = [self createIndexParametersForIndexName:groupName
                                                                            tableName:[self tableName]
                                                                   andSortDescriptors:sortDescriptors];
  
        MTQuery *queryCreateIndex = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheIndexCreateParameters
                                                                object: parametersCreateIndex];
        dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
        [queryCreateIndex performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
            NSAssert(success, @"Error %@", error);
            dispatch_semaphore_signal(semaphoreQuery);
        }];
        dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
        groupCounter++;
    }

    
}

- (void)dropIndex {
    NSInteger sortDescCtr = [[self sortDescriptors] count];
    NSInteger groupCounter = 0;
    for (NSInteger i = 0; i<sortDescCtr; i++) {
        NSString *groupName = [self indexNameForGroupLevel:sortDescCtr andIndex:groupCounter];
        NSDictionary *parameters = @{
                                     @(MTQueryCacheIndexDropIndexName) : groupName,
                                     };
        MTQuery *query = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheIndexDropParameters
                                                     object: parameters];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [query performQueryWithDatabase:[self databaseForInserts]
                             completion:^(BOOL success, NSError *error) {
                                 NSAssert(success, @"Error %@", error);
                                 dispatch_semaphore_signal(semaphore);
                             }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)vacuumCacheDb {
    NSDictionary *queryVacuumDefination = @{ };
    MTQuery *queryVacuum = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheVacuum object:queryVacuumDefination];

    dispatch_semaphore_t semaphoreVacuum = dispatch_semaphore_create(0);
    [queryVacuum performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(semaphoreVacuum);
    }];
    dispatch_semaphore_wait(semaphoreVacuum, DISPATCH_TIME_FOREVER);

}

- (void)dropTable {
    [self dropTableName:[self tableName]];
}

- (void)dropTableName:(NSString *)tableName {
    NSNumber *tableNameKey = @(MTQueryCacheDropTableTableName);
    NSDictionary *queryDefination = @{
                                      tableNameKey : tableName
                                      };
    
    MTQuery *queryDropTable = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheDropTable object:queryDefination];
    
    dispatch_semaphore_t semaphoreDropTable = dispatch_semaphore_create(0);
    [queryDropTable performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(semaphoreDropTable);
    }];
    dispatch_semaphore_wait(semaphoreDropTable, DISPATCH_TIME_FOREVER);
}

- (void)deleteAll {
    NSDictionary *queryDefination = [MTQuery queryDefinitionCacheDeleteAllFromTable:[self tableName]];
    MTQuery *queryDeleteAllFromTable = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheDeleteAllFromTable
                                                                   object: queryDefination];
    
    dispatch_semaphore_t semaphoreDeleteAll = dispatch_semaphore_create(0);
    [queryDeleteAllFromTable performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(semaphoreDeleteAll);
    }];
    dispatch_semaphore_wait(semaphoreDeleteAll, DISPATCH_TIME_FOREVER);

}

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
    // FIXME: Query just this field.
    NSDictionary *objForRow = [self objectAtRow:row];
    NSString *key = self.columnKeys[0];
    MTDataColumn *columnMetaData = self.columns[key];
    NSString *fieldName = [columnMetaData fieldName];
    return objForRow[fieldName];
}

- (NSDictionary *)objectAtRow:(NSInteger)row {
    return [[self objectAtRow:row limit:1] firstObject];
}

- (NSDictionary *)queryDefinationSelect {
    return [MTQuery queryDefinitionSelect:self.columnKeys tableName:[self tableName] sortDescriptors:[self sortDescriptors]];
}

- (NSDictionary *)queryDefinationSelectWithLimit:(NSInteger)limit andOffset:(NSInteger)offset {
    return [MTQuery queryDefinitionSelect:[self queryDefinationSelect] withLimit:limit andOffset:offset];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {

    NSDictionary *result = nil;
    if ([self lastDataForCacheId] != nil) {
        if ([cacheId isEqualToNumber:[self.lastDataForCacheId former]]) {
            result = [NSDictionary dictionaryWithDictionary:[self.lastDataForCacheId latter]];
        }
    }
    if (result == nil) {
        
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
        MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectRowId object:options];
        sqlite3_stmt *statement = NULL;
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        const char *sqlc = [sql UTF8String];
        char *queryString = sqlite3_mprintf((char *) sqlc);
        BOOL success = sqlite3_prepare_v2([[self databaseForSelects] databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;

        if (success) {  //Expect success to == NO in normal working conditions.
            success = sqlite3_step(statement) == SQLITE_ROW;
            result = [self currentObject:statement];
            self.lastDataForCacheId = [MTPair pairWithFormer:cacheId andLatter:result];
        }
        
        sqlite3_finalize(statement);
        sqlite3_free(queryString);

    }
    return result;
}

- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys {
    [self initalizeGroupKeys];
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:[groupKeys count]];
    NSInteger groupLevel = 0;
    for (NSString *key in groupKeys) {
        NSDictionary *whereStatement = @{MTQueryKeyPredicateColumn : [self idColumnKeyForGroupLocation:groupLevel],
                                         MTQueryKeyPredicateValue : key};
        [whereClause addObject:whereStatement];
        groupLevel++;
    }
    return whereClause;
}

- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys {

    [self initalizeGroupKeys];

    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSArray *whereClause = [self whereClauseForGroupKeys:groupKeys];
    NSDictionary *querySelect = @{
                                  @(MTQuerySelectFieldKeys) : self.columnKeys,
                                  @(MTQuerySelectTableName) : [self tableName],
                                  @(MTQuerySelectPredicates) : whereClause,
                                  @(MTQuerySelectSortDescriptors) : [self sortDescriptors],
                                  @(MTQuerySelectFieldDescriptors) : self.columns
                                  
                                  };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectItemsForGroupKeys object: querySelect];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    sqlite3 *databaseHandle = [[self databaseForSelects] databaseHandle];
    
    BOOL success = sqlite3_prepare_v2(databaseHandle, queryString, -1, &statement, NULL) == SQLITE_OK;
    
    for (MTDatabaseDataBinding *dataBinding in [query binaryBindings]) {
        [(MTDatabaseSqlite3 *)self.databaseForSelects bindStatement:&statement withBindings:dataBinding];
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

- (NSArray *)objectAtRow:(NSInteger)row limit:(NSUInteger)limit {
    
    NSDictionary *queryDefination = [self queryDefinationSelectWithLimit:limit andOffset:row];
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefination];

    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:limit];
    if (row != NSNotFound && limit > 0) {
        sqlite3_stmt *statement = NULL;
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        const char *sqlc = [sql UTF8String];
        char *queryString = sqlite3_mprintf((char *) sqlc);
        BOOL success = sqlite3_prepare_v2([[self databaseForSelects] databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
        NSAssert(success, @"%s", sqlite3_errmsg([[self databaseForSelects] databaseHandle]));
        if (success) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                @autoreleasepool {
                    NSDictionary *currentObject = [self currentObject:statement];
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
    return [self.columns keyEnumerator];
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
    
    for (NSString *key in keys) {
        NSInteger sortLevel = groupLevel - 1;
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
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : [self sortDescriptors],
                              };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:options];
    return query;
}

- (MTQuery *)queryForAllRowsWithKeys:(NSArray *)columnKeys {
    
    NSDictionary *options = @{
                              @(MTQueryCacheSelectLimitOffsetParamatersColumns) : self.columns,
                              @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys) : columnKeys,
                              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : [self sortDescriptors],
                              };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:options];
    return query;
}

- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly {
    
    NSDictionary *options = @{
                              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : [self sortDescriptors],
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
    NSMutableArray *columnKeys = [[NSMutableArray alloc] initWithCapacity:[[self sortDescriptors] count]];
    for (NSSortDescriptor *sortDescriptor in [self sortDescriptors]) {
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
    
    //[self.groupKeys removeAllObjects];
    //[self initalizeGroupKeys];
    
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

- (NSUInteger)numberOfColumns {
    return  [self.columnKeys count];
}

- (NSUInteger)numberOfRows {
    return [self rowCounter];
}


- (NSDictionary *)paramatersAggregateWithFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    NSNumber *keyTableName = @(MTQueryCacheAggregateFunctionParamatersTableName);
    NSNumber *keyFieldKey = @(MTQueryCacheAggregateFunctionParamatersFieldKey);
    NSNumber *keyAggregateFunctionType = @(MTQueryCacheAggregateFunctionParamatersAggregateFunctionType);
    NSNumber *keyFieldDescriptors = @(MTQueryCacheAggregateFunctionParamatersFieldDescriptors);
    NSNumber *objFunctionType = @(functionType);
    return @{
             keyTableName : [self tableName],
             keyFieldKey : fieldKey,
             keyFieldDescriptors : self.columns,
             keyAggregateFunctionType: objFunctionType
             };
}

- (NSDictionary *)paramatersAggregateByPageWithFieldKey:(NSString *)fieldKey andRowIds:(NSArray *)rowids andFunctionType:(MTAggregateFunctionType)functionType {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType]];
    NSNumber *keyRowids = @(MTQueryCacheAggregateFunctionParamatersRowids);
    parameters[keyRowids] = rowids;
    return parameters;
}

- (NSDictionary *)paramatersAggregateByGroupKeys:(NSArray *)groupKeys andFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType]];
    NSNumber *keyWhereClause = @(MTQueryCacheAggregateFunctionParamatersPredicates);
    parameters[keyWhereClause] = [self whereClauseForGroupKeys:groupKeys];
    return parameters;
}

- (NSDictionary *)parametersAggregateByReportWithFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    return [self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType];
}

- (id)resultsForAggregateType:(MTAggregateGroupByType)groupByType
                     function:(MTAggregateFunctionType)function
                     fieldKey:(NSString *)fieldKey
                    groupKeys:(NSArray *)groupKeys
                       rowids:(NSArray *)rowids {
    id result = nil;
  
    NSString *columnKey = [self columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        NSDictionary *queryParameters;
        
        MTQueryType queryType = MTQueryTypeCacheAggregateFunction;
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                queryParameters = [NSMutableDictionary dictionaryWithDictionary: [self paramatersAggregateByPageWithFieldKey:columnKey andRowIds:rowids andFunctionType:function]];
                NSNumber *groupByTypeNumber = @(groupByType);
                NSNumber *groupByTypeKey = @(MTQueryCacheAggregateFunctionParamatersGroupByType);
                ((NSMutableDictionary *)queryParameters)[groupByTypeKey] = groupByTypeNumber;

                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [self parametersAggregateByReportWithFieldKey:columnKey andFunctionType:function];
                break;
                
            case MTAggregateGroupByTypeSection:
                //[self initalizeGroupKeys];
                queryParameters = [self paramatersAggregateByGroupKeys:groupKeys andFieldKey:columnKey andFunctionType:function];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType:queryType object:queryParameters];
        sqlite3_stmt *statement = NULL;
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        const char *sqlc = [sql UTF8String];
        char *queryString = sqlite3_mprintf((char *) sqlc);
        sqlite3 *databaseHandle = [[self databaseForSelects] databaseHandle];
        
        BOOL success = sqlite3_prepare_v2(databaseHandle, queryString, -1, &statement, NULL) == SQLITE_OK;
        
        for (MTDatabaseDataBinding *dataBinding in [query binaryBindings]) {
            [(MTDatabaseSqlite3 *)self.databaseForSelects bindStatement:&statement withBindings:dataBinding];
        }
        
        if (success && sqlite3_step(statement) == SQLITE_ROW) {
            result = [self objectOfUnknownType:statement forColumnNumber:0];
        }
        NSAssert(success, @"%s", sqlite3_errmsg(databaseHandle));
        
        sqlite3_finalize(statement);
        sqlite3_free(queryString);
    }
    
    return result;
}

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

- (NSUInteger)columnIndexForKey:(NSString *)key {
    return [self.columnKeys indexOfObject:key];
}

- (id)objectOfUnknownType:(sqlite3_stmt *)statement forColumnNumber:(int)columnIndex {
    //MTDataType aggregateResultType = mad_sqlite3_datatype_for_sqlite3_type(sqlite3_column_type(statement, columnIndex));
    return [MTDatabaseSqlite3 valueForStatement:statement columnNumber:columnIndex];
}

- (id)currentObject:(sqlite3_stmt *)statement {
    NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:[self.columns count]];
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
    [self setBulkInsertLoop:YES];
    
    [self reopenDbConnection];
    
    [self setSortDescriptorsSet:NO];
    [self createIndex];
    
    [[self databaseForInserts] beginBulkInsert];

}

/*! Call right after bulk insert of data. */

- (void)endBulkInsert {
    [self setBulkInsertLoop:NO];
    [(MTDatabaseSqlite3 *)[self databaseForInserts] endBulkInsert];
}

#pragma mark - Unused

- (NSEnumerator *)enumeratorForRowIds:(NSArray *)cacheIds {  //Note, software currently usues NSArray for row ids
    
    NSNumber *keyRowIds = @(MTQuerySelectRowIds);
    NSNumber *keyTableN = @(MTQuerySelectTableName);
    NSNumber *keySortDe = @(MTQuerySelectSortDescriptors);
    NSNumber *keyColumn = @(MTQuerySelectColumns);
    
    NSString *tableName = [NSString stringWithString:[self tableName]];
    NSArray *sortDescs = [NSArray arrayWithArray:[self sortDescriptors]];
    NSDictionary *columns = [NSDictionary dictionaryWithDictionary:self.columns];
    
    NSDictionary *options = @{
                              keyRowIds : cacheIds,
                              keyTableN : tableName,
                              keySortDe : sortDescs,
                              keyColumn : columns
                              };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectRowIds object:options];
    
    NSArray *columnKeys = [NSArray arrayWithArray:self.columnKeys];
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
