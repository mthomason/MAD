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

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *rowids;
@property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryCacheSelectRowIds

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        id key;

        key = [[NSNumber alloc] initWithShort: MADQuerySelectRowIds];
        self.rowids = object[key];
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
        NSString *tableName = object[key];
        self.tableName = tableName;
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
        NSArray *array = object[key];
        NSArray *sortDescriptors = [NSArray arrayWithArray:array];
        self.sortDescriptors = sortDescriptors;
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectColumns];
        NSDictionary *columns = object[key];
        self.columns = columns;
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT *, ROWID FROM %@ ", self.tableName];

    [sql appendString:[self whereClauseWithRowIds:self.rowids]];
    [sql appendString:[self orderByClauseWithSortDescriptors:self.sortDescriptors]];
    
    return sql;
}

- (MADQueryType)type {
    return MADQueryTypeCacheSelectRowIds;
}

@end
