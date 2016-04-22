//
//  MTArrayCached.m
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADArrayCaching.h"
#import <MADDataStructures/MADIndex.h>
#import <MAD/MADConstants.h>
#import <MADSqlite3/MADSqlite3.h>
#import <MADFoundation/MADDataColumn.h>
#import "MTQuery.h"
#import "MTDatabaseConnection.h"
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

@interface MADArrayCaching ()

    @property (nonatomic, strong, readwrite) NSString *identifier;
    @property (nonatomic, strong) MTDatabaseCache *database;

    @property (nonatomic, assign) int numberOrRows;
    @property (nonatomic, assign) sqlite3_stmt *statementInsert;
    @property (nonatomic, assign) sqlite3_stmt *statementSelect;
    @property (nonatomic, assign) sqlite3_stmt *statementCount;
    @property (nonatomic, assign) sqlite3_stmt *statementEnumer;

    @property (nonatomic, strong) NSMutableArray *fastEnumerationObjects;
    @property (nonatomic, strong) MADIndex *lastObjectSelected;

@end

@implementation MADArrayCaching

- (void)dealloc {
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

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        
        _statementCount = NULL;
        _statementEnumer = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;

        NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
        self.fastEnumerationObjects = fastEnumerationObjects;

        NSString *i = [NSString stringWithString:identifier];
        self.identifier = i;
        
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier cachedDelegate:(id<MTCacheProtocol>)cachedDelegate {
    if (self = [super init]) {
        NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
        [self setFastEnumerationObjects:fastEnumerationObjects];
        
        _statementCount = NULL;
        _statementEnumer = NULL;
        _statementInsert = NULL;
        _statementSelect = NULL;
        
        NSString *i = [NSString stringWithString:identifier];
        self.identifier = i;
        self.cachedDelegate = cachedDelegate;
    }
    return self;
}

- (void)reopenDatabaseAtUrl:(NSURL *)url {
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUrl:url];
    MTDatabaseCache *database = [MTDatabaseCache newDatabaseWithConnection:databaseConnection];
#ifdef MAD_MTArrayCached_DEBUG
    sqlite3_trace(database.databaseHandle, sqliteCallbackFunc, NULL);
#endif
    [self setDatabase:database];
}

- (void)initializeDatabase {
    
    NSURL *url = [self url];
    BOOL createDatabase = ![[NSFileManager defaultManager] fileExistsAtPath:url.path];
    [self reopenDatabaseAtUrl:url];
    if (!createDatabase) {
        createDatabase = ![self.database tableExist:MTArrayCachedTableName];
    }
    if (![self.database tableExist:MTArrayCachedTableName]) {

        MADDataColumn *columnKey = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnKey];
        columnKey.type = MTDataTypeInteger;
        columnKey.primaryKey = true;
        columnKey.notNull = true;
        columnKey.autoIncrement = false;
        
        [self addColumn:columnKey toTable:MTArrayCachedTableName columnName:columnKey.identifier createTable:YES unique:NO];

        MADDataColumn *columnValue = [[MADDataColumn alloc] initWithIdentifier:MTArrayCachedColumnValue];
        columnValue.type = MTDataTypeBlob;
        columnValue.primaryKey = false;
        columnValue.notNull = true;
        columnValue.autoIncrement = false;

        [self addColumn:columnValue toTable:MTArrayCachedTableName columnName:columnValue.identifier createTable:NO unique:NO];

        self.numberOrRows = 0;
    }
    [self prepareStatements];
    self.numberOrRows = (int)[self count];
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
    NSString *sql = [[NSString alloc] initWithFormat:MTArrayCachedQueryEnumer,  MTArrayCachedColumnValue, MTArrayCachedTableName, MTArrayCachedColumnKey];
    if (_statementEnumer != NULL) {
        sqlite3_finalize(_statementEnumer);
        _statementEnumer = NULL;
    }
    BOOL success = YES;
    if (_statementEnumer == NULL)
        success = sqlite3_prepare_v2([[self database] databaseHandle], sql.UTF8String, -1, &_statementEnumer, NULL) == SQLITE_OK;
    return success;
}

- (BOOL)prepareStatementInsert {
    NSString *queryString = [[NSString alloc] initWithFormat:MTArrayCachedQueryInsert, MTArrayCachedTableName, MTArrayCachedColumnKey, MTArrayCachedColumnValue];
    if (_statementInsert != NULL) {
        sqlite3_finalize(_statementInsert);
        _statementInsert = NULL;
    }
    BOOL success = YES;
    if (_statementInsert == NULL)
        success = sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementInsert, NULL) == SQLITE_OK;
    return success;
}

