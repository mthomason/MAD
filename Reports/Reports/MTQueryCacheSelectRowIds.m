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
@property (nonatomic, strong) NSIndexSet *rowids;
@property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTQueryCacheSelectRowIds

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        self.rowids = [object objectForKey:@(MTQuerySelectRowIds)];
        
        NSString *tableName = [object objectForKey:@(MTQuerySelectTableName)];
        [self setTableName:tableName];
        
        NSArray *sortDescriptors = [NSArray arrayWithArray:[object objectForKey:@(MTQuerySelectSortDescriptors)]];
        [self setSortDescriptors:sortDescriptors];
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@  WHERE ", self.tableName];
    NSUInteger rowid = [[self rowids] firstIndex];
    BOOL firstTime = YES;
    while (rowid != NSNotFound) {
        if (firstTime == NO) {
            [sql appendString: @" OR "];
        }
        [sql appendFormat:@"rowid = %d", rowid];
        rowid = [[self rowids] indexGreaterThanIndex: rowid];
        firstTime = NO;
    }
    
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
    
    return sql;
}


@end
