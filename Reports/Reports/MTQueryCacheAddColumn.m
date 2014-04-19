//
//  MTQueryCacheAddColumn.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheAddColumn.h"
#import "MTDataColumn.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseField.h"
#import "MTDatabase.h"

@interface MTQueryCacheAddColumn ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSString *columnAffinity;
@property (nonatomic, assign) BOOL createTable;
@end

@implementation MTQueryCacheAddColumn

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
        
        NSString *columnAffinity = nil;
        MTDataType type = [[column columnType] integerValue];
        switch (type) {
            case MTDataTypeInteger:
                columnAffinity = @"INTEGER";
                break;
            case MTDataTypeString:
                columnAffinity = @"TEXT";
                break;
            case MTDataTypeBlob:
                columnAffinity = @"NONE";
                break;
            case MTDataTypeDouble:
                columnAffinity = @"REAL";
                break;
            case MTDataTypeNumber:
                columnAffinity = @"NUMERIC";
                break;
            default:
                columnAffinity = @"";
                break;
        }
        [self setColumnAffinity:columnAffinity];
        
        [self setTableName:tableName];
        
        MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:url];
        MTDatabase *db = [MTDatabase databaseFactory:connection];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *tableName = [self tableName];
    NSString *columnName = [self columnName];
    
    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, [self columnAffinity]];
    NSString *sql = [self createTable] ?
                    [NSString stringWithFormat:@"CREATE TABLE IF NOT EXIST main.%@ (%@);", tableName, columnDefination] :
                    [NSString stringWithFormat:@"ALTER TABLE main.%@ ADD COLUMN %@", tableName, columnDefination];
    
    return sql;
}

- (BOOL)expectsResults {
    return NO;
}

@end
