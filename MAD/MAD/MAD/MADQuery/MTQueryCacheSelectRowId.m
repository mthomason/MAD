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
#import "MADQuerySelectParameters.h"

static NSString * const WildCard = @"*";
static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";
static NSString * const SqlFormat = @", %@";

@interface MTQueryCacheSelectRowId ()

@end

@implementation MTQueryCacheSelectRowId {
    NSString *_sql;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *key = [[NSNumber alloc] initWithShort: MADQuerySelectFieldKeys];
        NSNumber *keyRowId = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
        NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
        
        NSArray *columnKeys = object[key];
        
        NSString *columnNames = columnKeys.count > 0 ? [columnKeys componentsJoinedByString:@", "] : WildCard;
        
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@ WHERE rowid = %ld",
                         columnNames, object[keyTableName], (long)((NSNumber *)object[keyRowId]).integerValue];;
        _sql = sql;
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return _sql;
}

@end
