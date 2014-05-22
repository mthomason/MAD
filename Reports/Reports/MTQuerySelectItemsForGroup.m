//
//  MTQuerySelectItemsForGroup.m
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuerySelectItemsForGroup.h"

@interface MTQuerySelectItemsForGroup ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, strong) NSArray *columnKeys;
@property (nonatomic, strong) NSArray *whereClause;

@end

@implementation MTQuerySelectItemsForGroup

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSString *tableName = [NSString stringWithString:[object objectForKey:@(MTQuerySelectTableName)]];
        [self setTableName:tableName];
        
        NSArray *sortDescriptors = [NSArray arrayWithArray:[object objectForKey:@(MTQuerySelectSortDescriptors)]];
        [self setSortDescriptors:sortDescriptors];
        
        NSArray *columnKeys = [object objectForKey:@(MTQuerySelectFieldKeys)];
        [self setColumnKeys:columnKeys];
        
        NSArray *whereClause = [object objectForKey:@(MTQuerySelectPredicates)];
        [self setWhereClause:whereClause];
  
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {

    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT "];
    
    NSUInteger columnCounter = 0;
    
    for (NSString *key in [self columnKeys]) {
        
        if (columnCounter != 0) {
            [sql appendString:@", "];
        }
        [sql appendFormat:@"\"%@\"", key];
        columnCounter++;
    }
    [sql appendFormat:@", rowid FROM %@", [self tableName]];

    if ([[self sortDescriptors] count] > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        
        for (NSSortDescriptor *sortDescriptor in [self sortDescriptors]) {
            if (sortCounter != 0) [sql appendString:@", "];
            NSString *sortDirection = [sortDescriptor ascending] ? @"COLLATE LSASC" : @"COLLATE LSDESC";
            [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDirection];
            sortCounter++;
        }
    }

    if ([[self whereClause] count] > 0) {
        [sql appendString:@" WHERE "];
        NSUInteger counter = 0;
        for (NSDictionary *condition in [self whereClause]) {
            [sql appendString: (counter == 0) ? @" WHERE " : @" AND "];
            NSString *columnHandle = [condition objectForKey:@"c"];
            NSString *columnValue = [condition objectForKey:@"v"];
            [sql appendFormat:@"%@ = \"%@\"", columnHandle, columnValue];
            counter++;
        }
    }
    
    return sql;
}

@end
