//
//  MTQueryCacheSelectGroupKeys.m
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectGroupKeys.h"
#import <MADFoundation/MADDataColumn.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import "MTDatabaseSqlite3.h"

static NSString * const JoinPredicateWhere = @" WHERE ";

@interface MTQueryCacheSelectGroupKeys ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, assign) BOOL accending;

@property (nonatomic, strong) NSString *sqlSpeedSorting;
@property (nonatomic, strong) NSString *sqlSpeedPredicate;

@end

@implementation MTQueryCacheSelectGroupKeys

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keySelectTableName = @(MTQuerySelectTableName);
        NSString *selectTableName = object[keySelectTableName];
        NSString *tableName = [NSString stringWithString:selectTableName];
        self.tableName = tableName;
        
        NSNumber *keySelectPredicates = @(MTQuerySelectPredicates);
        
        NSMutableString *sqlPredicate = [[NSMutableString alloc] initWithString:JoinPredicateWhere];
        int i = 0;
        NSArray * __weak selectPredicates = object[keySelectPredicates];
        for (NSDictionary *predicate in selectPredicates) {
            
            NSString *left = predicate[MTQueryKeyPredicateColumn];
            NSString *right = predicate[MTQueryKeyPredicateValue];
            if (i > 0) {
                [sqlPredicate appendString:@" AND "];
            }
            [sqlPredicate appendFormat:@"%@ = \"%@\"", left, right];
            i++;
        }
        self.sqlSpeedPredicate = sqlPredicate;
        
        NSNumber *keySelectFieldNames = @(MTQuerySelectFieldKeys);
        NSArray *fieldNames = object[keySelectFieldNames];
        NSString *columnName = fieldNames.firstObject;
        self.columnName = columnName;
        
        NSNumber *keySelectSortAccending = @(MTQuerySelectSortAccending);
        NSNumber *sortValue = object[keySelectSortAccending];
        self.accending = sortValue.boolValue;
        
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        NSDictionary * __weak columns = object[keyColumns];
        MADDataColumn * __weak dataColumn = columns[columnName];

        NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);

        NSString *sqlSpeedSortingDescription = [MTDatabaseSqlite3 sortDescForColumnType:dataColumn.nativeColumnType ascending:self.accending];
        NSString *sqlSpeedSort = [NSString stringWithString:sqlSpeedSortingDescription];
        self.sqlSpeedSorting = sqlSpeedSort;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return [NSString stringWithFormat:@"SELECT DISTINCT %@ FROM %@ %@ ORDER BY %@ %@", self.columnName, self.tableName, self.sqlSpeedPredicate, self.columnName, self.sqlSpeedSorting];
}

@end
