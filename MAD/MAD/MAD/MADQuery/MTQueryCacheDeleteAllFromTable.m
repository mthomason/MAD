//
//  MTQueryCacheDeleteAllFromTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheDeleteAllFromTable.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import "MADQueryCacheDeleteAllFromTableParameters.h"

@interface MTQueryCacheDeleteAllFromTable ()

    @property (nonatomic, copy) NSString *tableName;

@end

@implementation MTQueryCacheDeleteAllFromTable

- (instancetype)initWithTableName:(NSString *)tableName {
    if (self = [super init]) {
        _tableName = tableName.copy;
    }
    return self;
}

- (instancetype)initWithObject:(NSDictionary *)object {
    if (self = [super init]) {
        NSNumber *keyMTQueryCacheDeleteAllFromTableTableName = @(MTQueryCacheDeleteAllFromTableTableName);
        NSString *tableName = object[keyMTQueryCacheDeleteAllFromTableTableName];
        _tableName = tableName.copy;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", self.tableName];
    return sql;
}

- (BOOL)returnsResults { return NO; }

- (MADQueryType)type {
    return MADQueryTypeCacheDeleteAllFromTable;
}

@end
