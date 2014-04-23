//
//  MTDataTableFast.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

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

@interface MTDataTableFast ()

@property (assign) sqlite3 *database;
@property (assign, readwrite) sqlite3_stmt *statement;

@property (nonatomic, strong) MTDatabase *db;

@property (nonatomic, assign, readwrite) NSUInteger tag;
@property (nonatomic, strong, readwrite) NSMutableArray *columnKeys;
@property (nonatomic, strong, readwrite) NSMutableDictionary *columns;
@property (nonatomic, strong, readwrite) NSArray *sortDescriptors;

@property (nonatomic, strong, readwrite) NSString *sqlQuery;

@property (nonatomic, assign, readwrite) NSUInteger rowCounter;

@property (nonatomic, assign) BOOL bulkInsertLoop;

@end

@implementation MTDataTableFast

- (void)dealloc {
    sqlite3_close_v2(_database);
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    // FIXME: Implement this.
    //[super encodeWithCoder:encoder];
}

- (id)initWithCoder:(NSCoder *)decoder {
    // FIXME: Implement this.
    return nil;
}

- (id)initWithId:(NSUInteger)objectId {
    self = [super init];
    if (self) {
        
        [self setBulkInsertLoop:NO];
        
        [self setTag:objectId];
        
        NSString *filename = [NSFileManager filenameId:objectId extention:@"maddb"];
        NSURL *cacheDirectory = [NSFileManager cacheDirectory];
        NSURL *fileUrl = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
        [self setUrl:fileUrl];
        
        [self reopenDbConnection];
        
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
        [self setColumns:columns];
        
        NSMutableArray *columnKeys = [[NSMutableArray alloc] init];
        [self setColumnKeys:columnKeys];
        
        NSArray *sortDescriptors = [NSArray array];
        [self setSortDescriptors:sortDescriptors];
        
        [self setRowCounter:0];
        
        [self setupSqlite];

    }
    return self;
}

- (void)reopenDbConnection {
    MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:[self url]];
    MTDatabase *database = [MTDatabase databaseFactory:connection];
    [self setDb:database];
}

- (void)setupSqlite {
    _statement = NULL;
    const char *path = [[[self url] path] UTF8String];
    
    BOOL success = sqlite3_open_v2(path, &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX, NULL) == SQLITE_OK;
    if (success == NO) {
        const char *errorMessage = sqlite3_errmsg(_database);
        NSString *message = [NSString stringWithUTF8String: errorMessage];
        NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
        NSLog(@"%@ %@", message, title);
    }
    success = sqlite3_extended_result_codes(_database, true) == SQLITE_OK;

}

- (NSString *)sqlQuery {
    return [self sqlQueryWithFilters:nil];
}

- (NSString *)sqlQueryWithFilters:(NSDictionary *)predicates {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT "];
    NSUInteger columnCounter = 0;
    
    NSAssert([[self columnKeys] count] != 0, @"Bad parameter data.");  // FIXME: Handle case where no columns.
    
    for (NSString *key in [self columnKeys]) {
        if (columnCounter != 0) {
            [sql appendString:@", "];
        }
        [sql appendFormat:@"\"%@\"", key];
        columnCounter++;
    }
    [sql appendFormat:@" FROM %@", [self tableName]];

    if ([[self sortDescriptors] count] > 0) {
        [sql appendString:@" ORDER BY "];
        NSUInteger sortCounter = 0;
        for (NSSortDescriptor *sortDescriptor in [self sortDescriptors]) {
            if (sortCounter != 0) [sql appendString:@", "];
            NSString *sortDirection = [sortDescriptor ascending] ? @"ASC" : @"DESC";
            [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDirection];
            sortCounter++;
        }
    }
    return sql;
    
}

- (NSString *)sqlQueryRemoveAll {
    return [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:[self sqlQuery]];
    [sql appendFormat:@" LIMIT %ld ", (unsigned long)limit];
    NSLog(@"%@", sql);
    return sql;
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:[self sqlQueryWithLimit:limit]];
    [sql appendFormat:@" OFFSET %ld ", (unsigned long)offset];
    NSLog(@"%@", sql);
    return sql;
}

- (void)cache {
    // FIXME: Implement this.
    //[super cache];
}
- (id)plist {
    // FIXME: Implement this.
    return nil;
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
    [query performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        if (!success) NSLog(@"Error %@", error);
        dispatch_semaphore_signal(semaphoreQuery);
    }];
    dispatch_semaphore_wait(semaphoreQuery, DISPATCH_TIME_FOREVER);
}

