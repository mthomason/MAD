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
    @property (nonatomic, strong) NSString *sql;
@end

@implementation MTQueryCacheSelectRowIds

- (instancetype)initWithTableName:(NSString *)tableName rowIDs:(NSArray *)rowIDs sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns {

    if (self = [super initWithObject:nil]) {
        NSString *whereClause = [MTQueryCacheSelectRowIds whereClauseWithRowIds:rowIDs];
        NSString *orderByClause = [MTQueryCacheSelectRowIds orderByClauseWithSortDescriptors:sortDescriptors andColumns:columns];
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ %@%@", tableName, whereClause, orderByClause];
        self.sql = sql;
    }
    return self;
}

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keyRowIDs = @(MTQuerySelectRowIds);
        NSNumber *keySelectTableName = @(MTQuerySelectTableName);
        NSNumber *keySortDescriptors = @(MTQuerySelectSortDescriptors);
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        
        NSArray *rowIDs = object[keyRowIDs];
        NSString *tableName = object[keySelectTableName];
        NSArray *sortDescriptors = object[keySortDescriptors];
        NSDictionary *columns = object[keyColumns];
        
        NSString *whereClause = [MTQueryCacheSelectRowIds whereClauseWithRowIds:rowIDs];
        NSString *orderByClause = [MTQueryCacheSelectRowIds orderByClauseWithSortDescriptors:sortDescriptors andColumns:columns];
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ %@%@", tableName, whereClause, orderByClause];
        self.sql = sql;

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return self.sql;
}

@end
