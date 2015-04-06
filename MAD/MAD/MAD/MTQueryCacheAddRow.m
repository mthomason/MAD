//
//  MTQueryCacheAddRow.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheAddRow.h"
#import "MTDataColumn.h"
#import "MTDatabaseDataBinding.h"
#import "MTDatabaseConnection.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheAddRow ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *row;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;

@end

@implementation MTQueryCacheAddRow

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddRow expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheAddRowUrl = @(MTQueryCacheAddRowUrl);
        NSNumber *keyMTQueryCacheAddRowData = @(MTQueryCacheAddRowData);
        NSNumber *keyMTQueryCacheAddRowColumns = @(MTQueryCacheAddRowColumns);
        NSNumber *keyMTQueryCacheAddRowColumnKeys = @(MTQueryCacheAddRowColumnKeys);
        NSNumber *keyMTQueryCacheAddRowTableName = @(MTQueryCacheAddRowTableName);
        
        NSURL *url = object[keyMTQueryCacheAddRowUrl];
        NSArray *row = object[keyMTQueryCacheAddRowData];
        NSDictionary *columns = object[keyMTQueryCacheAddRowColumns];
        NSArray *columnKeys = object[keyMTQueryCacheAddRowColumnKeys];
        NSString *tableName = object[keyMTQueryCacheAddRowTableName];
        
        [self setUrl:url];
        [self setTableName:tableName];
        [self setRow:row];
        [self setColumns:columns];
        [self setColumnKeys:columnKeys];

        if (url != nil) {
            MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:url];
            MTDatabase *db = [MTDatabase databaseFactory:connection];
            NSAssert([db isKindOfClass:[MTDatabaseSqlite3 class]] == YES, @"Only allow Sqlite3. Fix this sometime.");
            [self setDatabase:db];
        }
        
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSMutableString *colmunNames = [[NSMutableString alloc] init];
    NSMutableString *values = [[NSMutableString alloc] init];
    
    NSUInteger columnCounter = 0;

    char colCtrBuf[19];
    for (id object in self.row) {
        
        NSString *fieldName = self.columnKeys[columnCounter];
        MTDataColumn *column = self.columns[fieldName];
        MTDataType type = [[column columnType] integerValue];
        NSString *safeFieldName = [[self database] safeIdentifier:fieldName];
        
        if (columnCounter > 0) {
            [colmunNames appendString:@", "];
            [values appendString:@", "];
        }
        
        [colmunNames appendString:safeFieldName];
        
        MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType: type
                                                                                  fieldIndex: columnCounter
                                                                                       value: object];
        [[self binaryBindings] addObject:databinding];
        
        snprintf(colCtrBuf, 19, "?%u", (unsigned int)columnCounter + 1);
        NSString *columnValue = @(colCtrBuf);
        [values appendString:columnValue];
        
        columnCounter++;
    }

    NSMutableString *result = [NSMutableString stringWithString:@"INSERT INTO main."];
    [result appendString:self.tableName];
    [result appendString:@" ("];
    [result appendString:colmunNames];
    [result appendString:@") VALUES ("];
    [result appendString:values];
    [result appendString:@")"];
    return result;
}

- (BOOL)returnsResults {
    return NO;
}

- (BOOL)partOfTransactionSet {
    return YES;  //Can't use YES here, because insert is bound with different values on each run.
}

@end
