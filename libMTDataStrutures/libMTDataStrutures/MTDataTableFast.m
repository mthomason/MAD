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
#import "MTDatabaseField.h"
#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseConnection.h"
#import "MTDatabase.h"
#import "libSqlite3_8.h"
#import "MTLog.h"
#import "MTDatabaseSqlite3.h"

@interface MTDataTableFast ()

@property (nonatomic, strong) MTDatabase *databaseForInserts;
@property (nonatomic, strong) MTDatabase *databaseForSelects;

@property (nonatomic, strong) NSURL *urlFastCache;
@property (nonatomic, assign, readwrite) NSUInteger tag;
@property (nonatomic, assign) BOOL bulkInsertLoop;
@property (nonatomic, assign) BOOL sortDescriptorsSet;

@end

@implementation MTDataTableFast

- (id)plist {
    
    NSDictionary *superPlist = [super plist];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:superPlist];
    
    NSString *keyUrlFastCache = [MTDataTableFast keyUrlFastCache];
    NSString *keyTag = [MTDataTableFast keyTag];
    NSString *keyBulkInsertLoop = [MTDataTableFast keyBulkInsertLoop];

    plist[keyUrlFastCache] = [[self urlFastCache] absoluteString];
    plist[keyTag] = @([self tag]);
    plist[keyBulkInsertLoop] = @([self bulkInsertLoop]);

    return plist;
}

-(void)loadWithPlist:(NSDictionary *)plist {
    [super loadWithPlist:plist];
    
    NSString *absoluteString = [plist objectForKey: [MTDataTableFast keyUrlFastCache]];
    NSURL *url = [NSURL URLWithString:absoluteString];
    [self setUrlFastCache: url];
    
    NSNumber *tagWrapper = [plist objectForKey: [MTDataTableFast keyTag]];

     NSUInteger tag = [tagWrapper integerValue];
    [self setTag:tag];
    
    NSNumber *bulkInsertLoopWrapper = [plist objectForKey: [MTDataTableFast keyBulkInsertLoop]];
    BOOL bulkInsertLoop = [bulkInsertLoopWrapper boolValue];
    [self setBulkInsertLoop:bulkInsertLoop];
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

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];

    [encoder encodeObject:  [_urlFastCache absoluteString]      forKey: [MTDataTableFast keyUrlFastCache]];
    [encoder encodeInteger: _tag                                forKey: [MTDataTableFast keyTag]];
    [encoder encodeBool: _bulkInsertLoop                        forKey: [MTDataTableFast keyBulkInsertLoop]];
    [encoder encodeBool:_sortDescriptorsSet forKey:[MTDataTableFast keySortDescriptorsSet]];

}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if(self) {
        
        NSString *absoluteString = [decoder decodeObjectForKey: [MTDataTableFast keyUrlFastCache]];
        NSURL *url = [NSURL URLWithString:absoluteString];
        [self setUrlFastCache: url];
        
        NSUInteger tag = [decoder decodeIntegerForKey: [MTDataTableFast keyTag]];
        [self setTag:tag];

        BOOL bulkInsertLoop = [decoder decodeBoolForKey: [MTDataTableFast keyBulkInsertLoop]];;
        [self setBulkInsertLoop:bulkInsertLoop];

        BOOL sortDescriptorsSet = [decoder decodeBoolForKey: [MTDataTableFast keySortDescriptorsSet]];;
        [self setSortDescriptorsSet:sortDescriptorsSet];

        
        [self reopenDbConnection];
    }
    return self;
}

+ (NSString *)keyColumns {
    SEL selColumns = @selector(columns);
    return NSStringFromSelector(selColumns);
}
+ (NSString *)keySortDescriptorsSet {
    SEL selector = @selector(sortDescriptorsSet);
    return NSStringFromSelector(selector);
}
- (id)initWithId:(NSUInteger)objectId {
    self = [super initWithId:objectId];
    if (self) {
        [self setBulkInsertLoop:NO];
        [self setTag:objectId];
        [self setObjectId:objectId];
        [self setSortDescriptorsSet:NO];
        [self reopenDbConnection];
    }
    return self;
}

