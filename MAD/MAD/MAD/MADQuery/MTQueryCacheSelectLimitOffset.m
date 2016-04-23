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
#import <dispatch/dispatch.h>
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheSelectLimitOffset ()

    @property (nonatomic, copy) NSString *tableName;
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

        id keyLimit = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersLimit];
        NSNumber *limitO = object[keyLimit];
        
        id keyOffset = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersOffset];
        NSNumber *offsetO = object[keyOffset];

        _limit = limitO ? limitO.unsignedIntegerValue : NSNotFound;     // Careful not to fuck this up!
        _offset = offsetO ? offsetO.unsignedIntegerValue : NSNotFound;  // Careful not to fuck this up!
        
        NSNumber *keyTableNames = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
        NSString * __weak tableName = object[keyTableNames];
        _tableName = tableName.copy;
        
        NSNumber *keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
        NSArray *columnKeys = object[keyColumnKeys];
        _columnKeys = [[NSArray alloc] initWithArray:columnKeys];
        
        NSNumber *keySortDesc = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];
        NSArray *sortDesc = object[keySortDesc];
        _sortDesc = [[NSArray alloc] initWithArray: sortDesc];
        
        NSNumber *keyWhere = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersWhere];
        NSArray *whereClause = object[keyWhere];
        _whereClause = [[NSArray alloc] initWithArray: whereClause];
        
        NSNumber *keyColumns = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumns];
        NSDictionary *columns = object[keyColumns];
        NSDictionary *c = [[NSDictionary alloc] initWithDictionary: columns];
        self.columns = c;
        
        NSNumber *keyRowID = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersDropRowid];
        NSNumber *dropRowid = object[keyRowID];
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

    NSString *(^sqlSelect)(NSString *, NSArray *, bool);
    sqlSelect = ^(NSString *tableName, NSArray *columnKeys, bool includingRowID) {
        NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT "];
        if (columnKeys.count == 0) {
            [sql appendFormat:@" rowid FROM %@", tableName];
        } else {
            
            NSUInteger columnCounter = 0;
            for (NSString *key in columnKeys) {
                if (columnCounter != 0) {
                    [sql appendString:@", "];
                }
                [sql appendFormat:@"\"%@\"", key];
                columnCounter++;
            }
            if (includingRowID) {
                [sql appendFormat:@" FROM %@", tableName];
            } else {
                [sql appendFormat:@", rowid FROM %@", tableName];
            }
        }
        return sql;
    };

    NSString *(^sqlOrderBy)(NSArray *, NSDictionary *);
    sqlOrderBy = ^(NSArray *sortDesc, NSDictionary *columns) {
    
        if (sortDesc.count > 0) {
            NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
            NSUInteger sortCounter = 0;
            [sql appendString:@" ORDER BY "];
            for (NSSortDescriptor *sortDescriptor in sortDesc) {
                if (sortCounter != 0) [sql appendString:@", "];
                
                MADDataColumn *dataColumn = nil;
                if (columns) { dataColumn = columns[sortDescriptor.key]; }
                MADSqlite3SortDescription *sortDescription;
                sortDescription = [MTDatabaseSqlite3 newSqlite3SortDescriptionForColumnType: dataColumn.nativeType
                                                                                  ascending: sortDescriptor.ascending];
                [sql appendFormat:@"%@ %@", sortDescriptor.key, sortDescription];
                sortCounter++;
            }
            return (NSString *)sql;
        } else {
            return @"";
        }
        
    };
    
    NSString *(^sqlWhere)(NSArray *);
    sqlWhere = ^(NSArray *whereClause) {
        if (whereClause.count > 0) {
            
            NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
            [sql appendString:@" WHERE "];
            
            NSUInteger counter = 0;
            for (NSDictionary *condition in whereClause) {
                if (counter > 0) [sql appendString:@" AND "];
                
                NSString * __weak columnHandle = condition[MTQueryKeyPredicateColumn];
                NSString * __weak columnValue = condition[MTQueryKeyPredicateValue];
                [sql appendFormat:@"%@ = %@", columnHandle, columnValue];
                counter++;
            }
            return (NSString *)sql;
        } else {
            return @"";
        }
    };

    __block NSString *select;
    __block NSString *orderBy;
    __block NSString *whereClause;

    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        select = sqlSelect(self.tableName, self.columnKeys, self.droprowid);
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        orderBy = sqlOrderBy(self.sortDesc, self.columns);
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        whereClause = sqlWhere(self.whereClause);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSMutableString *sql = [[NSMutableString alloc] initWithString:select];
    [sql appendString:orderBy];
    [sql appendString:whereClause];
    
    return sql;
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit {
    NSString *sqlQuery = [self sqlQuery];
    return [sqlQuery stringByAppendingFormat:@" LIMIT %ld ", (unsigned long)limit];
}

- (NSString *)sqlQueryWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
    NSString *sqlQueryWithLimit = [self sqlQueryWithLimit:limit];
    return [sqlQueryWithLimit stringByAppendingFormat:@" OFFSET %ld ", (unsigned long)offset];
}

@end
