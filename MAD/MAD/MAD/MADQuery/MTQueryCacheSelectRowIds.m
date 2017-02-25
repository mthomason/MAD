//
//  MTQueryCacheRowIds.m
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectRowIds.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import "MADQuerySelectParameters.h"

@interface MTQueryCacheSelectRowIds ()
    @property (nonatomic, copy) NSString *sql;

@end

@implementation MTQueryCacheSelectRowIds

- (instancetype)initWithRowIDs:(NSArray *)rowIDs tableName:(NSString *)tableName
               sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns {
    if (self = [super init]) {
        NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ ", tableName];
        [sql appendString:[self whereClauseWithRowIds:rowIDs]];
        [sql appendString:[self orderByClauseWithSortDescriptors:sortDescriptors]];
        self.sql = sql;
    }
    return self;
}

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self = [super initWithObject:object]) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        id key;

        key = [[NSNumber alloc] initWithShort: MADQuerySelectRowIds];
        NSArray *rowIDs = object[key];
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
        NSString *tableName = object[key];
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
        NSArray *array = object[key];
        NSArray *sortDescriptors = [NSArray arrayWithArray:array];
        
        NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ ", tableName];
        [sql appendString:[self whereClauseWithRowIds:rowIDs]];
        [sql appendString:[self orderByClauseWithSortDescriptors:sortDescriptors]];
        self.sql = sql;
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return self.sql;
}

- (MADQueryType)type {
    return MADQueryTypeCacheSelectRowIds;
}

@end