- (void)setObjectId:(NSUInteger)objectId {
    [super setObjectId:objectId];
    NSString *filename = [NSFileManager filenameId:objectId extention:@"maddb"];
    NSURL *cacheDirectory = [NSFileManager cacheDirectory];
    NSURL *fileUrl = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
    [self setUrlFastCache:fileUrl];
}

- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (void)reopenDbConnection {
    MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:[self urlFastCache]];
    MTDatabase *database = [MTDatabase databaseFactory:connection];
    [self setDatabaseForInserts:database];
    MTDatabase *database2 = [MTDatabase databaseFactory:connection];
    [self setDatabaseForSelects:database2];
}

- (NSString *)tableName {
    return [NSString stringWithFormat:@"t%lu", (unsigned long)[self tag]];
}

- (void)addColumn:(MTDataColumn *)column {
    
    NSUInteger columnId = [[self columnKeys] count];
    NSString *columnName = [NSString stringWithFormat:@"c%lu", (unsigned long)columnId];
    
    [[self columns] setObject:column forKey:columnName];
    [[self columnKeys] addObject:columnName];
    
    NSNumber *createTable = @(columnId == 0);
    NSDictionary *queryDefination = @{
                                      @(MTQueryCacheAddColumnDataColumn) : column,
                                      @(MTQueryCacheAddColumnTableName) : [self tableName],
                                      @(MTQueryCacheAddColumnColumnName) : columnName,
                                      @(MTQueryCacheAddColumnCreateTable) : createTable
                                      };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddColumn object:queryDefination];
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        if (!success) NSLog(@"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)addRow:(NSArray *)row {
    
    NSDictionary *queryDefination = @{
                                      @(MTQueryCacheAddRowColumnKeys)   : [self columnKeys],
                                      @(MTQueryCacheAddRowColumns)      : [self columns],
                                      @(MTQueryCacheAddRowData)         : row,
                                      @(MTQueryCacheAddRowTableName)    : [self tableName]
                                      };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddRow object:queryDefination];
    self.rowCounter++;
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)addRowWithDataForFieldKeys:(NSDictionary *)row {
    NSMutableArray *rowData = [[NSMutableArray alloc] init];
    for (id columnDefKey in [self columnKeys]) {
        MTDataColumn *columnDef = [[self columns] objectForKey:columnDefKey];
        NSString *fieldKey = [columnDef fieldName];
        id obj = row[fieldKey];
        if (obj == nil) obj = [NSNull null];
        [rowData addObject:obj];
    }
    [self addRow:rowData];
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {
    
    if ([[self columnKeys] count] > 0 && [[self columns] count] > 0) {
        
        if ([sortDescriptors count] > 0 && self.sortDescriptorsSet == NO) {
            NSMutableArray *newSorts = [[NSMutableArray alloc] initWithCapacity:[sortDescriptors count]];
            
            for (NSSortDescriptor *sort in sortDescriptors) {
                for (NSString *columnKey in [[self columns] keyEnumerator]) {
                    MTDataColumn *column = [[self columns] objectForKey:columnKey];
                    if ([[column fieldName] isEqualToString:[sort key]]) {
                        NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey:columnKey
                                                                                ascending:[sort ascending]
                                                                                 selector:[MTDatabaseField selectorForSorting:[[column columnType] integerValue]]];
                        [newSorts addObject:sortn];
                        break;
                    }
                }
                if ([newSorts count] == [sortDescriptors count]) {
                    [self setSortDescriptorsSet:YES];
                    [self setSortDescriptors:newSorts];
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
    
    dispatch_semaphore_t semaphoreRemoveAll = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [self reopenDbConnection];
        [self dropIndex];
        [self dropTable];
        [self vacuumCacheDb];
        dispatch_semaphore_signal(semaphoreRemoveAll);
    });
    dispatch_semaphore_wait(semaphoreRemoveAll, DISPATCH_TIME_FOREVER);

    [[self columnKeys] removeAllObjects];
    [[self columns] removeAllObjects];
    [self setRowCounter:0];
    
}

- (void)createIndex {
    
    [self sortUsingDescriptors:[self sortDescriptors]];
    
    NSDictionary *parametersCreateIndex = @{
                                            @(MTQueryCacheIndexCreateIndexName)         : @"i1",
                                            @(MTQueryCacheIndexCreateTableName)         : [self tableName],
                                            @(MTQueryCacheIndexCreateSortDescriptors)   : [self sortDescriptors]
                                            };
    MTQuery *queryCreateIndex = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheIndexCreateParameters
                                                            object: parametersCreateIndex];
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [queryCreateIndex performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)dropIndex {
    NSDictionary *parameters = @{
                                 @(MTQueryCacheIndexDropIndexName) : @"i1",
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
    NSNumber *tableNameKey = @(MTQueryCacheDropTableTableName);
    NSDictionary *queryDefination = @{
                                      tableNameKey : [self tableName]
                                      };
    
    MTQuery *queryDropTable = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheDropTable object:queryDefination];

    dispatch_semaphore_t semaphoreDropTable = dispatch_semaphore_create(0);
    [queryDropTable performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(semaphoreDropTable);
    }];
    dispatch_semaphore_wait(semaphoreDropTable, DISPATCH_TIME_FOREVER);
    
}

- (void)deleteAll {
    NSNumber *tableNameKey = @(MTQueryCacheDeleteAllFromTableTableName);
    NSDictionary *queryDefination = @{
                                      tableNameKey : [self tableName]
                                      };
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
    NSString *key = [[self columnKeys] objectAtIndex:0];
    MTDataColumn *columnMetaData = [self columns][key];
    NSString *fieldName = [columnMetaData fieldName];
    return [objForRow objectForKey:fieldName];
}

- (NSDictionary *)objectAtRow:(NSInteger)row {
    return [[self objectAtRow:row limit:1] firstObject];
}

- (NSDictionary *)queryDefinationSelect {
    return  @{
              @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys) : [self columnKeys],
              @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
              @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : [self sortDescriptors],
              
              };
}

