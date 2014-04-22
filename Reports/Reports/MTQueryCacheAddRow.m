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
#import "MTDatabaseConnection.h"
#import "MTDatabase.h"
#import "MTDataColumn.h"
#import "MTDatabaseField.h"
#import "MTDatabaseDataBinding.h"

@interface MTQueryCacheAddRow ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *row;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;

@end

@implementation MTQueryCacheAddRow

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheAddRow expects NSDictionary.");
        
        NSNumber *keyMTQueryCacheAddRowUrl = @(MTQueryCacheAddRowUrl);
        NSNumber *keyMTQueryCacheAddRowData = @(MTQueryCacheAddRowData);
        NSNumber *keyMTQueryCacheAddRowColumns = @(MTQueryCacheAddRowColumns);
        NSNumber *keyMTQueryCacheAddRowColumnKeys = @(MTQueryCacheAddRowColumnKeys);
        NSNumber *keyMTQueryCacheAddRowTableName = @(MTQueryCacheAddRowTableName);
        
        NSURL *url = [object objectForKey:keyMTQueryCacheAddRowUrl];
        NSArray *row = [object objectForKey:keyMTQueryCacheAddRowData];
        NSDictionary *columns = [object objectForKey:keyMTQueryCacheAddRowColumns];
        NSArray *columnKeys = [object objectForKey:keyMTQueryCacheAddRowColumnKeys];
        NSString *tableName = object[keyMTQueryCacheAddRowTableName];
        
        [self setUrl:url];
        [self setTableName:tableName];
        [self setRow:row];
        [self setColumns:columns];
        [self setColumnKeys:columnKeys];

        MTDatabaseConnection *connection = [MTDatabaseConnection databaseConnectionFactory:url];
        MTDatabase *db = [MTDatabase databaseFactory:connection];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSMutableString *colmunNames = [[NSMutableString alloc] init];
    NSMutableString *values = [[NSMutableString alloc] init];
    
    
    NSUInteger columnCounter = 0;
    
    for (id object in [self row]) {
        NSString *fieldName = [self columnKeys][columnCounter];
        MTDataColumn *column = [self columns][fieldName];
        NSString *columnValue = nil;
        MTDataType type = [[column columnType] integerValue];
        NSString *safeFieldName = [[self database] safeIdentifier:fieldName];
        
        if (columnCounter > 0) {
            [colmunNames appendString:@", "];
            [values appendString:@", "];
        }
        
        [colmunNames appendString:safeFieldName];
        switch (type) {
            case MTDataTypeBit:
            case MTDataTypeInteger:
            case MTDataTypeShort:
            case MTDataTypeLong:
            case MTDataTypeLongLong:
            case MTDataTypeInt24:
            case MTDataTypeEnum: {
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeInteger
                                                                                          fieldIndex:columnCounter
                                                                                               value:object];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];
                break;
            }
            case MTDataTypeSet:
            case MTDataTypeTime:
            case MTDataTypeTimeStamp:
            case MTDataTypeYear:
            case MTDataTypeDate:
            case MTDataTypeDateTime:
            case MTDataTypeString:
            case MTDataTypeVarChar:
            case MTDataTypeGeometry: {
                
                
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeString
                                                                                          fieldIndex:columnCounter
                                                                                               value:object];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];
                break;
            }
            case MTDataTypeImage:
            case MTDataTypeBlob: {
                
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeBlob
                                                                                          fieldIndex:columnCounter
                                                                                               value:object];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];
                break;
            }
            case MTDataTypeFloat: {
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeFloat
                                                                                          fieldIndex:columnCounter
                                                                                               value:object];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];
                break;
            }
            case MTDataTypeDouble:
            case MTDataTypeDecimal:
            case MTDataTypeNumber: {
                
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeDouble
                                                                                          fieldIndex:columnCounter
                                                                                               value:object];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];
                break;
            }
            case MTDataTypeUnknown:
            default: {
                NSString *safeObject = [NSString stringWithFormat:@"%@", object];
                MTDatabaseDataBinding *databinding = [[MTDatabaseDataBinding alloc] initWithDataType:MTDataTypeString
                                                                                          fieldIndex:columnCounter
                                                                                               value:safeObject];
                [[self binaryBindings] addObject:databinding];
                columnValue = [NSString stringWithFormat: @"?%d", columnCounter + 1];

                break;
            }
        }
        [values appendString:columnValue];
        
        columnCounter++;
    }
    
    return [NSString stringWithFormat:@"INSERT INTO main.%@ (%@) VALUES (%@)", [self tableName], colmunNames, values];
}

- (BOOL)returnsResults {
    return NO;
}

@end
