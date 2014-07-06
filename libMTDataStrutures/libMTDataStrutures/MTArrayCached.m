//
//  MTArrayCached.m
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

//#ifndef MAD_MTArrayCached_DEBUG
//#define MAD_MTArrayCached_DEBUG

#import "MTArrayCached.h"
#import "NSFileManager+Common.h"
#import "MTDatabaseConnection.h"
#import "MTDatabase.h"
#import "MTDataColumn.h"
#import "MTQuery.h"
#import "libSqlite3_8.h"
#import "MTLog.h"

NSString * const MTArrayCachedTableName = @"ac";
NSString * const MTArrayCachedColumnKey = @"ci";
NSString * const MTArrayCachedColumnValue = @"ck";
NSString * const MTArrayCachedExtension = @"madac";


@interface MTArrayCached ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) MTDatabase *database;
@property (nonatomic, assign) NSInteger numberOrRows;

@end

@implementation MTArrayCached

- (void)dealloc {

}

- (id)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        NSString *i = [NSString stringWithString:identifier];
        [self setIdentifier:i];

        [self initalizeDatabase];
    }
    return self;
}

- (void)initalizeDatabase {

    NSURL *url = [self url];
    BOOL createDatabase = [[NSFileManager defaultManager] fileExistsAtPath:[url path]] == NO;
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:url];
    MTDatabase *database = [MTDatabase databaseFactory:databaseConnection];
    [self setDatabase:database];
#ifdef MAD_MTArrayCached_DEBUG
    sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
    if (createDatabase == NO) {
        createDatabase = [database tableExist:MTArrayCachedTableName] == NO;
    }
    if (createDatabase) {
        MTDataColumn *columnKey = [MTArrayCached columnKey];
        MTDataColumn *columnValue = [MTArrayCached columnValue];
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:[columnKey identifier] createTable:YES unique:NO];
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:[columnValue identifier] createTable:NO unique:NO];
        [self setNumberOrRows:0];
    } else {
        [self setNumberOrRows:[self count]];
    }
}

#ifdef MAD_MTArrayCached_DEBUG
void sqliteCallbackFunc(void *foo, const char* statement);
void sqliteCallbackFunc(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif


+ (NSURL *)directoryCachedArray {
    NSURL *cachedArrayDirectories = [[NSFileManager cacheDirectory] URLByAppendingPathComponent:MTArrayCachedTableName isDirectory:YES];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist, isDirectory;
    exist = [fm fileExistsAtPath:[cachedArrayDirectories path] isDirectory:&isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES attributes:@{} error:&error];
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

+ (NSURL *)urlForIdentifier:(NSString *)identifer {
    NSURL *cachedArrayDirectories = [self directoryCachedArray];
    NSString *filename = [identifer stringByAppendingPathExtension:@"madac"];
    return [cachedArrayDirectories URLByAppendingPathComponent:filename isDirectory:NO];
}

- (NSURL *)url {
    return [MTArrayCached urlForIdentifier:[self identifier]];
}

+ (MTDataColumn *)columnKey {
    MTDataColumn *column = [[MTDataColumn alloc] initWithIdentifier:MTArrayCachedColumnKey];
    NSNumber *columnType = @(MTDataTypeInteger);
    [column setColumnType:columnType];
    [column setPrimaryKey:YES];
    [column setNotNull:YES];
    [column setAutoIncrement:NO];
    return column;
}

+ (MTDataColumn *)columnValue {
    MTDataColumn *column = [[MTDataColumn alloc] initWithIdentifier:MTArrayCachedColumnValue];
    NSNumber *columnType = @(MTDataTypeBlob);
    [column setColumnType:columnType];
    [column setPrimaryKey:NO];
    [column setNotNull:YES];
    [column setAutoIncrement:NO];
    return column;
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
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddColumn object:queryDefination];
    
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self database] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)addObject:(id)object {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSNumber *index = @(self.numberOrRows);
    NSArray *row = @[index, data];
    
    NSNumber *keyKeys = @(MTQueryCacheAddRowColumnKeys);
    NSNumber *keyColumns = @(MTQueryCacheAddRowColumns);
    NSNumber *keyData = @(MTQueryCacheAddRowData);
    NSNumber *keyTableName = @(MTQueryCacheAddRowTableName);
    MTDataColumn *ck = [MTArrayCached columnKey];
    MTDataColumn *cv = [MTArrayCached columnValue];
    NSArray *columnKeys = @[MTArrayCachedColumnKey, MTArrayCachedColumnValue];
    NSDictionary *columns = @{MTArrayCachedColumnKey : ck, MTArrayCachedColumnValue : cv};
    NSDictionary *queryDefination = @{
                                      keyKeys : columnKeys,
                                      keyColumns : columns,
                                      keyData : row,
                                      keyTableName : MTArrayCachedTableName
                                      };

    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddRow object:queryDefination];
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self database] completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    self.numberOrRows++;
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (id)objectAtIndex:(NSUInteger)index {
    NSNumber *indexObj = [NSNumber numberWithInteger:index];
    NSDictionary *whereStatement = @{MTQueryKeyPredicateColumn : MTArrayCachedColumnKey,
                                     MTQueryKeyPredicateValue : indexObj};
    NSArray *predicates = @[whereStatement];
    NSArray *columnNameIndex = @[MTArrayCachedColumnValue];
    NSArray *sortdesc = @[];
    NSDictionary *queryDefinationSelect = [MTQuery queryDefinationSelect:columnNameIndex tableName:MTArrayCachedTableName sortDescriptors:sortdesc];
    NSDictionary *queryDef = [MTQuery queryDefinationSelect:queryDefinationSelect withLimit:1 andOffset:0 dropRowid:YES];
    NSMutableDictionary *queryDefWithPredicates = [NSMutableDictionary dictionaryWithDictionary:queryDef];
    NSNumber *key = @(MTQueryCacheSelectLimitOffsetParamatersWhere);
    [queryDefWithPredicates setObject:predicates forKey:key];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefWithPredicates];

    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    BOOL success = sqlite3_prepare_v2([[self database] databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
    NSAssert(success, @"%s", sqlite3_errmsg([[self database] databaseHandle]));

    id result = nil;
    
    if (success) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(statement, 0)
                                         length: sqlite3_column_bytes(statement, 0)];
            result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
        }
    }
    
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    
    return result;
}

