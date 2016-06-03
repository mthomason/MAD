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
#import <Foundation/NSArray.h>
#import <MADFoundation/MADDataColumn.h>
#import "MTDatabaseDataBinding.h"
#import "MTDatabaseConnection.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"
#import "MADQueryCacheAddRowParameters.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <stdio.h>
#import "madlib.h"

static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";

@interface MTQueryCacheAddRow ()
    @property (nonatomic, weak, readwrite) MTDatabase *cacheDatabase;

    @property (nonatomic, readwrite, copy) NSString *tableName;
    @property (nonatomic, readwrite, weak) NSDictionary *columns;
    @property (nonatomic, readwrite, weak) NSArray *columnKeys;

    @property (nonatomic, readwrite, strong) NSString *sqlPreProcessColumnNames;

@end

@implementation MTQueryCacheAddRow

@dynamic columns;

- (void)setDatabase:(MTDatabase *)database {
    super.database = database;
    NSString *c = [self columnNames];
    NSString *sqlColumnNames = [NSString stringWithString:c];
    self.sqlPreProcessColumnNames = sqlColumnNames;
}

- (NSString *)columnNames {
    NSMutableString *colmunNames = [[NSMutableString alloc] init];
    
    NSUInteger columnCount = self.columnKeys.count;
    NSString * __weak fieldName;
    for (NSUInteger columnCounter=0; columnCounter<columnCount; columnCounter++) {
        fieldName = self.columnKeys[columnCounter];
        
        MADSafeQueryField *safeFieldName = [self.cacheDatabase newSafeIdentifier:fieldName];
        if (columnCounter > 0) {
            [colmunNames appendFormat:SqlDelimitorObject, safeFieldName];
        } else {
            [colmunNames appendString:safeFieldName];
        }
        
    }
    return colmunNames;
}

- (instancetype)initWithColumnKeys:(NSArray *)columnKeys columns:(NSDictionary *)columns
                      andTableName:(NSString *)tableName forDatabase:(MTDatabase *)database {

    if (self = [super initWithObject:nil]) {
    
        self.cacheDatabase = database;
        
        NSArray *keys = [[NSArray alloc] initWithArray:columnKeys];
        self.columnKeys = keys;

        NSString *sqlColumnNames = [self columnNames];
        self.sqlPreProcessColumnNames = sqlColumnNames.copy;
    
        NSString *name = [[NSString alloc] initWithString:tableName];
        self.tableName = name;
        
        NSDictionary *cols = [[NSDictionary alloc] initWithDictionary:columns];
        self.columns = cols;
        
    }
    return self;
}

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddRow expects NSDictionary.");
        
        id keyAddRowData = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowData];
        NSArray * __weak row = object[keyAddRowData];
        self.rowData = row;
        
        id keyColumns = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowColumns];
        NSDictionary * __weak columns = object[keyColumns];
        self.columns = columns;
        
        id keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowColumnKeys];
        NSArray * __weak columnKeys = object[keyColumnKeys];
        self.columnKeys = columnKeys;

        id keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowTableName];
        NSString * __weak tableName = object[keyTableName];
        self.tableName = tableName.copy;
        
        id keyRowUrl = [[NSNumber alloc] initWithShort: MTQueryCacheAddRowUrl];
        NSURL * __weak url = object[keyRowUrl];
        
        if (url != nil) {
            id connection = [MTDatabaseConnection newDatabaseConnectionForUrl:url];
            MTDatabase *db = [MTDatabase newDatabaseWithConnection:connection];
            NSAssert([db isKindOfClass:[MTDatabaseSqlite3 class]], @"Only allow Sqlite3. Fix this sometime.");
            self.cacheDatabase = db;
        }
        
        self.queryObject = object;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    [super getSqlWithError:error];
    
    NSMutableString *values = [[NSMutableString alloc] init];
    
    NSUInteger columnCounter = 0;

    char buf[12];

    NSArray *row = self.rowData;
    
    [self.binaryBindings removeAllObjects];
    
    for (id object in row) {
        
        @autoreleasepool {
            
            NSString * __weak fieldName = self.columnKeys[columnCounter];
            MADDataColumn *  __weak column = self.columns[fieldName];
            
            if (columnCounter > 0) {
                [values appendString:SqlDelimitor];
            }
            
            id databinding = [[MTDatabaseDataBinding alloc] initWithDataType: column.type
                                                                  fieldIndex: columnCounter
                                                                       value: object];
            [self.binaryBindings addObject:databinding];
            buf[0] = '?';
            ultoa((unsigned int)columnCounter + 1, &*(buf+1));
            char *ptr = buf;

            
            NSString *columnValue = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
            [values appendString:columnValue];
        }
        
        columnCounter++;
    }
    
    NSString *result = [[NSString alloc] initWithFormat:@"INSERT INTO main.%@ (%@) VALUES (%@)", self.tableName, self.sqlPreProcessColumnNames, values];
    return result;
}

- (BOOL)returnsResults {
    return NO;
}

- (BOOL)partOfTransactionSet {
    return YES;  //Can't use YES here, because insert is bound with different values on each run.
}

@end
