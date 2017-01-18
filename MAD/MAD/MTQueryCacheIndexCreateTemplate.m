//
//  MTQueryCacheIndexCreateTemplate.m
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheIndexCreateTemplate.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import "MTQueryCacheIndexCreateTypes.h"

@implementation MTQueryCacheIndexCreateTemplate {
    NSUInteger _groupCount;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheIndexDrop expects NSDictionary.");
        
        NSNumber *keyGroupCount = [[NSNumber alloc] initWithShort:MTQueryCacheIndexCreateIndexGroupCount];
        NSNumber *groupCount = object[keyGroupCount];
        _groupCount = groupCount.unsignedIntegerValue;
        
        self.queryObject = object;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {

    NSMutableString *sql;
    if (_groupCount > 0) {
        sql = [[NSMutableString alloc] initWithString:@"CREATE INDEX IF NOT EXISTS main.? ON ? ("];
        for (NSUInteger i = 0; i < _groupCount; i++) {
            
            if (i != 0) [sql appendString:@", ? ?"];
            else [sql appendString:@"? ?"];
        }
        [sql appendString:@" )"];
    }
    
    return sql;
}

- (BOOL)returnsResults { return NO; }

- (NSUInteger)parameterCount {
    return _groupCount * 2 + 2;
}

@end