- (void)addRow:(NSArray *)row {
        
    NSDictionary *queryDefination = @{
                                      @(MTQueryCacheAddRowColumnKeys) : [self columnKeys],
                                      @(MTQueryCacheAddRowColumns) : [self columns],
                                      @(MTQueryCacheAddRowData) : row,
                                      @(MTQueryCacheAddRowTableName) : [self tableName]
                                      };
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheAddRow object:queryDefination];
    self.rowCounter++;
    dispatch_semaphore_t semaphoreQuery = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        if (!success) NSLog(@"Error %@", error);
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
    NSMutableArray *newSorts = [[NSMutableArray alloc] initWithCapacity:[sortDescriptors count]];
    for (NSSortDescriptor *sort in sortDescriptors) {
        for (NSString *columnKey in [[self columns] keyEnumerator]) {
            MTDataColumn *column = [[self columns] objectForKey:columnKey];
            if ([[column fieldName] isEqualToString:[sort key]]) {
                NSSortDescriptor *sortn = [NSSortDescriptor sortDescriptorWithKey:columnKey  ascending:[sort ascending]];
                [newSorts addObject:sortn];
                break;
            }
        }
    }
    [self setSortDescriptors:newSorts];
    // FIXME: reset cache after setting the sort descriptors    
}

- (void)removeAllObjects {
    
    dispatch_semaphore_t semaphoreRemoveAll = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [self dropTable];
        [self vacuumCacheDb];
        dispatch_semaphore_signal(semaphoreRemoveAll);
    });
    dispatch_semaphore_wait(semaphoreRemoveAll, DISPATCH_TIME_FOREVER);

    [[self columnKeys] removeAllObjects];
    [[self columns] removeAllObjects];
    
}

- (void)vacuumCacheDb {
    NSDictionary *queryVacuumDefination = @{ };
    MTQuery *queryVacuum = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheVacuum object:queryVacuumDefination];

    dispatch_semaphore_t semaphoreVacuum = dispatch_semaphore_create(0);
    [queryVacuum performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
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
    [queryDropTable performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
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
    [queryDeleteAllFromTable performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
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

- (NSArray *)objectAtRow:(NSInteger)row limit:(NSUInteger)limit {
    id results = nil;
    if (row != NSNotFound && limit > 0) {
        results = [[NSMutableArray alloc] initWithCapacity:limit];
        NSDictionary *currentObject = nil;
        _statement = NULL;
        NSString *sql = [self sqlQueryWithLimit:limit offset:row];
        const char *sqlc = [sql UTF8String];
        char *queryString = sqlite3_mprintf((char *) sqlc);
        BOOL success = sqlite3_prepare_v2(_database, queryString, -1, &_statement, NULL) == SQLITE_OK;
        //NSMutableArray *results = nil;
        if (success) {
            while (sqlite3_step(_statement) == SQLITE_ROW) {
                NSDictionary *currentD = [self currentObject];
                currentObject = [NSDictionary dictionaryWithDictionary:currentD];
                [results addObject:currentObject];
            }
        } else {
            const char *errorMessage = sqlite3_errmsg(_database);
            NSString *message = [NSString stringWithUTF8String: errorMessage];
            NSLog(@"%@", message);
        }
        sqlite3_finalize(_statement);
    } else {
        results = [NSArray array];
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
        NSString *sql = [self sqlQuery];
        NSLog(@"objectEnumerator: %@", sql);
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:[self url]];
        objectEnumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection:databaseConnection
                                                                                       columns:[self columns]
                                                                                    columnKeys:[self columnKeys]
                                                                                           sql:sql];
    }
    return objectEnumerator;
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

- (id)currentObject {
    NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:[[self columns] count]];
    int columnCounter = 0;
    for (id key in [self columnKeys]) {
        MTDataColumn *dataColumn = [self columns][key];
        id columnValue;
        switch ([[dataColumn columnType] integerValue]) {
            case MTDataTypeInteger:
                columnValue = [NSNumber numberWithLongLong:sqlite3_column_int64(_statement, columnCounter)];
                break;
            case MTDataTypeBlob:
                columnValue = [NSData dataWithBytes: sqlite3_column_blob(_statement, columnCounter)
                                             length: sqlite3_column_bytes(_statement, columnCounter)];
                break;
            case MTDataTypeFloat:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeDouble:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeDecimal:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeString:
                columnValue = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(_statement, columnCounter)];
                break;
            default:
                NSAssert(false, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3");
                columnValue = sqlite3_column_type(_statement, columnCounter) == SQLITE_TEXT ? [NSString stringWithUTF8String:(const char *)sqlite3_column_text(_statement, columnCounter)] : nil;
                break;
        }
        if (columnValue != nil) {
            [currentObject setValue:columnValue forKey:[dataColumn fieldName]];
        }
        columnCounter++;
    }
    return currentObject;
}

- (void)beginBulkInsert {
    [self setBulkInsertLoop:YES];
    



    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeOff object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeOverride object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [queryJournalMode performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);
    

    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheBeginTransaction object:@{}];
    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);
}

- (void)endBulkInsert {
    [self setBulkInsertLoop:NO];
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheEndTransaction object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeDefault object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeDefault object:@{}];
    [queryJournalMode performQueryWithDatabase:[self db] completion:^(BOOL success, NSError *error) {
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);

    [[self db] cleanupBulkInsert];
}


/*
- (NSArray *)getDetalForGroupLevel:(NSUInteger)level andKeys:(NSArray *)keys {
    
    [[[self query] datatable] getDetalForGroupLevel:level keys:];
}

- (NSArray *)getKeysForGroupLevel:(NSUInteger)level andKeys:(NSArray *)keys {
    
    [[[self query] datatable] getDetalForGroupLevel:level keys:];
}*/


@end
