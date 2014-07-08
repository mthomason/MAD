//
//  MTArrayCached.m
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

//#ifndef MAD_MTArrayCached_DEBUG
//#define MAD_MTArrayCached_DEBUG
//#endif

#import "MTArrayCached.h"
#import "NSFileManager+Common.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseCache.h"
#import "MTDataColumn.h"
#import "MTQuery.h"
#import "libSqlite3_8.h"
#import "MTLog.h"

NSString * const MTArrayCachedTableName = @"ac";
NSString * const MTArrayCachedColumnKey = @"ci";
NSString * const MTArrayCachedColumnValue = @"ck";
NSString * const MTArrayCachedExtension = @"madac";

NSString * const MTArrayCachedQueryInsert = @"INSERT INTO %@ (%@, %@) VALUES (?1, ?2);";
NSString * const MTArrayCachedQuerySelect = @"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1  OFFSET 0;";
NSString * const MTArrayCachedQueryLastId = @"SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT 1 OFFSET 0;";
NSString * const MTArrayCachedQueryEnumer = @"SELECT %@ FROM %@ ORDER BY %@;";

@interface MTArrayCached ()

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong) MTDatabaseCache *database;
@property (nonatomic, assign) NSInteger numberOrRows;
@property (nonatomic, assign) sqlite3_stmt *statementInsert;
@property (nonatomic, assign) sqlite3_stmt *statementSelect;
@property (nonatomic, assign) sqlite3_stmt *statementCount;
@property (nonatomic, assign) sqlite3_stmt *statementEnumer;

@property (nonatomic, assign) NSUInteger nextObjectCounter;

@property (nonatomic, strong) NSMutableArray *fastEnumerationObjects;

@end

@implementation MTArrayCached

- (void)dealloc {
    sqlite3_finalize(_statementInsert);
    sqlite3_finalize(_statementSelect);
    sqlite3_close(_database.databaseHandle);
}

- (id)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
        [self setFastEnumerationObjects:fastEnumerationObjects];
        
        NSString *i = [NSString stringWithString:identifier];
        [self setIdentifier:i];
        [self initalizeDatabase];
    }
    return self;
}

- (void)reopenDatabaseAtUrl:(NSURL *)url {
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:url];
    MTDatabaseCache *database = [MTDatabaseCache databaseFactory:databaseConnection];
#ifdef MAD_MTArrayCached_DEBUG
    sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
    [self setDatabase:database];
}

- (void)initalizeDatabase {

    NSURL *url = [self url];
    BOOL createDatabase = [[NSFileManager defaultManager] fileExistsAtPath:[url path]] == NO;
    [self reopenDatabaseAtUrl:[self url]];
    if (createDatabase == NO) {
        createDatabase = [self.database tableExist:MTArrayCachedTableName] == NO;
    }
    if ([self.database tableExist:MTArrayCachedTableName] == NO) {
        MTDataColumn *columnKey = [MTArrayCached columnKey];
        MTDataColumn *columnValue = [MTArrayCached columnValue];
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:[columnKey identifier] createTable:YES unique:NO];
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:[columnValue identifier] createTable:NO unique:NO];
        [self setNumberOrRows:0];
    } else {
        [self setNumberOrRows:[self count]];
    }
    [self prepareStatements];
}

- (void)beginBulkInserts {
    [[self database] beginBulkInsert];
}

- (void)endBulkInserts {
    [[self database] endBulkInsert];
    [self reopenDatabaseAtUrl:[self url]];
    [self prepareStatements];
}

- (BOOL)prepareStatements {
    return [self prepareStatementInsert] && [self prepareStatementSelect] &&
           [self prepareStatementCount] && [self prepareStatementEnum];
}

- (BOOL)prepareStatementEnum {
    NSString *sql = [NSString stringWithFormat:MTArrayCachedQueryEnumer,  MTArrayCachedColumnValue, MTArrayCachedTableName, MTArrayCachedColumnKey];
    _statementEnumer = NULL;
    return sqlite3_prepare_v2([[self database] databaseHandle], [sql UTF8String], -1, &_statementEnumer, NULL) == SQLITE_OK;
}

- (BOOL)prepareStatementInsert {
    NSString *queryString = [NSString stringWithFormat:MTArrayCachedQueryInsert, MTArrayCachedTableName, MTArrayCachedColumnKey, MTArrayCachedColumnValue];
    _statementInsert = NULL;
    return sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementInsert, NULL) == SQLITE_OK;
}

- (BOOL)prepareStatementSelect {
    NSString *queryString = [NSString stringWithFormat:MTArrayCachedQuerySelect, MTArrayCachedColumnValue, MTArrayCachedTableName, MTArrayCachedColumnKey];
    _statementSelect = NULL;
    return sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementSelect, NULL) == SQLITE_OK;
}

