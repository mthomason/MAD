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
@property (nonatomic, strong) MTDataColumn *column;
@property (nonatomic, assign) BOOL createTable;
@property (nonatomic, assign) BOOL uniqueColumnHack;

@end

@implementation MTQueryCacheAddColumn

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheAddColumnUrl = @(MTQueryCacheAddColumnUrl);
        NSNumber *keyMTQueryCacheAddColumnDataColumn = @(MTQueryCacheAddColumnDataColumn);
        NSNumber *keyMTQueryCacheAddColumnTableName = @(MTQueryCacheAddColumnTableName);
        NSNumber *keyMTQueryCacheAddColumnColumnName = @(MTQueryCacheAddColumnColumnName);
        NSNumber *keyMTQueryCacheAddColumnCreateTable = @(MTQueryCacheAddColumnCreateTable);

        MTDataColumn *column = object[keyMTQueryCacheAddColumnDataColumn];
        [self setColumn:column];
        
        NSString *tableName = object[keyMTQueryCacheAddColumnTableName];
        NSURL *url = object[keyMTQueryCacheAddColumnUrl];
        NSString *columnName = object[keyMTQueryCacheAddColumnColumnName];
        NSNumber *createTable = object[keyMTQueryCacheAddColumnCreateTable];
        NSNumber *uniqueObj = object[@(MTQueryCacheAddColumnUnique)];
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
            [self setDatabase:(MTDatabaseCache *)db];
        }
        [self setQueryObject:object];
        

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *tableName = [self tableName];
    NSString *columnName = [self columnName];
    
    NSString *columnAffinity = [[self database] nativeTypeForDataType:[[[self column] columnType] integerValue]];


    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, columnAffinity];
    
    
    NSString *unique = self.uniqueColumnHack ? @"UNIQUE" : @"";
    if ([[self column] isPrimaryKey]) {
        unique = @"PRIMARY KEY";
    }
    NSString *sql = [self createTable] ?
    
    [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS main.%@ (%@ %@);", tableName, columnDefination, unique] :
                    [NSString stringWithFormat:@"ALTER TABLE main.%@ ADD COLUMN %@;", tableName, columnDefination];
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
