//
//  MTQueryCacheRowIds.m
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectRowIds.h"

@interface MTQueryCacheSelectRowIds ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *rowids;
@property (nonatomic, strong) NSArray *sortDescriptors;

//- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQueryCacheSelectRowIds

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        self.rowids = object[@(MTQuerySelectRowIds)];
        
        NSString *tableName = object[@(MTQuerySelectTableName)];
        [self setTableName:tableName];
        
        NSArray *sortDescriptors = [NSArray arrayWithArray:object[@(MTQuerySelectSortDescriptors)]];
        [self setSortDescriptors:sortDescriptors];
        
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        NSDictionary *columns = object[keyColumns];
        [self setColumns:columns];
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * _Nullable *)error {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT *, ROWID FROM %@ ", self.tableName];

    [sql appendString:[self whereClauseWithRowIds:[self rowids]]];
    [sql appendString:[self orderByClauseWithSortDescriptors:[self sortDescriptors]]];
    
    return sql;
}

@end
