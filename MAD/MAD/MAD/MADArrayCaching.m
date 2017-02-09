//
//  MTArrayCached.m
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADArrayCaching.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSData.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSKeyedArchiver.h>

#import <MADSqlite3/sqlite3.h>

#import <MADDataStructures/MADIndex.h>

#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADQueryCacheSelectLimitOffsetParamaters.h>

#import "MADDatabaseConnection.h"
#import "MTQueryCacheAddColumn.h"
#import "MTDatabaseSqlite3.h"

static NSString * const MTArrayCachedTableName = @"ac";
static NSString * const MTArrayCachedColumnKey = @"ci";
static NSString * const MTArrayCachedColumnValue = @"ck";
static NSString * const MTArrayCachedExtension = @"madac";

#ifdef MAD_MTArrayCached_DEBUG
void sqliteCallbackFunc(void *foo, const char* statement);
void sqliteCallbackFunc(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif

@interface MADArrayCaching ()

    @property (nonatomic, strong, readwrite) MTDatabaseSqlite3 *database;

    @property (nonatomic, copy, readwrite) NSString *identifier;
    @property (nonatomic, copy, readwrite) dispatch_queue_t archivingQueue;
    @property (nonatomic, copy, readwrite) dispatch_queue_t unarchiveQueue;

    @property (nonatomic, strong, readwrite) MADIndex *lastObjectSelected;

    @property (nonatomic, copy, readonly) NSURL *url;

@end

@interface MADArrayCachingEnumerator : NSEnumerator
    <NSFastEnumeration>

    - (instancetype)initWithURL:(NSURL *)url;
    @property (nonatomic, retain) NSURL *url;

@end

@implementation MADArrayCaching {
    int _numberOfRows;
    NSURL *_url;
    sqlite3_stmt *_statementInsert;
    sqlite3_stmt *_statementSelect;
    sqlite3_stmt *_statementCount;
}

@dynamic url;

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    _lastObjectSelected = nil;
    if (_statementInsert != NULL) {
        sqlite3_finalize(_statementInsert);
        sqlite3_finalize(_statementSelect);
        sqlite3_finalize(_statementCount);
        _statementCount = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;
    }
    //sqlite3_close_v2(_database.databaseHandle);
}

- (void)finalizeDatabase {
    sqlite3_finalize(_statementInsert);
    sqlite3_finalize(_statementSelect);
    sqlite3_finalize(_statementCount);
    _statementCount = NULL;
    _statementInsert = NULL;
    _statementSelect = NULL;
    //sqlite3_close_v2(_database.databaseHandle);
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                    cachedDelegate:(id <MADCacheProtocol>)cachedDelegate {
    if (self = [super init]) {
        
        NSAssert(cachedDelegate != nil, @"We need delegate to get cache location.");

        _archivingQueue = dispatch_queue_create("MADArrayCachingQueue", DISPATCH_QUEUE_SERIAL);
        _unarchiveQueue = dispatch_queue_create("MADArrayCachingQueueReader", DISPATCH_QUEUE_SERIAL);
        _statementCount = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;
        
        self.identifier = identifier.copy;
        self.cachedDelegate = cachedDelegate;
    }
    return self;
}

- (void)reopenDatabaseAtUrl:(NSURL *)url {
    MADDatabaseConnection *databaseConnection;
    MTDatabaseSqlite3 *database;
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl:url];
    database = [MTDatabaseSqlite3 newDatabaseWithConnection:databaseConnection];
    
#ifdef MAD_MTArrayCached_DEBUG
    sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
    
    self.database = database;
}

- (void)initializeDatabase {
    
    NSURL *url = [self url];
    [self reopenDatabaseAtUrl:url];
    if (![self.database tableExist:MTArrayCachedTableName]) {

        MADDataColumn *columnKey;
        columnKey = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnKey];
        columnKey.type = MADDataTypeInteger;
        columnKey.primaryKey = YES;
        columnKey.notNull = YES;
        columnKey.autoIncrement = NO;
        
        [self addColumn: columnKey toTable:MTArrayCachedTableName
             columnName: columnKey.identifier
            createTable: YES
                 unique: NO];

        MADDataColumn *columnValue;
        columnValue = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnValue];
        columnValue.type = MADDataTypeBlob;
        columnValue.primaryKey = NO;
        columnValue.notNull = YES;
        columnValue.autoIncrement = NO;

        [self addColumn: columnValue
                toTable: MTArrayCachedTableName
             columnName: columnValue.identifier
            createTable: NO
                 unique: NO];

        _numberOfRows = 0;
    }
    [self prepareStatements];
    _numberOfRows = (int)self.count;
}

