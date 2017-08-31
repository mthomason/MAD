//
//  MADQueryCacheAddColumn.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheAddColumn.h"

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>

#import <MADAPI/MADQueryType.h>

#import "MADQueryCacheAddColumnParameters.h"
#import "MADQueryParameters.h"

@class MADDatabaseSqlite3;

@interface MADQueryCacheAddColumn ()

    @property (nonatomic, strong) NSString *sql;
    @property (nonatomic, strong) NSString *tableName;

@end

@implementation MADQueryCacheAddColumn

@synthesize database = _database;

// FIXME: This is currently SQLite specific.

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MADQueryCacheAddColumn expects NSDictionary.");
        
        id keyDataColumn = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnDataColumn];
        MADDataColumn *column = object[keyDataColumn];
        
        id keyTableName = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnTableName];
        self.tableName = object[keyTableName];
        
        id keyColumnName = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnColumnName];
        NSString *columnName = object[keyColumnName];
        
        id keyCreateTable = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnCreateTable];
        NSNumber *createTable = object[keyCreateTable];
        
        id keyColumnAffinity = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnAffinity];
        NSString *columnAffinity = object[keyColumnAffinity];
        
        id keyColumnUnique = [[NSNumber alloc] initWithShort: MADQueryCacheAddColumnUnique];
        NSNumber *uniqueObj = object[keyColumnUnique];
        BOOL uniqueValue = NO;
        if (uniqueObj != nil) {
            uniqueValue = uniqueObj.boolValue;
        }
        
        NSString *sql = [MADQueryCacheAddColumn newSqlWithTableName:self.tableName
                                                        columnName:columnName
                                                          datatype:column.type
                                                      isPrimaryKey:column.isPrimaryKey
                                                       createTable:createTable.boolValue ?
                                                                                YES : NO
                                                  uniqueColumnHack:uniqueValue
                                                    columnAffinity:columnAffinity];
        self.sql = sql;
    }
    return self;
}

- (instancetype)initWithTableName: (NSString *)tableName
                       columnName: (NSString *)columnName
                           column: (MADDataColumn *)column
                      createTable: (BOOL)createTable
                 uniqueColumnHack: (BOOL)uniqueColumnHack
                   columnAffinity: (NSString *)columnAffinity {
    if (self = [super init]) {
        NSString *sql = [MADQueryCacheAddColumn newSqlWithTableName:tableName
                                                        columnName:columnName
                                                          datatype:column.type
                                                      isPrimaryKey:column.isPrimaryKey
                                                       createTable:createTable
                                                  uniqueColumnHack:uniqueColumnHack
                                                    columnAffinity:columnAffinity];
        self.sql = sql;
        
    }
    return self;
}

- (NSString *)queryTableName {
    return self.tableName;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return self.sql;
}

+ (NSString *)newSqlWithTableName:(NSString *)tableName
                       columnName:(NSString *)columnName
                         datatype:(MADDataType)datatype
                     isPrimaryKey:(BOOL)isPrimaryKey
                      createTable:(BOOL)createTable
                 uniqueColumnHack:(BOOL)uniqueColumnHack
                   columnAffinity:(NSString *)columnAffinity {
    
    NSString *columnDefination = [NSString stringWithFormat:@"%@ %@", columnName, columnAffinity];
    NSString *unique = uniqueColumnHack ? @"UNIQUE" : @"";
    if (isPrimaryKey) { unique = @"PRIMARY KEY"; }
    
    NSString *CreateTable = @"CREATE TABLE IF NOT EXISTS main.%@ (%@ %@);";
    NSString *AlterTable  = @"ALTER TABLE main.%@ ADD COLUMN %@;";
    
    NSString *sql = createTable ?
            [NSString stringWithFormat:CreateTable, tableName, columnDefination, unique] :
            [NSString stringWithFormat:AlterTable, tableName, columnDefination];
    
    return sql;
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCacheAddColumn;
}

- (NSArray <NSString *> *)queryColumnKeys {
    @throw NSInternalInconsistencyException;
}

@end
