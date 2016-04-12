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

static NSString * const JoinPredicateWhere =    @" WHERE ";
static NSString * const SqlAnd =                @" AND ";

@interface MTQueryCacheSelectGroupKeys ()
    @property (nonatomic, strong) NSString *sql;
@end

@implementation MTQueryCacheSelectGroupKeys

- (instancetype)initWithTableName:(NSString *)tableName selectPredicates:(NSArray *)selectPredicates fieldNames:(NSArray *)fieldNames accending:(bool)accending columns:(NSDictionary *)columns {

    if (self = [super init]) {
    
        NSMutableString *sqlPredicate = [[NSMutableString alloc] initWithString:JoinPredicateWhere];
        int i = 0;
        for (NSDictionary *predicate in selectPredicates) {
            
            NSString * __weak left = predicate[MTQueryKeyPredicateColumn];
            NSString * __weak right = predicate[MTQueryKeyPredicateValue];
            if (i > 0) {
                [sqlPredicate appendString:SqlAnd];
            }
            [sqlPredicate appendFormat:@"%@ = \"%@\"", left, right];
            i++;
        }
        
        NSString *columnName = fieldNames.firstObject;
        MADDataColumn * __weak dataColumn = columns[columnName];
        
        NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
        
        NSString *sqlSpeedSortingDescription = [MTDatabaseSqlite3 sortDescForColumnType:dataColumn.columnType ascending:accending];
        NSString *sqlSpeedSort = [NSString stringWithString:sqlSpeedSortingDescription];
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT DISTINCT %@ FROM %@ %@ ORDER BY %@ %@", columnName, tableName, sqlPredicate, columnName, sqlSpeedSort];
        self.sql = sql;
    }
    return self;

}

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keySelectTableName = @(MTQuerySelectTableName);
        NSString * __weak tableName = object[keySelectTableName];
        
        NSNumber *keySelectPredicates = @(MTQuerySelectPredicates);
        
        NSMutableString *sqlPredicate = [[NSMutableString alloc] initWithString:JoinPredicateWhere];
        int i = 0;
        NSArray * __weak selectPredicates = object[keySelectPredicates];
        for (NSDictionary *predicate in selectPredicates) {
            
            NSString *left = predicate[MTQueryKeyPredicateColumn];
            NSString *right = predicate[MTQueryKeyPredicateValue];
            if (i > 0) {
                [sqlPredicate appendString:SqlAnd];
            }
            [sqlPredicate appendFormat:@"%@ = \"%@\"", left, right];
            i++;
        }
        
        NSNumber *keySelectFieldNames = @(MTQuerySelectFieldKeys);
        NSArray *fieldNames = object[keySelectFieldNames];
        NSString *columnName = fieldNames.firstObject;
        
        NSNumber *keySelectSortAccending = @(MTQuerySelectSortAccending);
        NSNumber *sortValue = object[keySelectSortAccending];
        bool accending = sortValue.boolValue ? YES : NO;
        
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        NSDictionary * __weak columns = object[keyColumns];
        MADDataColumn * __weak dataColumn = columns[columnName];

        NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);

        NSString *sqlSpeedSortingDescription = [MTDatabaseSqlite3 sortDescForColumnType:dataColumn.columnType ascending:accending];
        NSString *sqlSpeedSort = [NSString stringWithString:sqlSpeedSortingDescription];
        
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT DISTINCT %@ FROM %@ %@ ORDER BY %@ %@", columnName, tableName, sqlPredicate, columnName, sqlSpeedSort];
        self.sql = sql;
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error { return self.sql; }

@end
