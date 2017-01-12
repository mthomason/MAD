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

#import <MADSqlite3/sqlite3.h>

#import <MADDataStructures/MADIndex.h>

#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADQueryCacheSelectLimitOffsetParamaters.h>

#import "MADDatabaseConnection.h"
#import "MTDatabaseCache.h"
#import "MTQueryCacheAddColumn.h"

static NSString * const MTArrayCachedTableName = @"ac";
static NSString * const MTArrayCachedColumnKey = @"ci";
static NSString * const MTArrayCachedColumnValue = @"ck";
static NSString * const MTArrayCachedExtension = @"madac";

static NSString * const MTArrayCachedQueryInsert = @"INSERT INTO %@ (%@, %@) VALUES (?1, ?2);";
static NSString * const MTArrayCachedQuerySelect = @"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1  OFFSET 0;";
static NSString * const MTArrayCachedQueryLastId = @"SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT 1 OFFSET 0;";
static NSString * const MTArrayCachedQueryEnumer = @"SELECT %@ FROM %@ ORDER BY %@;";

#ifdef MAD_MTArrayCached_DEBUG
void sqliteCallbackFunc(void *foo, const char* statement);
void sqliteCallbackFunc(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif

@interface MADArrayCaching ()

    @property (nonatomic, strong, readwrite) NSString *identifier;
    @property (nonatomic, strong, readwrite) MTDatabaseCache *database;
    @property (nonatomic, strong, readwrite) MADIndex *lastObjectSelected;

@end

@implementation MADArrayCaching {
    
    int _numberOfRows;
    sqlite3_stmt *_statementInsert;
    sqlite3_stmt *_statementSelect;
    sqlite3_stmt *_statementCount;
    sqlite3_stmt *_statementEnumer;
}

static inline BOOL Sqlite3StepResultOK(int result);
static inline BOOL Sqlite3StepResultOK(int result) {
    return result == SQLITE_OK || result == SQLITE_ROW || result == SQLITE_DONE;
}

- (void)dealloc {
    _lastObjectSelected = nil;
    if (_statementInsert != NULL) {
        sqlite3_finalize(_statementInsert);
        sqlite3_finalize(_statementSelect);
        sqlite3_finalize(_statementCount);
        sqlite3_finalize(_statementEnumer);
        _statementCount = NULL;
        _statementEnumer = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;
    }
    //sqlite3_close_v2(_database.databaseHandle);
}

- (void)finalizeDatabase {
    sqlite3_finalize(_statementInsert);
    sqlite3_finalize(_statementSelect);
    sqlite3_finalize(_statementCount);
    sqlite3_finalize(_statementEnumer);
    _statementCount = NULL;
    _statementEnumer = NULL;
    _statementInsert = NULL;
    _statementSelect = NULL;
    //sqlite3_close_v2(_database.databaseHandle);
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                    cachedDelegate:(id <MTCacheProtocol>)cachedDelegate {
    if (self = [super init]) {
        
        NSAssert(cachedDelegate != nil, @"We need delegate to get cache location.");
        
        _statementCount = NULL;
        _statementEnumer = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;
        
        self.identifier = identifier.copy;
        self.cachedDelegate = cachedDelegate;
    }
    return self;
}

- (void)reopenDatabaseAtUrl:(NSURL *)url {
    MADDatabaseConnection *databaseConnection;
    MTDatabaseCache *database;
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUrl:url];
    database = [MTDatabaseCache newDatabaseWithConnection:databaseConnection];
    
#ifdef MAD_MTArrayCached_DEBUG
    sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
    self.database = database;
}

- (void)initializeDatabase {
    
    NSURL *url = [self url];
    NSString *path = url.path.copy;
    BOOL createDatabase = ![[NSFileManager defaultManager] fileExistsAtPath: path];
    [self reopenDatabaseAtUrl:url];
    if (!createDatabase) {
        createDatabase = ![self.database tableExist:MTArrayCachedTableName];
    }
    if (![self.database tableExist:MTArrayCachedTableName]) {

        MADDataColumn *columnKey;
        columnKey = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnKey];
        columnKey.type = MADDataTypeInteger;
        columnKey.primaryKey = YES;
        columnKey.notNull = YES;
        columnKey.autoIncrement = NO;
        
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:columnKey.identifier
            createTable:YES unique:NO];

        MADDataColumn *columnValue;
        columnValue = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnValue];
        columnValue.type = MADDataTypeBlob;
        columnValue.primaryKey = NO;
        columnValue.notNull = YES;
        columnValue.autoIncrement = NO;

        [self addColumn:columnValue toTable:MTArrayCachedTableName
             columnName:columnValue.identifier createTable:NO unique:NO];

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
    return [self prepareStatementInsert] && [self prepareStatementSelect] &&
    [self prepareStatementCount] && [self prepareStatementEnum];
}