- (BOOL)prepareStatementCount {
    NSString *queryString = [NSString stringWithFormat:MTArrayCachedQueryLastId, MTArrayCachedColumnKey, MTArrayCachedTableName, MTArrayCachedColumnKey];
    _statementCount = NULL;
    return sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementCount, NULL) == SQLITE_OK;
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
    NSData *data = nil;
    if ([object conformsToProtocol:@protocol(NSCoding)]) {
        @try {
            data = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
        @catch (NSException *exception) {
            NSValue *v = [NSValue valueWithPointer:(__bridge const void *)(object)];
            data = [NSKeyedArchiver archivedDataWithRootObject:v];
        }
        @finally { }
    } else {
        NSValue *v = [NSValue valueWithPointer:(__bridge const void *)(object)];
        data = [NSKeyedArchiver archivedDataWithRootObject:v];
    }
    sqlite3_bind_int(_statementInsert, 1, (int)self.numberOrRows);
    sqlite3_bind_blob(_statementInsert, 2, [data bytes], (int)[data length], SQLITE_TRANSIENT);
    if (sqlite3_step(_statementInsert) == SQLITE_DONE) {
        sqlite3_reset(_statementInsert);
        self.numberOrRows++;
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [self objectAtIndex:idx];
}

- (id)objectAtIndex:(NSUInteger)index {
    sqlite3_bind_int(_statementSelect, 1, (int)index);
    id result = nil;

    if (sqlite3_step(_statementSelect) == SQLITE_ROW) {
        NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementSelect, 0)
                                             length: sqlite3_column_bytes(_statementSelect, 0)];
        result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
        sqlite3_reset(_statementSelect);
    }
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
    NSMutableDictionary *queryDefinationSelect = [NSMutableDictionary dictionaryWithDictionary:[MTQuery queryDefinationSelect:columnNameIndex
                                                                                                                    tableName:MTArrayCachedTableName
                                                                                                              sortDescriptors:sortdesc]];
    NSNumber *yes = @YES;
    NSNumber *key = @(MTQueryCacheSelectLimitOffsetParamatersDropRowid);
    [queryDefinationSelect setObject:yes forKey:key];
    return [MTQuery queryDefinationSelect:queryDefinationSelect withLimit:1 andOffset:0];
}

- (NSUInteger)count {
    NSUInteger lastRowid = 0;
    if (sqlite3_step(_statementCount) == SQLITE_ROW) {
        lastRowid = sqlite3_column_int(_statementCount, 0);
        sqlite3_reset(_statementCount);
    }
    return lastRowid + 1;
}

- (BOOL)isEmpty {
    return [self numberOrRows] > 0;
}

- (NSArray *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    if ([self isEmpty] == NO) {
        while (sqlite3_step(_statementEnumer) == SQLITE_ROW) {
            NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementEnumer, 0)
                                                 length: sqlite3_column_bytes(_statementEnumer, 0)];
            id result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
            [results addObject:result];
        }
    }
    return results;
}

- (id)nextObject {
    
    int stepResult;
    id result = nil;
    if ([self isEmpty]) {
        stepResult = sqlite3_step(_statementEnumer);
        if (stepResult == SQLITE_ROW) {
            NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementEnumer, 0)
                                                 length: sqlite3_column_bytes(_statementEnumer, 0)];
            result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
        } else if (stepResult == SQLITE_DONE) {
            sqlite3_reset(_statementEnumer);
            result = nil;
        }
    } else {
        sqlite3_reset(_statementEnumer);
    }
    return result;
}

- (void)resetEnumerator {
    sqlite3_reset(_statementEnumer);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len {

    NSUInteger i = 0;
    int stepResult;

    if(state->state == 0) {
        state->state = 1;
        state->mutationsPtr = &state->extra[0];
        sqlite3_reset(_statementEnumer);
    }
    
    if (state->state != 2) {
        //state->mutationsPtr = (unsigned long *)&_statementEnumer;
        state->itemsPtr = stackbuf;
        [[self fastEnumerationObjects] removeAllObjects];
        
        for (i = 0; i<len; i++) {
            @autoreleasepool {
                stepResult = sqlite3_step(_statementEnumer);
                if (stepResult == SQLITE_ROW) {
                    NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementEnumer, 0)
                                                         length: sqlite3_column_bytes(_statementEnumer, 0)];
                    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
                    [[self fastEnumerationObjects] addObject:obj];
                    stackbuf[i] = obj;
                } else if (stepResult == SQLITE_DONE) {
                    sqlite3_reset(_statementEnumer);
                    stackbuf[i] = nil;
                    state->state = 2;
                    break;
                }
            }
        }
    }
    return i;
}

@end
