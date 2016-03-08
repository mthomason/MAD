//
//  MTQueryCacheSelectRowId.m
//  MAD
//
//  Created by Michael Thomason on 5/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectRowId.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

static NSString * const WildCard = @"*";
static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";
static NSString * const SqlFormat = @", %@";

@interface MTQueryCacheSelectRowId ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, copy) NSNumber *rowId;
@property (nonatomic, strong) NSArray *columnKeys;
@property (nonatomic, strong) NSString *columnNames;

@end

@implementation MTQueryCacheSelectRowId

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *key = @(MTQuerySelectFieldKeys);
        NSNumber *keyRowId = @(MTQuerySelectRowId);
        NSNumber *keyTableName = @(MTQuerySelectTableName);
        NSNumber *keyFieldDescriptors = @(MTQuerySelectFieldDescriptors);
        
        NSArray *columnKeys = object[key];
        if (columnKeys) {
            NSArray *ck = [[NSArray alloc] initWithArray:columnKeys];
            self.columnKeys = ck;
        }
        
        if (columnKeys.count > 0) {
            NSString *firstKey = columnKeys.firstObject;
            NSMutableString *columnNames = [[NSMutableString alloc] initWithString:firstKey];
            NSArray *columnKeysMinusFirst = [columnKeys subarrayWithRange:NSMakeRange(1, columnKeys.count - 1)];
            for (NSString *key in columnKeysMinusFirst) {
                [columnNames appendFormat:SqlDelimitorObject, key];
            }
            self.columnNames = columnNames;
        } else {
            self.columnNames = WildCard;
        }
 
        _rowId = ((NSNumber *)object[keyRowId]).copy;
        
        NSString *tableName = [[NSString alloc] initWithString: object[keyTableName]];
        self.tableName = tableName;
        
        NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithDictionary: object[keyFieldDescriptors]];
        self.columns = columns;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE rowid = %ld", self.columnNames, self.tableName, (long)self.rowId.integerValue];
}

@end
