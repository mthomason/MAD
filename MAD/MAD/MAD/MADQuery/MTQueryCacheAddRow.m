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
#import <MADFoundation/MADDataColumn.h>
#import "MTDatabaseDataBinding.h"
#import "MTDatabaseConnection.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"

static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";

@interface MTQueryCacheAddRow ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;

@property (nonatomic, strong) NSString *sqlPreProcessColumnNames;

@end

@implementation MTQueryCacheAddRow

@dynamic columns;

- (void)setDatabase:(MTDatabase *)database {
    [super setDatabase:database];
    NSString *c = [self columnNames];
    NSString *sqlColumnNames = [NSString stringWithString:c];
    self.sqlPreProcessColumnNames = sqlColumnNames;
}

- (NSString *)columnNames {
    NSMutableString *colmunNames = [[NSMutableString alloc] init];
    
    NSUInteger columnCount = self.columnKeys.count;
    for (NSUInteger columnCounter=0; columnCounter<columnCount; columnCounter++) {
        
        @autoreleasepool {
            
            NSString * __weak fieldName = self.columnKeys[columnCounter];
            NSString *safeFieldName = [self.database safeIdentifier:fieldName];
            if (columnCounter > 0) {
                [colmunNames appendFormat:SqlDelimitorObject, safeFieldName];
            } else {
                [colmunNames appendString:safeFieldName];
            }
        }
    }
    return colmunNames;
}

- (instancetype)initWithColumnKeys:(NSArray *)columnKeys columns:(NSDictionary *)columns andTableName:(NSString *)tableName {
    if (self = [super initWithObject:nil]) {

        NSString *name = [[NSString alloc] initWithString:tableName];
        self.tableName = name;
        
        NSDictionary *cols = [[NSDictionary alloc] initWithDictionary:columns];
        self.columns = cols;
        
        NSArray *keys = [[NSArray alloc] initWithArray:columnKeys];
        self.columnKeys = keys;
        
    }
    return self;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
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
        
        self.url = url;
        self.tableName = tableName;
        self.rowData = row;
        self.columns = columns;
        self.columnKeys = columnKeys;

        if (url != nil) {
            MTDatabaseConnection *connection = [MTDatabaseConnection newDatabaseConnectionForUrl:url];
            MTDatabase *db = [MTDatabase newDatabaseWithConnection:connection];
            NSAssert([db isKindOfClass:[MTDatabaseSqlite3 class]], @"Only allow Sqlite3. Fix this sometime.");
            self.database = db;
        }
        
        self.queryObject = object;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSMutableString *values = [[NSMutableString alloc] init];
    
    NSUInteger columnCounter = 0;

    char colCtrBuf[19];
    NSArray *row = self.rowData;
    NSMutableArray *binaryBindings = [[NSMutableArray alloc] initWithCapacity:row.count];
    for (id object in row) {
        
        @autoreleasepool {
            
            NSString * __weak fieldName = self.columnKeys[columnCounter];
            MADDataColumn *  __weak column = self.columns[fieldName];
            
            if (columnCounter > 0) {
                [values appendString:SqlDelimitor];
            }
            
            
            MTDatabaseDataBinding * databinding = [[MTDatabaseDataBinding alloc] initWithDataType: column.columnType.unsignedIntegerValue
                                                                                                       fieldIndex: columnCounter
                                                                                                            value: object];
            [binaryBindings addObject:databinding];
            
            snprintf(colCtrBuf, 19, "?%u", (unsigned int)columnCounter + 1);
            NSString *columnValue = @(colCtrBuf);
            [values appendString:columnValue];
        }
        
        columnCounter++;
    }
    self.binaryBindings = binaryBindings;
    
    NSString * __autoreleasing result = [[NSString alloc] initWithFormat:@"INSERT INTO main.%@ (%@) VALUES (%@)", self.tableName, self.sqlPreProcessColumnNames, values];
    return result;
}

- (BOOL)returnsResults {
    return NO;
}

- (BOOL)partOfTransactionSet {
    return YES;  //Can't use YES here, because insert is bound with different values on each run.
}

@end