- (BOOL)prepareStatementSelect {
    NSString *queryString = [[NSString alloc] initWithFormat:MTArrayCachedQuerySelect, MTArrayCachedColumnValue, MTArrayCachedTableName, MTArrayCachedColumnKey];
    if (_statementSelect != NULL) {
        sqlite3_finalize(_statementSelect);
        _statementSelect = NULL;
    }
    BOOL success = YES;
    if (_statementSelect == NULL)
        success = sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementSelect, NULL) == SQLITE_OK;
    return success;

}

- (BOOL)prepareStatementCount {
    NSString *queryString = [[NSString alloc] initWithFormat:MTArrayCachedQueryLastId, MTArrayCachedColumnKey, MTArrayCachedTableName, MTArrayCachedColumnKey];
    if (_statementCount != NULL) {
        sqlite3_finalize(_statementCount);
        _statementCount = NULL;
    }
    BOOL success = YES;
    if (_statementCount == NULL)
        success = sqlite3_prepare_v2([[self database] databaseHandle], [queryString UTF8String], -1, &_statementCount, NULL) == SQLITE_OK;
    return success;
}

#ifdef MAD_MTArrayCached_DEBUG
void sqliteCallbackFunc(void *foo, const char* statement);
void sqliteCallbackFunc(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif

+ (NSURL *)urlForIdentifier:(NSString *)identifer {
    NSURL *cachedArrayDirectories = [MADFileUtilities localCacheDirectoryForGroupIdentifier:identifer];
    NSString *filename = [identifer stringByAppendingPathExtension:@"madac"];
    return [cachedArrayDirectories URLByAppendingPathComponent:filename isDirectory:NO];
}

- (NSURL *)url {
    NSURL *result = nil;
    NSURL *cachedArrayDirectories = self.cachedDelegate == nil ?
    [MADFileUtilities localCacheDirectoryForGroupIdentifier:MADIdentifierGroup] :
    [self.cachedDelegate cachedFilesDirectory];
    NSString *filename = [self.identifier stringByAppendingPathExtension:@"madac"];
    result = [cachedArrayDirectories URLByAppendingPathComponent:filename isDirectory:NO];
    return result;
}

- (void)addColumn:(MADDataColumn *)column toTable:(NSString *)table
                                       columnName:(NSString *)columnName
      createTable:(BOOL)create unique:(BOOL)unique {
    
    NSString *columnAffinity = [self.database newNativeTypeForDataType:column.type];
    MTQueryCacheAddColumn *queryCacheAddColumn =
        [[MTQueryCacheAddColumn alloc] initWithTableName:table columnName:columnName column:column
                                             createTable:create ? true : false
                                        uniqueColumnHack:unique ? true : false
                                        columnAffinity:columnAffinity];
    bool success = false;
    NSError * __autoreleasing error = NULL;
    success = [self.database executeQuery:queryCacheAddColumn withError:&error];
}

- (NSData *)dataForObject:(id)object {
    NSError * __autoreleasing * error = NULL;
    static const NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList: object format: format
                                                             options: 0 error: error];
    NSAssert(error == NULL, @"Error %@ in %s.", error, __PRETTY_FUNCTION__);
    return data;
}

- (id)objectForData:(NSData *)data {
    NSError * __autoreleasing * error = NULL;
    static const NSPropertyListReadOptions options = NSPropertyListImmutable;
    id propertyList = [NSPropertyListSerialization propertyListWithData: data options: options
                                                                 format: nil error: error];
    NSAssert(error == NULL, @"Error %@ in %s.", error, __PRETTY_FUNCTION__);
    return propertyList;
}

- (void)addObject:(id)object {
    @autoreleasepool {

        self.lastObjectSelected = nil;
        NSError * __autoreleasing * error = NULL;
        static const NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList: object format: format
                                                                 options: 0 error: error];
        
        const void *dataBytes = data.bytes;
        int dataLength = data.length;
        
        sqlite3_bind_int(_statementInsert, 1, _numberOrRows);
        sqlite3_bind_blob(_statementInsert, 2, dataBytes, dataLength, SQLITE_TRANSIENT);
        if (sqlite3_step(_statementInsert) == SQLITE_DONE) {
            sqlite3_reset(_statementInsert);
            _numberOrRows++;
        }
    }
}