- (BOOL)prepareStatementEnum {
    NSString *sql = [[NSString alloc] initWithFormat: MTArrayCachedQueryEnumer,
                                                      MTArrayCachedColumnValue,
                                                      MTArrayCachedTableName,
                                                      MTArrayCachedColumnKey];
    if (_statementEnumer != NULL) {
        sqlite3_finalize(_statementEnumer);
        _statementEnumer = NULL;
    }
    BOOL success = YES;
    if (_statementEnumer == NULL) {
        MTDatabaseCache *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, sql.UTF8String, -1, &_statementEnumer,
                                     NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;
}

- (BOOL)prepareStatementInsert {
    NSString *queryString = [[NSString alloc] initWithFormat: MTArrayCachedQueryInsert,
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey,
                                                              MTArrayCachedColumnValue];
    if (_statementInsert != NULL) {
        sqlite3_finalize(_statementInsert);
        _statementInsert = NULL;
    }
    BOOL success = YES;
    if (_statementInsert == NULL) {
        MTDatabaseCache *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1,
                                     &_statementInsert, NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;
}

- (BOOL)prepareStatementSelect {
    NSString *queryString = [[NSString alloc] initWithFormat: MTArrayCachedQuerySelect,
                                                              MTArrayCachedColumnValue,
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey];
    if (_statementSelect != NULL) {
        sqlite3_finalize(_statementSelect);
        _statementSelect = NULL;
    }
    BOOL success = YES;
    if (_statementSelect == NULL) {
        MTDatabaseCache *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String, -1,
                                     &_statementSelect, NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;

}

- (BOOL)prepareStatementCount {
    NSString *queryString = [[NSString alloc] initWithFormat: MTArrayCachedQueryLastId,
                                                              MTArrayCachedColumnKey,
                                                              MTArrayCachedTableName,
                                                              MTArrayCachedColumnKey];
    if (_statementCount != NULL) {
        sqlite3_finalize(_statementCount);
        _statementCount = NULL;
    }
    BOOL success = YES;
    if (_statementCount == NULL) {
        MTDatabaseCache *database = self.database;
        int prepare_result = sqlite3_prepare_v2(database->_database, queryString.UTF8String,
                                     -1, &_statementCount, NULL);
        NSAssert(prepare_result == SQLITE_OK, @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
        success = prepare_result == SQLITE_OK;
    }
    return success;
}

- (NSURL *)url {
    NSURL *result = nil;
    NSURL *cachedArrayDirectories = [self.cachedDelegate cachedFilesDirectory].copy;
    NSString *filename = [self.identifier stringByAppendingPathExtension:@"madac"];
    result = [cachedArrayDirectories URLByAppendingPathComponent:filename isDirectory:NO];
    return result;
}

- (void)addColumn:(MADDataColumn *)column toTable:(NSString *)table
       columnName:(NSString *)columnName createTable:(BOOL)create unique:(BOOL)unique {
    
    NSString *columnAffinity = [self.database newNativeTypeForDataType:column.type];
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

+ (NSData *)dataForObject:(id _Nonnull)object {
    NSError * __autoreleasing * error = NULL;
    NSData *data;
    data = [NSPropertyListSerialization dataWithPropertyList: object
                                                      format: NSPropertyListBinaryFormat_v1_0
                                                     options: 0
                                                       error: error];
    NSAssert(error == NULL, @"Error %@ in %s.", *error, __PRETTY_FUNCTION__);
    return data;
}

+ (id)newObjectForData:(NSData *)data {
    NSError * __autoreleasing * error = NULL;
    id plist;
    plist = [NSPropertyListSerialization propertyListWithData: data
                                                      options: NSPropertyListImmutable
                                                       format: nil error: error];
    NSAssert(error == NULL, @"Error %@ in %s.", *error, __PRETTY_FUNCTION__);
    return plist;
}

- (void)addObject:(id _Nonnull)object {
    @autoreleasepool {

        _lastObjectSelected = nil;
        NSError * __autoreleasing * error = NULL;
        NSData *data;
        data = [NSPropertyListSerialization dataWithPropertyList: object
                                                          format: NSPropertyListBinaryFormat_v1_0
                                                         options: 0
                                                           error: error];
        NSAssert(error == NULL, @"%@", *error);
        int bind_result;
        bind_result = sqlite3_bind_int(_statementInsert, 1, _numberOfRows);
        NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
        bind_result = sqlite3_bind_blob(_statementInsert, 2, data.bytes, (int)data.length, SQLITE_STATIC);
        NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
        bind_result = sqlite3_step(_statementInsert);
        NSAssert(Sqlite3StepResultOK(bind_result), @"Error: '%s'.", __PRETTY_FUNCTION__);
        if (bind_result == SQLITE_DONE) {
            sqlite3_reset(_statementInsert);
            ++_numberOfRows;
        }
    }
}

- (void)writeData:(NSData *)data {
    int bind_result;
    bind_result = sqlite3_bind_int(_statementInsert, 1, _numberOfRows);
    NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
    bind_result = sqlite3_bind_blob(_statementInsert, 2, data.bytes, (int)data.length, SQLITE_STATIC);
    NSAssert(bind_result == SQLITE_OK, @"Error: '%s'.", __PRETTY_FUNCTION__);
    bind_result = sqlite3_step(_statementInsert);
    NSAssert(Sqlite3StepResultOK(bind_result), @"Error: '%s'.", __PRETTY_FUNCTION__);
    if (bind_result == SQLITE_DONE) {
        sqlite3_reset(_statementInsert);
        ++_numberOfRows;
    }
}

- (NSData *)readDataAtIndex:(NSUInteger)index {

    NSData *result = nil;
    
    if (self.lastObjectSelected != nil) {
        if (self.lastObjectSelected.index == index) {
            return self.lastObjectSelected.object;
        }
    }
    
    sqlite3_bind_int(_statementSelect, 1, (int)index);
    
    if (sqlite3_step(_statementSelect) == SQLITE_ROW) {
        const void *blob = sqlite3_column_blob(_statementSelect, 0);
        int bytes = sqlite3_column_bytes(_statementSelect, 0);
        result = [[NSData alloc] initWithBytes: blob
                                        length: (NSUInteger)bytes];
        sqlite3_reset(_statementSelect);
    }
    return result;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index { return [self objectAtIndex: index]; }

- (id)objectAtIndex:(NSUInteger)index {
    id result = nil;
    
    //If they are asking for the last one, short circut
    if (self.lastObjectSelected != nil) {
        if (self.lastObjectSelected.index == index) {
            return self.lastObjectSelected.object;
        }
    }
    
    sqlite3_bind_int(_statementSelect, 1, (int)index);
    
    if (sqlite3_step(_statementSelect) == SQLITE_ROW) {
        const void *blob = sqlite3_column_blob(_statementSelect, 0);
        int bytes = sqlite3_column_bytes(_statementSelect, 0);
       NSData *queryResult = [[NSData alloc] initWithBytes: blob
                                                     length: (NSUInteger)bytes];
        result = [MADArrayCaching newObjectForData:queryResult];
        
        MADIndex *idx = [[MADIndex alloc] initWithIndex:index andObject:result];
        self.lastObjectSelected = idx;
        sqlite3_reset(_statementSelect);
        
    }
    return result;
}

- (void)removeAllObjects {
    _lastObjectSelected = nil;
    _numberOfRows = 0;
    NSDictionary *queryDefination;
    MTQuery *queryDeleteAllFromTable;
    queryDefination = [MTQuery newQueryDefinitionCacheDeleteAllFromTable: MTArrayCachedTableName];
    queryDeleteAllFromTable = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheDeleteAllFromTable
                                                                   object: queryDefination];
    
    NSError * __autoreleasing *error = NULL;
    BOOL success = NO;
    success = [self.database executeQuery:queryDeleteAllFromTable withError:error];

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
    sqlite_int64 lastRowid = 0;
    int stepResult = sqlite3_step(_statementCount);
    if (stepResult == SQLITE_ROW || stepResult == SQLITE_DONE) {
        lastRowid = sqlite3_column_int64(_statementCount, 0) + 1;
        sqlite3_reset(_statementCount);
    }
    return lastRowid;
}

- (BOOL)isEmpty { return _numberOfRows > 0; }

- (NSArray *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    if (![self isEmpty]) {  //wat??
        NSData *queryResult;
        while (sqlite3_step(_statementEnumer) == SQLITE_ROW) {
            
            const void *blob = sqlite3_column_blob(_statementEnumer, 0);
            int bytes = sqlite3_column_bytes(_statementEnumer, 0);

            queryResult = [[NSData alloc] initWithBytes: blob
                                                 length: (NSUInteger)bytes];
            id result = [MADArrayCaching newObjectForData:queryResult];
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

            const void *blob = sqlite3_column_blob(_statementEnumer, 0);
            int bytes = sqlite3_column_bytes(_statementEnumer, 0);

            NSData *queryResult;
            queryResult = [[NSData alloc] initWithBytes: blob
                                                 length: (NSUInteger)bytes];
            result = [MADArrayCaching newObjectForData:queryResult];
        } else if (stepResult == SQLITE_DONE) {
            sqlite3_reset(_statementEnumer);
            result = nil;
        }
    } else {
        sqlite3_reset(_statementEnumer);
    }
    return result;
}

- (void)resetEnumerator { sqlite3_reset(_statementEnumer); }

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
                id obj = [MADArrayCaching newObjectForData:queryResult];
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
