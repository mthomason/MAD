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
@property (nonatomic, assign) MTDataType columnType;
@property (nonatomic, assign) BOOL createTable;

@property (nonatomic, assign) BOOL uniqueColumnHack;

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
        NSNumber *uniqueObj = [object objectForKey:@(MTQueryCacheAddColumnUnique)];
        BOOL uniqueValue = NO;
        if (uniqueObj != nil) {
            uniqueValue = [uniqueObj boolValue];
        }
        [self setUniqueColumnHack:uniqueValue];
        
        [self setCreateTable:[createTable boolValue]];
        [self setColumnName:columnName];
        
        [self setTableName:tableName];
        
        if (url != nil) {
            MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:url];
            MTDatabase *db = [MTDatabase databaseFactory:connection];
            NSAssert([db isKindOfClass:[MTDatabaseSqlite3 class]], @"Only allow Sqlite3. Fix this sometime.");
            [self setDatabase:db];
        }
        [self setQueryObject:object];
        
        MTDataType type = [[column columnType] integerValue];
        [self setColumnType:type];

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *tableName = [self tableName];
    NSString *columnName = [self columnName];
    
    NSString *columnAffinity = [[self database] nativeTypeForDataType:[self columnType]];

    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, columnAffinity];
    
    NSString *collate = [columnAffinity isEqualToString:@"TEXT"] ? @"COLLATE LSASC" : @"COLLATE LSDESC";;
    
    NSString *unique = self.uniqueColumnHack ? @"UNIQUE" : @"";
    NSString *sql = [self createTable] ?
    
    [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS main.%@ (%@ %@ %@);", tableName, columnDefination, unique, collate] :
                    [NSString stringWithFormat:@"ALTER TABLE main.%@ ADD COLUMN %@ %@", tableName, columnDefination, collate];
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
