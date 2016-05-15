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
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

@class MTDatabaseSqlite3;

@interface MTQueryCacheAddColumn ()
    @property (nonatomic, strong) NSString *sql;
@end

@implementation MTQueryCacheAddColumn

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddColumn expects NSDictionary.");
        
        id keyDataColumn = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnDataColumn];
        MADDataColumn *column = object[keyDataColumn];
        
        id keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnTableName];
        NSString *tableName = object[keyTableName];
        
        id keyColumnName = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnColumnName];
        NSString *columnName = object[keyColumnName];
        
        id keyCreateTable = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnCreateTable];
        NSNumber *createTable = object[keyCreateTable];
        
        id keyColumnAffinity = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnAffinity];
        NSString *columnAffinity = object[keyColumnAffinity];
        
        id keyColumnUnique = [[NSNumber alloc] initWithShort: MTQueryCacheAddColumnUnique];
        NSNumber * __weak uniqueObj = object[keyColumnUnique];
        bool uniqueValue = false;
        if (uniqueObj != nil) {
            uniqueValue = uniqueObj.boolValue ? true : false;
        }
        
        NSString *sql = [MTQueryCacheAddColumn newSqlWithTableName:tableName columnName:columnName
                                                          database:self.database
                                                          datatype:column.type
                                                      isPrimaryKey:column.isPrimaryKey
                                                       createTable:createTable.boolValue ?
                                                                                true : false
                                                  uniqueColumnHack:uniqueValue
                                                    columnAffinity:columnAffinity];
        self.sql = sql;
    }
    return self;
}

- (instancetype)initWithTableName:(NSString *)tableName columnName:(NSString *)columnName
                           column:(MADDataColumn *)column createTable:(bool)createTable
                 uniqueColumnHack:(bool)uniqueColumnHack columnAffinity:(NSString *)columnAffinity {
    if (self = [super init]) {
        NSString *sql = [MTQueryCacheAddColumn newSqlWithTableName:tableName columnName:columnName
                                                          database:self.database
                                                          datatype:column.type
                                                      isPrimaryKey:column.isPrimaryKey
                                                       createTable:createTable
                                                  uniqueColumnHack:uniqueColumnHack
                                                    columnAffinity:columnAffinity];
        self.sql = sql;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return self.sql;
}

+ (NSString *)newSqlWithTableName:(NSString *)tableName columnName:(NSString *)columnName
                         database:(MTDatabaseCache *)database datatype:(MTDataType)datatype
                     isPrimaryKey:(bool)isPrimaryKey createTable:(bool)createTable
                 uniqueColumnHack:(bool)uniqueColumnHack columnAffinity:(NSString *)columnAffinity {
    
    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, columnAffinity];
    NSString *unique = uniqueColumnHack ? @"UNIQUE" : @"";
    if (isPrimaryKey) { unique = @"PRIMARY KEY"; }
    
    static NSString * const CreateTable = @"CREATE TABLE IF NOT EXISTS main.%@ (%@ %@);";
    static NSString * const AlterTable  = @"ALTER TABLE main.%@ ADD COLUMN %@;";
    
    NSString *sql = createTable ?
            [NSString stringWithFormat:CreateTable, tableName, columnDefination, unique] :
            [NSString stringWithFormat:AlterTable, tableName, columnDefination];
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

@end
