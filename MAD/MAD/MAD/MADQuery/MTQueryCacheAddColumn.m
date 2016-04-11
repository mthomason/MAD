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
#import <MADFoundation/MADDataColumn.h>
#import "MTDatabaseConnection.h"
#import "MTDatabaseSqlite3.h"

@class MTDatabaseSqlite3;

@interface MTQueryCacheAddColumn ()

    @property (nonatomic, copy) NSString *tableName;
    @property (nonatomic, copy) NSString *columnName;
    @property (nonatomic, strong) MADDataColumn *column;
    @property (nonatomic, assign) bool createTable;
    @property (nonatomic, assign) bool uniqueColumnHack;

@end

@implementation MTQueryCacheAddColumn

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheAddColumnDataColumn = @(MTQueryCacheAddColumnDataColumn);
        NSNumber *keyMTQueryCacheAddColumnTableName = @(MTQueryCacheAddColumnTableName);
        NSNumber *keyMTQueryCacheAddColumnColumnName = @(MTQueryCacheAddColumnColumnName);
        NSNumber *keyMTQueryCacheAddColumnCreateTable = @(MTQueryCacheAddColumnCreateTable);

        MADDataColumn *column = object[keyMTQueryCacheAddColumnDataColumn];
        [self setColumn:column];
        
        NSString *tableName = object[keyMTQueryCacheAddColumnTableName];
        NSString *columnName = object[keyMTQueryCacheAddColumnColumnName];
        NSNumber *createTable = object[keyMTQueryCacheAddColumnCreateTable];
        NSNumber *uniqueObj = object[@(MTQueryCacheAddColumnUnique)];
        BOOL uniqueValue = NO;
        if (uniqueObj != nil) {
            uniqueValue = uniqueObj.boolValue;
        }
        [self setUniqueColumnHack:uniqueValue];
        
        [self setCreateTable:createTable.boolValue];
        [self setColumnName:columnName];
        
        [self setTableName:tableName];
        
        [self setQueryObject:object];
        

    }
    return self;
}

- (instancetype)initWithTableName:(NSString *)tableName columnName:(NSString *)columnName column:(MADDataColumn *)dataColumn createTable:(bool)createTable uniqueColumnHack:(bool)uniqueColumnHack {
    if (self = [super init]) {
        
        _createTable = createTable;
        _uniqueColumnHack = uniqueColumnHack;
        _tableName = tableName.copy;
        _columnName = columnName.copy;
        self.column = dataColumn;
        
    }
    return self;
}



- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *tableName = [self tableName];
    NSString *columnName = [self columnName];
    
    MTDatabaseSqlite3 *database = [self database];
    MTDataType datatype = self.column.columnType;
    NSString *columnAffinity = [database columnAffinityForDataType:datatype];

    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, columnAffinity];
    
    NSString *unique = self.uniqueColumnHack ? @"UNIQUE" : @"";
    if ([self.column isPrimaryKey]) {
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
