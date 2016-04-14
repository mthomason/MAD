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
static NSString * const SqlFormat = @"SELECT %@ FROM %@ WHERE rowid = %ld";

@interface MTQueryCacheSelectRowId ()

    @property (nonatomic, strong) NSString *sql;

@end

@implementation MTQueryCacheSelectRowId

- (instancetype)initWithTableName:(NSString *)tableName rowID:(NSUInteger)rowID columnKeys:(NSArray *)columnKeys {

    if (self = [super initWithObject:nil]) {
        NSString * __weak columnName = columnKeys.count > 0 ? columnKeys.firstObject : WildCard;
        NSString *sql = [[NSString alloc] initWithFormat:SqlFormat, columnName, tableName, (long)rowID];
        self.sql = sql;
    }
    return self;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *key = @(MTQuerySelectFieldKeys);
        NSNumber *keyRowId = @(MTQuerySelectRowId);
        NSNumber *keyTableName = @(MTQuerySelectTableName);
        
        NSArray *columnKeys = object[key];
        NSString *tableName = object[keyTableName];
        NSUInteger rowID = ((NSNumber *)object[keyRowId]).unsignedIntegerValue;

        NSString * __weak columnName = columnKeys.count > 0 ? columnKeys.firstObject : WildCard;
        NSString *sql = [[NSString alloc] initWithFormat:SqlFormat, columnName, tableName, (long)rowID];
        self.sql = sql;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return self.sql;
}

@end
