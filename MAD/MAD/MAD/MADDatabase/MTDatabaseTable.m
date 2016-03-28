//
//  MNSDatabaseTable.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseTable.h"
#import <Foundation/NSString.h>

@interface MTDatabaseTable ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation MTDatabaseTable

- (instancetype)init {
    if (self = [super init]) {
        _name = nil;
    }
    return self;
}

- (instancetype)initWithTableName:(NSString *)tableName {
    if (self = [super init]) {
        _name = tableName.copy;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MTDatabaseTable *copy = [[[self class] allocWithZone:zone] initWithTableName:_name];
    copy.queryable = _queryable;
    return copy;
}

@end