- (void)writeData:(NSData *)data {
    sqlite3_bind_int(_statementInsert, 1, _numberOrRows);
    const void *dataBytes = data.bytes;
    int dataLength = data.length;
    sqlite3_bind_blob(_statementInsert, 2, dataBytes, dataLength, SQLITE_TRANSIENT);
    if (sqlite3_step(_statementInsert) == SQLITE_DONE) {
        sqlite3_reset(_statementInsert);
        _numberOrRows++;
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
        result = [NSData dataWithBytes: sqlite3_column_blob(_statementSelect, 0)
                                length: (NSUInteger)sqlite3_column_bytes(_statementSelect, 0)];
        sqlite3_reset(_statementSelect);
    }
    return result;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index { return [self objectAtIndex:index]; }

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
        const void *sqlite3ColumnBlob = sqlite3_column_blob(_statementSelect, 0);
        int bytes = sqlite3_column_bytes(_statementSelect, 0);
        NSData *queryResult = [NSData dataWithBytes: sqlite3ColumnBlob
                                             length: (NSUInteger)bytes];
        result = [self objectForData:queryResult];
        
        MADIndex *idx = [[MADIndex alloc] initWithIndex:index andObject:result];
        self.lastObjectSelected = idx;
        sqlite3_reset(_statementSelect);
        
    }
    return result;
}

- (void)removeAllObjects {
    [self setLastObjectSelected:nil];
    self.numberOrRows = 0;
    NSDictionary *queryDefination = [MTQuery newQueryDefinitionCacheDeleteAllFromTable: MTArrayCachedTableName];
    MTQuery *queryDeleteAllFromTable = [[MTQuery alloc] initWithQueryType: MTQueryTypeCacheDeleteAllFromTable
                                                                   object: queryDefination];
    
    NSError * __autoreleasing error = NULL;
    bool success = false;
    success = [self.database executeQuery:queryDeleteAllFromTable withError:&error];

}

- (MADQueryDefinition *)queryDefinatinSelect {
    NSArray *columnNameIndex = [[NSArray alloc] initWithObjects: MTArrayCachedColumnKey];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey: MTArrayCachedColumnKey
                                                            ascending: NO
                                                             selector: @selector(compare:)];
    NSArray *sortdesc = [[NSArray alloc] initWithObjects: sortn];
    MADQueryDefinition *queryDefinitionSelect = [MTQuery newQueryDefinitionSelect: columnNameIndex
                                                                        tableName: MTArrayCachedTableName
                                                                  sortDescriptors: sortdesc];
    return queryDefinitionSelect;
}

- (MADQueryDefinition *)queryDefinationLastObject {
    NSArray *columnNameIndex = [[NSArray alloc] initWithObjects: MTArrayCachedColumnKey, nil];
    NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey: MTArrayCachedColumnKey
                                                            ascending: NO
                                                             selector: @selector(compare:)];
    NSArray *sortdesc = [[NSArray alloc] initWithObjects: sortn];
    MADQueryDefinition *queryDefinition = [MTQuery newQueryDefinitionSelect: columnNameIndex
                                                                  tableName: MTArrayCachedTableName
                                                            sortDescriptors: sortdesc];
    NSMutableDictionary *queryDefinationSelect = queryDefinition.mutableCopy;
    NSNumber *yes = @YES;
    NSNumber *key = @(MTQueryCacheSelectLimitOffsetParamatersDropRowid);

    [queryDefinationSelect setObject:yes forKey:key];
    
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

- (BOOL)isEmpty { return self.numberOrRows > 0; }

- (NSArray *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    if (![self isEmpty]) {  //wat??
        while (sqlite3_step(_statementEnumer) == SQLITE_ROW) {
            NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementEnumer, 0)
                                                 length: (unsigned int)sqlite3_column_bytes(_statementEnumer, 0)];
            id result = [self objectForData:queryResult];
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
                                                 length: (unsigned int)sqlite3_column_bytes(_statementEnumer, 0)];
            result = [self objectForData:queryResult];
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
        [self.fastEnumerationObjects removeAllObjects];
        
        for (i = 0; i<len; i++) {
            @autoreleasepool {
                stepResult = sqlite3_step(_statementEnumer);
                if (stepResult == SQLITE_ROW) {
                    NSData *queryResult = [NSData dataWithBytes: sqlite3_column_blob(_statementEnumer, 0)
                                                         length: (unsigned int)sqlite3_column_bytes(_statementEnumer, 0)];
                    id obj = [self objectForData:queryResult];
                    [self.fastEnumerationObjects addObject:obj];
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
    }
    return i;
}



@end
