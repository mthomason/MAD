//
//  MTQueryCacheSelectLimitOffset.m
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectLimitOffset.h"
#import <MADFoundation/MADDataColumn.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheSelectLimitOffset ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSArray *columnKeys;
@property (nonatomic, strong) NSArray *sortDesc;

@property (nonatomic, strong) NSArray *whereClause;

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, assign) NSUInteger offset;

@property (nonatomic, assign) bool droprowid;

@end

@implementation MTQueryCacheSelectLimitOffset

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));

        NSNumber *limitO = object[@(MTQueryCacheSelectLimitOffsetParamatersLimit)];
        NSNumber *offsetO = object[@(MTQueryCacheSelectLimitOffsetParamatersOffset)];

        _limit = limitO ? limitO.unsignedIntegerValue : NSNotFound;     // Careful not to fuck this up!
        _offset = offsetO ? offsetO.unsignedIntegerValue : NSNotFound;  // Careful not to fuck this up!
        
        NSNumber *keyTableNames = @(MTQueryCacheSelectLimitOffsetParamatersTableNames);
        NSString *tableName = object[keyTableNames];
        _tableName = [[NSString alloc] initWithString: tableName];
        
        NSArray *columnKeys = object[@(MTQueryCacheSelectLimitOffsetParamatersColumnKeys)];
        _columnKeys = [[NSArray alloc] initWithArray:columnKeys];
        
        NSArray *sortDesc = object[@(MTQueryCacheSelectLimitOffsetParamatersSortDesc)];
        _sortDesc = [[NSArray alloc] initWithArray: sortDesc];
        
        NSArray *whereClause = object[@(MTQueryCacheSelectLimitOffsetParamatersWhere)];
        _whereClause = [[NSArray alloc] initWithArray: whereClause];
        
        NSDictionary *columns = object[@(MTQueryCacheSelectLimitOffsetParamatersColumns)];
        NSDictionary *c = [[NSDictionary alloc] initWithDictionary: columns];
        self.columns = c;
        
        NSNumber *dropRowid = object[@(MTQueryCacheSelectLimitOffsetParamatersDropRowid)];
        self.droprowid = dropRowid != nil ? dropRowid.boolValue : NO;
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
        
    if ([[self columnKeys] count] == 0) {
        [sql appendFormat:@" rowid FROM %@", [self tableName]];
    } else {

        NSUInteger columnCounter = 0;
        for (NSString *key in [self columnKeys]) {
            if (columnCounter != 0) {
                [sql appendString:@", "];
            }
            [sql appendFormat:@"\"%@\"", key];
            columnCounter++;
        }
        if (self.droprowid) {
            [sql appendFormat:@" FROM %@", [self tableName]];
        } else {
            [sql appendFormat:@", rowid FROM %@", [self tableName]];
        }
    }
    
    if ([[self sortDesc] count] > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        for (NSSortDescriptor *sortDescriptor in [self sortDesc]) {
            if (sortCounter != 0) [sql appendString:@", "];
            
            MADDataColumn *dataColumn = nil;
            if ([self columns]) {
                dataColumn = [self columns][[sortDescriptor key]];
            }
            NSString *sortDescription = [MTDatabaseSqlite3 sortDescForColumnType: dataColumn.nativeType
                                                                       ascending: sortDescriptor.ascending];
            
            [sql appendFormat:@"%@ %@", [sortDescriptor key], sortDescription];
            sortCounter++;
        }
    }
    
    // FIXME: Right now only handles equal case.
    if ([[self whereClause] count] > 0) {
        [sql appendString:@" WHERE "];
        NSUInteger counter = 0;
        for (NSDictionary *condition in [self whereClause]) {
            if (counter > 0) [sql appendString:@" AND "];
            NSString *columnHandle = condition[MTQueryKeyPredicateColumn];
            NSString *columnValue = condition[MTQueryKeyPredicateValue];
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