- (void)beginBulkInserts {
    [self.database beginBulkInsert];
}

- (void)endBulkInserts {
    [self.database endBulkInsert];
    NSURL *url = [self url];
    [self reopenDatabaseAtUrl: url];
    [self prepareStatements];
}

- (BOOL)prepareStatements {
    return [self prepareStatementInsert] &&
        [self prepareStatementSelect] &&
        [self prepareStatementCount];
}

- (BOOL)prepareStatementInsert {
    NSString *queryString = [[NSString alloc] initWithFormat: @"INSERT INTO %@ (%@, %@) VALUES (?1, ?2);",
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey,
                                                              MTArrayCachedColumnValue];
    if (_statementInsert != NULL) {
        sqlite3_finalize(_statementInsert);
        _statementInsert = NULL;
    }
    __block BOOL success = YES;
    if (_statementInsert == NULL) {
        MTDatabaseSqlite3 *database = self.database;
        __block sqlite3_stmt *stmt_insert = _statementInsert;
        dispatch_sync(self.archivingQueue, ^{
            @autoreleasepool {
                
                int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1,
                                                        &stmt_insert, NULL);
                NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
                success = prepare_result == SQLITE_OK;
            }
        });
        _statementInsert = stmt_insert;
    }
    return success;
}

- (BOOL)prepareStatementSelect {
    NSString *queryString = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1  OFFSET 0;",
                                                              MTArrayCachedColumnValue,
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey];
    if (_statementSelect != NULL) {
        sqlite3_finalize(_statementSelect);
        _statementSelect = NULL;
    }
    BOOL success = YES;
    if (_statementSelect == NULL) {
        MTDatabaseSqlite3 *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1,
                                     &_statementSelect, NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;

}

- (BOOL)prepareStatementCount {
    NSString *queryString = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT 1 OFFSET 0;",
                                                              MTArrayCachedColumnKey,
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey];
    if (_statementCount != NULL) {
        sqlite3_finalize(_statementCount);
        _statementCount = NULL;
    }
    BOOL success = YES;
    if (_statementCount == NULL) {
        MTDatabaseSqlite3 *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String,
                                     -1, &_statementCount, NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;
}

- (NSURL *)url {
    if (_url == nil) {
        NSURL *cachedArrayDirectories = [self.cachedDelegate cachedFilesDirectory].copy;
        NSString *filename = [self.identifier stringByAppendingPathExtension:@"madac"];
        _url = [cachedArrayDirectories URLByAppendingPathComponent:filename isDirectory:NO];
    }
    return _url;
}

- (void)addColumn:(MADDataColumn *)column
          toTable:(NSString *)table
       columnName:(NSString *)columnName
      createTable:(BOOL)create
           unique:(BOOL)unique {
    
    NSString *columnAffinity = [MADSqlite3NativeType newSqlite3NativeType:column.type];
    MTQueryCacheAddColumn *queryCacheAddColumn;
    queryCacheAddColumn =
        [[MTQueryCacheAddColumn alloc] initWithTableName: table
                                              columnName: columnName
                                                  column: column
                                             createTable: create
                                        uniqueColumnHack: unique
                                          columnAffinity: columnAffinity];
    BOOL success = NO;
    NSError * __autoreleasing *error = NULL;
    success = [self.database executeQuery:queryCacheAddColumn withError:error];
    NSAssert(success, @"%s at %s", sqlite3_errmsg(_database->_database),
             __PRETTY_FUNCTION__);
}

+ (id)newObjectForData:(NSData *)data {
    NSError * __autoreleasing * error = NULL;
    id plist;
    if (data) {
        plist = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSAssert(error == NULL, @"Error %@ in %s.", *error, __PRETTY_FUNCTION__);
        return plist;
    } else {
        return nil;
    }
}

- (void)addObject:(id _Nonnull)object {
    _lastObjectSelected = nil;
    NSError * __autoreleasing * error = NULL;
    
    if (!object) {
        NSLog(@"Can't be null");
    }
    int numberOfRows = _numberOfRows;
    sqlite3_stmt *statementInsert = _statementInsert;
    id objectToAdd = object;
    dispatch_sync(self.archivingQueue, ^{
        NSData *data;
        data = [NSKeyedArchiver archivedDataWithRootObject:objectToAdd];
        NSAssert(error == NULL, @"%@", *error);
        int bind_result;
        bind_result = sqlite3_bind_int(statementInsert, 1, numberOfRows);
        NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
        bind_result = sqlite3_bind_blob(statementInsert, 2, data.bytes, (int)data.length, SQLITE_STATIC);
        NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
        bind_result = sqlite3_step(statementInsert);
        NSAssert(Sqlite3StepResultOK(bind_result), @"Error: '%s'.", __PRETTY_FUNCTION__);
        if (bind_result == SQLITE_DONE) {
            sqlite3_reset(statementInsert);
            sqlite3_clear_bindings(statementInsert);
        }
    });
    ++_numberOfRows;
}

