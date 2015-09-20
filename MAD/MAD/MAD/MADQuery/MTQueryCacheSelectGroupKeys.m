//
//  MTQueryCacheSelectGroupKeys.m
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectGroupKeys.h"
#import <MADFoundation/MTDataColumn.h>
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheSelectGroupKeys ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSArray *predicates;
@property (nonatomic, assign) BOOL accending;

@end

@implementation MTQueryCacheSelectGroupKeys

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSString *tableName = [NSString stringWithString:object[@(MTQuerySelectTableName)]];
        [self setTableName:tableName];
        
        NSArray *predicates = [NSArray arrayWithArray:object[@(MTQuerySelectPredicates)]];
        [self setPredicates:predicates];
        
        NSArray *fieldKeys = object[@(MTQuerySelectFieldKeys)];
        NSString *columnName = [NSString stringWithString:[fieldKeys firstObject]];
        [self setColumnName:columnName];
        
        [self setAccending:[object[@(MTQuerySelectSortAccending)] boolValue]];
        
        NSNumber *keyColumns = @(MTQuerySelectColumns);
        NSDictionary *columns = object[keyColumns];
        if (columns) {
            NSDictionary *c = [NSDictionary dictionaryWithDictionary:columns];
            [self setColumns:c];
        }
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT DISTINCT %@ FROM %@", self.columnName, self.tableName];
    NSInteger i = 0;
    for (NSDictionary *predicate in [self predicates]) {
        NSString *left = predicate[MTQueryKeyPredicateColumn];
        NSString *right = predicate[MTQueryKeyPredicateValue];
        if (i == 0) {
            [sql appendString:@" WHERE "];
        } else {
            [sql appendString:@" AND "];
        }
        [sql appendFormat:@"%@ = \"%@\"", left, right];
        i++;
    }

    MTDataColumn *dataColumn = nil;
    if ([self columns]) {
        dataColumn = [self columns][self.columnName];
    }
    NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
    NSString *sortDirection = [MTDatabaseSqlite3 sortDescForColumnType:[[dataColumn nativeColumnType] integerValue] ascending:self.accending];
    
    [sql appendFormat:@" ORDER BY %@ %@", self.columnName, sortDirection];
    return sql;
}

@end
