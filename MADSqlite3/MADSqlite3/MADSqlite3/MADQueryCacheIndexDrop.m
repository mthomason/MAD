//
//  MTQueryCacheIndexDrop.m
//  MAD
//
//  Created by Michael Thomason on 5/7/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheIndexDrop.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import "MADQueryCacheIndexDropParameters.h"
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheIndexDrop ()

@end

@implementation MADQueryCacheIndexDrop {
    NSString *_sql;
}

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheIndexDrop expects NSDictionary.");
        NSNumber *keyIndexName = [[NSNumber alloc] initWithUnsignedInteger: MTQueryCacheIndexDropIndexName];
        NSString *result = [[NSString alloc] initWithFormat:@"DROP INDEX IF EXISTS main.%@", object[keyIndexName]];
        _sql = result;
        
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return _sql;
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCacheIndexDropParameters;
}

@end
