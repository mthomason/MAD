//
//  MTQueryCacheSelectGroupKeys.m
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectGroupKeys.h"

@interface MTQueryCacheSelectGroupKeys ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSArray *predicates;
@property (nonatomic, assign) BOOL accending;

@end

@implementation MTQueryCacheSelectGroupKeys

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSString *tableName = [NSString stringWithString:[object objectForKey:@(MTQuerySelectTableName)]];
        [self setTableName:tableName];
        
        NSArray *predicates = [NSArray arrayWithArray:[object objectForKey:@(MTQuerySelectPredicates)]];
        [self setPredicates:predicates];
        
        NSArray *fieldKeys = [object objectForKey:@(MTQuerySelectFieldKeys)];
        NSString *columnName = [NSString stringWithString:[fieldKeys firstObject]];
        [self setColumnName:columnName];
        
        [self setAccending:[[object objectForKey:@(MTQuerySelectSortAccending)] boolValue]];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT DISTINCT %@ FROM %@", self.columnName, self.tableName];
    NSInteger i = 0;
    for (NSDictionary *predicate in [self predicates]) {
        NSString *left = [predicate objectForKey:@"c"];
        NSString *right = [predicate objectForKey:@"v"];
        if (i == 0) {
            [sql appendString:@" WHERE "];
        } else {
            [sql appendString:@" AND "];
        }
        [sql appendFormat:@"%@ = \"%@\"", left, right];
        i++;
    }

    [sql appendFormat:@" ORDER BY %@ %@", self.columnName, (self.accending ? @"COLLATE LSASC ASC" : @"COLLATE LSDESC DESC")];
    return sql;
}

@end