- (NSDictionary *)queryDefinationSelectWithLimit:(NSInteger)limit andOffset:(NSInteger)offset {
    NSMutableDictionary *queryDefination = [NSMutableDictionary dictionaryWithDictionary:[self queryDefinationSelect]];
    [queryDefination setObject:@(limit) forKey:@(MTQueryCacheSelectLimitOffsetParamatersLimit)];
    [queryDefination setObject:@(offset) forKey:@(MTQueryCacheSelectLimitOffsetParamatersOffset)];
    return  queryDefination;
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    NSDictionary *options = @{
                              @(MTQuerySelectRowId) : cacheId,
                              @(MTQuerySelectTableName) : [self tableName],
                                  };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectRowId object:options];
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    BOOL success = sqlite3_prepare_v2([[self databaseForSelects] databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
    NSDictionary *result = nil;
    if (success) {
        success = sqlite3_step(statement) == SQLITE_ROW;
        result = [self currentObject:statement];
    } else {
        const char *errorMessage = sqlite3_errmsg([[self databaseForSelects] databaseHandle]);
        NSString *message = [NSString stringWithUTF8String: errorMessage];
        MTLog(@"%@", message);
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return result;
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
        if (success) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                @autoreleasepool {
                    NSDictionary *currentObject = [self currentObject:statement];
                    [results addObject:currentObject];
                }
            }
        } else {
            const char *errorMessage = sqlite3_errmsg([[self databaseForSelects] databaseHandle]);
            NSString *message = [NSString stringWithUTF8String: errorMessage];
            MTLog(@"%@", message);
        }
        
        sqlite3_finalize(statement);
        sqlite3_free(queryString);
    }
    return results;
}

- (NSEnumerator *)columnsEnumerator {
    // FIXME: Implement this.
    return [[self columns] keyEnumerator];
}