- (void)writeData:(NSData *)data {
    
    int numberOfRows = _numberOfRows;
    sqlite3_stmt *statementInsert = _statementInsert;
    NSData *dataToWrite = data;
    dispatch_async(self.archivingQueue, ^{
        @autoreleasepool {
            int bind_result;
            bind_result = sqlite3_bind_int(statementInsert, 1, numberOfRows);
            NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
            bind_result = sqlite3_bind_blob(statementInsert, 2, dataToWrite.bytes, (int)dataToWrite.length, SQLITE_STATIC);
            NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
            bind_result = sqlite3_step(statementInsert);
            NSAssert(Sqlite3StepResultOK(bind_result), @"Error: '%s'.", __PRETTY_FUNCTION__);
            if (bind_result == SQLITE_DONE) {
                sqlite3_reset(statementInsert);
                sqlite3_clear_bindings(statementInsert);
                //numberOfRows++;
            }
        }
    });
    _numberOfRows++;// = numberOfRows;
}

- (NSData *)readDataAtIndex:(NSUInteger)index {
    if (self.lastObjectSelected != nil && self.lastObjectSelected.index == index) {
        return self.lastObjectSelected.object;
    }

    __block NSData *result = nil;
    sqlite3_stmt *statementSelect = _statementSelect;
    dispatch_sync(self.unarchiveQueue, ^{
        sqlite3_bind_int(statementSelect, 1, (int)index);
        
        if (sqlite3_step(statementSelect) == SQLITE_ROW) {
            const void *blob = sqlite3_column_blob(statementSelect, 0);
            int bytes = sqlite3_column_bytes(statementSelect, 0);
            result = [[NSData alloc] initWithBytes: blob
                                            length: (NSUInteger)bytes];
            sqlite3_reset(statementSelect);
            sqlite3_clear_bindings(statementSelect);
        }
    });
    
    return result;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index { return [self objectAtIndex: index]; }

- (id)objectAtIndex:(NSUInteger)index {

    //If they are asking for the last one, short circut
    if (self.lastObjectSelected != nil) {
        if (self.lastObjectSelected.index == index) {
            return self.lastObjectSelected.object;
        }
    }

    __block id result = nil;
    sqlite3_stmt *statementSelect = _statementSelect;
    dispatch_sync(self.unarchiveQueue, ^{
        @autoreleasepool {
            sqlite3_bind_int(statementSelect, 1, (int)index);
            
            if (sqlite3_step(statementSelect) == SQLITE_ROW) {
                const void *blob = sqlite3_column_blob(statementSelect, 0);
                int bytes = sqlite3_column_bytes(statementSelect, 0);
                NSData *queryResult = [[NSData alloc] initWithBytes: blob
                                                             length: (NSUInteger)bytes];
                result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
                //id result2 = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
                //NSLog(@"%@-%@", NSStringFromClass([result class]), result);
                //NSLog(@"%@-%@", NSStringFromClass([result2 class]), result2);
                
            }
            sqlite3_clear_bindings(statementSelect);
            sqlite3_reset(statementSelect);
        }
    });
    
    MADIndex *idx = [[MADIndex alloc] initWithIndex:index andObject:result];
    self.lastObjectSelected = idx;

    return result;
}

- (BOOL)removeAllObjects {
    _lastObjectSelected = nil;
    _numberOfRows = 0;
    NSDictionary *queryDefination;
    MTQuery *queryDeleteAllFromTable;
    queryDefination = [MTQuery newQueryDefinitionCacheDeleteAllFromTable: MTArrayCachedTableName];
    queryDeleteAllFromTable = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheDeleteAllFromTable
                                                                   object: queryDefination];
    
    NSError * __autoreleasing *error = NULL;
    return [self.database executeQuery:queryDeleteAllFromTable withError:error];

}

- (MADQueryDefinition *)queryDefinatinSelect {
    NSArray *columnNameIndex = [[NSArray alloc] initWithObjects: MTArrayCachedColumnKey, nil];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey: MTArrayCachedColumnKey
                                                            ascending: NO
                                                             selector: @selector(compare:)];
    NSArray *sortdesc = [[NSArray alloc] initWithObjects: sortn, nil];
    MADQueryDefinition *definition = [MTQuery newQueryDefinitionSelect: columnNameIndex
                                                             tableName: MTArrayCachedTableName
                                                       sortDescriptors: sortdesc];
    return definition;
}