- (void)removeAllObjects {
    self.numberOrRows = 0;
    NSDictionary *queryDefination = [MTQuery queryDefinationCacheDeleteAllFromTable:MTArrayCachedTableName];
    MTQuery *queryDeleteAllFromTable = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheDeleteAllFromTable
                                                                   object: queryDefination];
    dispatch_semaphore_t semaphoreDeleteAll = dispatch_semaphore_create(0);
    [queryDeleteAllFromTable performQueryWithDatabase:[self database] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(semaphoreDeleteAll);
    }];
    dispatch_semaphore_wait(semaphoreDeleteAll, DISPATCH_TIME_FOREVER);
}

- (NSDictionary *)queryDefinatinSelect {
    NSArray *columnNameIndex = @[MTArrayCachedColumnKey];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey:MTArrayCachedColumnKey
                                                            ascending:NO
                                                             selector:@selector(compare:)];
    NSArray *sortdesc = @[sortn];
    return [MTQuery queryDefinationSelect:columnNameIndex tableName:MTArrayCachedTableName sortDescriptors:sortdesc];
}

- (NSDictionary *)queryDefinationLastObject {
    NSArray *columnNameIndex = @[MTArrayCachedColumnKey];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey:MTArrayCachedColumnKey
                                                            ascending:NO
                                                             selector:@selector(compare:)];
    NSArray *sortdesc = @[sortn];
    NSMutableDictionary *queryDefinationSelect = [NSMutableDictionary dictionaryWithDictionary:[MTQuery queryDefinationSelect:columnNameIndex tableName:MTArrayCachedTableName sortDescriptors:sortdesc]];
    NSNumber *yes = @YES;
    NSNumber *key = @(MTQueryCacheSelectLimitOffsetParamatersDropRowid);
    [queryDefinationSelect setObject:yes forKey:key];
    return [MTQuery queryDefinationSelect:queryDefinationSelect withLimit:1 andOffset:0];
}

- (NSUInteger)count {
    NSUInteger count = 0;
    NSDictionary *queryDefinationSelectLastIndex = [NSDictionary dictionaryWithDictionary:[self queryDefinationLastObject]];
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectLimitOffset object:queryDefinationSelectLastIndex];
    
    sqlite3_stmt *statement = NULL;
    NSError *error = nil;
    NSString *sql = [query getSqlWithError:&error];
    NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    const char *sqlc = [sql UTF8String];
    char *queryString = sqlite3_mprintf((char *) sqlc);
    BOOL success = sqlite3_prepare_v2([[self database] databaseHandle], queryString, -1, &statement, NULL) == SQLITE_OK;
    NSAssert(success, @"%s", sqlite3_errmsg([[self database] databaseHandle]));
    if (success) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            count = sqlite3_column_int(statement, 0);
        }
    }
    sqlite3_finalize(statement);
    sqlite3_free(queryString);
    return count;
}

@end