- (NSEnumerator *)objectEnumerator {
    NSEnumerator *objectEnumerator = nil;
    if ([[self columns] count] > 0) {
        NSDictionary *queryDefination = [self queryDefinationSelect];
        MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefination];

        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:[self urlFastCache]];
        objectEnumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection:databaseConnection
                                                                                       columns:[self columns]
                                                                                    columnKeys:[self columnKeys]
                                                                                           query:query];
    }
    return objectEnumerator;
}

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys {
    NSAssert([keys count] == groupLevel, @"Need a key for each previous group.");
    NSEnumerator *enumerator = nil;
    
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    for (NSString *key in keys) {
        NSSortDescriptor *sortDescriptor = [[self sortDescriptors] objectAtIndex:0];
        NSDictionary *whereStatement = @{@"col" : [sortDescriptor key], @"val" : key };
        [whereClause addObject:whereStatement];
    }

    NSDictionary *querySelect = @{
                                  @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys) : [self columnKeys],
                                  @(MTQueryCacheSelectLimitOffsetParamatersTableNames) : [self tableName],
                                  @(MTQueryCacheSelectLimitOffsetParamatersSortDesc) : [self sortDescriptors],
                                  @(MTQueryCacheSelectLimitOffsetParamatersWhere) : whereClause,
                                  };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object: querySelect];
    
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: [self urlFastCache]];
    enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                             columns: [self columns]
                                                                          columnKeys: [self columnKeys]
                                                                               query: query];
    
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
    return  [[self columnKeys] count];
}

- (NSUInteger)numberOfRows {
    return [self rowCounter];
}

- (id)currentObject:(sqlite3_stmt *)statement {
    NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:[[self columns] count]];
    int columnCounter = 0;
    for (id key in [self columnKeys]) {
        MTDataColumn *dataColumn = [self columns][key];
        id columnValue;
        switch ([[dataColumn columnType] integerValue]) {
            case MTDataTypeLong:
            case MTDataTypeLongLong:
            case MTDataTypeInteger:
                columnValue = [NSNumber numberWithLongLong:sqlite3_column_int64(statement, columnCounter)];
                break;
            case MTDataTypeBlob:
                columnValue = [NSData dataWithBytes: sqlite3_column_blob(statement, columnCounter)
                                             length: sqlite3_column_bytes(statement, columnCounter)];
                break;
            case MTDataTypeFloat:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(statement, columnCounter)];
                break;
            case MTDataTypeDouble:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(statement, columnCounter)];
                break;
            case MTDataTypeDecimal:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(statement, columnCounter)];
                break;
            case MTDataTypeString: {
                const unsigned char *text = sqlite3_column_text(statement, columnCounter);
                if (text == NULL) {
                    columnValue = [NSNull null];
                } else {
                    columnValue = [NSString stringWithUTF8String:(const char *) text];
                }
                break;
            }
            default: {
                NSAssert(false, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3");
                if (sqlite3_column_type(statement, columnCounter) == SQLITE_TEXT) {
                    const unsigned char *text = sqlite3_column_text(statement, columnCounter);
                    if (text == NULL) {
                        columnValue = [NSNull null];
                    } else {
                        columnValue = [NSString stringWithUTF8String:(const char *) text];
                    }
                }
                break;
            }
        }
        if (columnValue != nil) {
            [currentObject setValue:columnValue forKey:[dataColumn identifier]];
        }
        columnCounter++;
    }
    return currentObject;
}

- (void)beginBulkInsert {
    [self setBulkInsertLoop:YES];
    
    [self reopenDbConnection];

    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeOff object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeOverride object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [queryJournalMode performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);
    
    [self setSortDescriptorsSet:NO];
    [self createIndex];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheBeginTransaction object:@{}];
    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);
}

- (void)endBulkInsert {
    [self setBulkInsertLoop:NO];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheEndTransaction object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeDefault object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeDefault object:@{}];
    [queryJournalMode performQueryWithDatabase:[self databaseForInserts] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);

    [[self databaseForInserts] cleanupBulkInsert];
}

@end
