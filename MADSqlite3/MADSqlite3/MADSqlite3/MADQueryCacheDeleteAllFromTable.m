//
//  MTQueryCacheDeleteAllFromTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheDeleteAllFromTable.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <MADAPI/MADQueryType.h>
#import "MADQueryCacheDeleteAllFromTableParameters.h"

@interface MADQueryCacheDeleteAllFromTable ()

    @property (nonatomic, copy) NSString *tableName;

@end

@implementation MADQueryCacheDeleteAllFromTable

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

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM %@", self.tableName];
    return sql;
}

- (BOOL)returnsResults { return NO; }

- (MADQueryType)type {
    return MADQueryTypeCacheDeleteAllFromTable;
}

@end