- (MADQueryDefinition *)queryDefinationLastObject {
    NSArray *columnNameIndex = [[NSArray alloc] initWithObjects: MTArrayCachedColumnKey, nil];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey: MTArrayCachedColumnKey
                                                            ascending: NO
                                                             selector: @selector(compare:)];
    NSArray *sortdesc = [[NSArray alloc] initWithObjects: sortn, nil];
    MADQueryDefinition *queryDefinition = [MTQuery newQueryDefinitionSelect: columnNameIndex
                                                                  tableName: MTArrayCachedTableName
                                                            sortDescriptors: sortdesc];
    NSMutableDictionary *queryDefinationSelect = queryDefinition.mutableCopy;
    NSNumber *yes = @YES, *key;
    key = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersDropRowid];

    queryDefinationSelect[key] = yes;
    
    MADQueryDefinition *result = [MTQuery newQueryDefinitionSelect:queryDefinationSelect
                                                         withLimit:1
                                                         andOffset:0];
    return result;
}

- (long long int)count {
    //__block sqlite_int64 lastRowid = 0;
    //sqlite3_stmt *stmt_count = _statementCount;
    
    //int stepResult = sqlite3_step(stmt_count);
    //if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
    //    lastRowid = sqlite3_column_int64(stmt_count, 0) + 1;
    //    sqlite3_reset(stmt_count);
    //}
    return _numberOfRows;
}

- (BOOL)isEmpty { return _numberOfRows > 0; }

@end

@implementation MADArrayCachingEnumerator {
    sqlite3_stmt *_statementEnumer;
}

- (void)dealloc {
    sqlite3_finalize(_statementEnumer);
    _statementEnumer = NULL;
}

- (id)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        NSString *sql = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ ORDER BY %@;",
                         MTArrayCachedColumnValue,
                         MTArrayCachedTableName,
                         MTArrayCachedColumnKey];
        
        MADDatabaseConnection *databaseConnection;
        MTDatabaseSqlite3 *database;
        databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl:url];
        database = [MTDatabaseSqlite3 newDatabaseWithConnection:databaseConnection];
        int prepare_result = sqlite3_prepare_v2(database->_database, sql.UTF8String, -1, &_statementEnumer,
                                                NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
    }
    return self;
}

- (NSArray *)allObjects {
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt_enum = _statementEnumer;
    NSData *queryResult;
    
    while (sqlite3_step(stmt_enum) == SQLITE_ROW) {
        
        const void *blob = sqlite3_column_blob(stmt_enum, 0);
        int bytes = sqlite3_column_bytes(stmt_enum, 0);
        
        queryResult = [[NSData alloc] initWithBytes: blob
                                             length: (NSUInteger)bytes];
        id result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
        [results addObject:result];
    }
    return results;
}

- (id)nextObject {
    __block id result = nil;
    sqlite3_stmt *stmt_enum = _statementEnumer;
    int stepResult;
    stepResult = sqlite3_step(stmt_enum);
    if (stepResult == SQLITE_ROW) {
        NSData *queryResult;
        queryResult = [[NSData alloc] initWithBytes: sqlite3_column_blob(stmt_enum, 0)
                                             length: (NSUInteger)sqlite3_column_bytes(stmt_enum, 0)];
        result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
    }
    sqlite3_reset(stmt_enum);
    return result;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained *)stackbuf
                                    count:(NSUInteger)len {
    
    NSUInteger i = 0;
    int stepResult;
    
    if(state->state == 0) {
        state->state = 1;
        state->mutationsPtr = &state->extra[0];
        sqlite3_reset(_statementEnumer);
    }
    
    if (state->state != 2) {
        state->itemsPtr = stackbuf;
        
        NSData *queryResult;
        
        for (i = 0; i<len; i++) {

            stepResult = sqlite3_step(_statementEnumer);
            if (stepResult == SQLITE_ROW) {
                const void *blob = sqlite3_column_blob(_statementEnumer, 0);
                int bytes = sqlite3_column_bytes(_statementEnumer, 0);

                queryResult = [[NSData alloc] initWithBytes: blob
                                                     length: (NSUInteger)bytes];
                id obj = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
                stackbuf[i] = obj;
                
            } else if (stepResult == SQLITE_DONE) {
                sqlite3_reset(_statementEnumer);
                stackbuf[i] = nil;
                state->state = 2;
                break;
                
            } else {
                sqlite3_reset(_statementEnumer);
                stackbuf[i] = nil;
                state->state = 2;
                break;
                
            }
        }
    }
    return i;
}

@end
