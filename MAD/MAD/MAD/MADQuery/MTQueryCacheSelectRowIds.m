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

@interface MTQueryCacheSelectRowIds ()

    @property (nonatomic, strong) NSString *tableName;
    @property (nonatomic, strong) NSArray *rowids;
    @property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryCacheSelectRowIds

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keyRowIDs = @(MTQuerySelectRowIds);
        NSNumber *keySelectTableName = @(MTQuerySelectTableName);
        NSNumber *keySortDescriptors = @(MTQuerySelectSortDescriptors);
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        
        self.rowids = object[keyRowIDs];

        NSString *tableName = object[keySelectTableName];
        self.tableName = tableName;
        
        NSArray *sortDescriptors = [NSArray arrayWithArray:object[keySortDescriptors]];
        self.sortDescriptors = sortDescriptors;
        
        NSDictionary *columns = object[keyColumns];
        self.columns = columns;
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSString *whereClause = [MTQueryCacheSelectRowIds whereClauseWithRowIds:self.rowids];
    NSString *orderByClause = [MTQueryCacheSelectRowIds orderByClauseWithSortDescriptors:self.sortDescriptors andColumns:self.columns];
    NSString *result = [[NSString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ %@%@", self.tableName, whereClause, orderByClause];
    return result;
}

@end
