//
//  MTQueryCacheSelectLimitOffset.m
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectLimitOffset.h"

@interface MTQueryCacheSelectLimitOffset ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *columnKeys;
@property (nonatomic, strong) NSArray *sortDesc;

@property (nonatomic, strong) NSArray *whereClause;

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, assign) NSUInteger offset;

@end

@implementation MTQueryCacheSelectLimitOffset

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));

        NSNumber *limitO = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersLimit)];
        self.limit = limitO ? [limitO integerValue] : NSNotFound;

        NSNumber *offsetO = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersOffset)];
        self.offset = offsetO ? [offsetO integerValue] : NSNotFound;
        
        NSString *tableName = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersTableNames)];
        [self setTableName:tableName];
        
        NSArray *columnKeys = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersColumnKeys)];
        [self setColumnKeys:columnKeys];
        
        NSArray *sortDesc = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersSortDesc)];
        [self setSortDesc:sortDesc];
        
        NSArray *whereClause = [object objectForKey:@(MTQueryCacheSelectLimitOffsetParamatersWhere)];
        [self setWhereClause:whereClause];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    NSString *result = nil;
    
    
    if (self.limit == NSNotFound && self.offset == NSNotFound) {
        result = [self sqlQuery];
    } else if (self.offset == NSNotFound) {
        result = [self sqlQueryWithLimit:self.limit];
    } else {
        result = [self sqlQueryWithLimit:self.limit offset:self.offset];
    }
    return result;
}

- (BOOL)returnsResults {
    return YES;
}

- (NSString *)sqlQuery {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT "];
    
    NSAssert([[self columnKeys] count] != 0, @"Bad parameter data.");  // FIXME: Handle case where no columns.
    
    NSUInteger columnCounter = 0;
    for (NSString *key in [self columnKeys]) {
        if (columnCounter != 0) {
            [sql appendString:@", "];
        }
        [sql appendFormat:@"\"%@\"", key];
        columnCounter++;
    }
    [sql appendFormat:@", rowid FROM %@", [self tableName]];
    
    if ([[self sortDesc] count] > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        for (NSSortDescriptor *sortDescriptor in [self sortDesc]) {
            if (sortCounter != 0) [sql appendString:@", "];
            NSString *sortDirection = [sortDescriptor ascending] ? @"COLLATE LSASC" : @"COLLATE LSDESC";
            [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDirection];
            sortCounter++;
        }
    }
    
    // FIXME: Right now only handles equal case.
    if ([[self whereClause] count] > 0) {
        [sql appendString:@" WHERE "];
        NSUInteger counter = 0;
        for (NSDictionary *condition in [self whereClause]) {
            if (counter > 0) [sql appendString:@" AND "];
            NSString *columnHandle = [condition objectForKey:@"col"];
            NSString *columnValue = [condition objectForKey:@"val"];
            [sql appendFormat:@"%@ = %@", columnHandle, columnValue];
            counter++;
        }
    }
    
    return sql;
    
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit {
    return [[self sqlQuery] stringByAppendingFormat:@" LIMIT %ld ", (unsigned long)limit];
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
    return [[self sqlQueryWithLimit:limit] stringByAppendingFormat:@" OFFSET %ld ", (unsigned long)offset];
}

@end
