//
//  MTQueryCacheAddColumn.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheAddColumn.h"
#import "MTDataColumn.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseField.h"
#import "MTDatabase.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"

@class MTDatabaseSqlite3;

@interface MTQueryCacheAddColumn ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSString *columnAffinity;
@property (nonatomic, assign) BOOL createTable;

@end

@implementation MTQueryCacheAddColumn

// FIXME: This is currently SQLite specific.

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheAddColumnUrl = @(MTQueryCacheAddColumnUrl);
        NSNumber *keyMTQueryCacheAddColumnDataColumn = @(MTQueryCacheAddColumnDataColumn);
        NSNumber *keyMTQueryCacheAddColumnTableName = @(MTQueryCacheAddColumnTableName);
        NSNumber *keyMTQueryCacheAddColumnColumnName = @(MTQueryCacheAddColumnColumnName);
        NSNumber *keyMTQueryCacheAddColumnCreateTable = @(MTQueryCacheAddColumnCreateTable);

        MTDataColumn *column = [object objectForKey:keyMTQueryCacheAddColumnDataColumn];
        NSString *tableName = [object objectForKey:keyMTQueryCacheAddColumnTableName];
        NSURL *url = [object objectForKey:keyMTQueryCacheAddColumnUrl];
        NSString *columnName = [object objectForKey:keyMTQueryCacheAddColumnColumnName];
        NSNumber *createTable = [object objectForKey:keyMTQueryCacheAddColumnCreateTable];
        [self setCreateTable:[createTable boolValue]];
        [self setColumnName:columnName];
        
        [self setTableName:tableName];
        
        MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:url];
        MTDatabase *db = [MTDatabase databaseFactory:connection];
        NSAssert([db isKindOfClass:[MTDatabaseSqlite3 class]], @"Only allow Sqlite3. Fix this sometime.");
        [self setDatabase:db];
        [self setQueryObject:object];
        
        MTDataType type = [[column columnType] integerValue];
        NSString *columnAffinity = [db nativeTypeForDataType:type];
        [self setColumnAffinity:columnAffinity];

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *tableName = [self tableName];
    NSString *columnName = [self columnName];
    
    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, [self columnAffinity]];
    NSString *sql = [self createTable] ?
                    [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS main.%@ (%@);", tableName, columnDefination] :
                    [NSString stringWithFormat:@"ALTER TABLE main.%@ ADD COLUMN %@", tableName, columnDefination];
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
