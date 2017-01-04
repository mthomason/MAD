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

#import "MADQueryCacheSelectLimitOffsetParamaters.h"

@interface MTQueryCacheSelectLimitOffset ()
    @property (nonatomic, strong) NSString *sql;
@end

@implementation MTQueryCacheSelectLimitOffset

+ (instancetype)newQueryCacheSelectLimitOffsetWithTableName:(NSString *)tableName
                                                 columnKeys:(NSArray *)columnKeys
                                            sortDescriptors:(NSArray *)sortDescriptors {
    id keyColumnKeys = @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys);
    id keyTableNames = @(MTQueryCacheSelectLimitOffsetParamatersTableNames);
    id keySortDesc   = @(MTQueryCacheSelectLimitOffsetParamatersSortDesc);
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             columnKeys, keyColumnKeys,
                             tableName, keyTableNames,
                             sortDescriptors, keySortDesc, nil];
    
    id query = [[self alloc] initWithObject: options];
    return query;

}

+ (instancetype)newQueryCacheSelectLimitOffsetWithTableName:(NSString *)tableName
                                                 columnKeys:(NSArray *)columnKeys
                                                    columns:(NSMutableDictionary <NSString *, MADDataColumn *> *)columns
                                            sortDescriptors:(NSArray *)sortDescriptors {
    id keyColumnKeys = @(MTQueryCacheSelectLimitOffsetParamatersColumnKeys);
    id keyTableNames = @(MTQueryCacheSelectLimitOffsetParamatersTableNames);
    id keySortDesc   = @(MTQueryCacheSelectLimitOffsetParamatersSortDesc);
    id keyColumns    = @(MTQueryCacheSelectLimitOffsetParamatersColumns);
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             columns, keyColumns,
                             columnKeys, keyColumnKeys,
                             tableName, keyTableNames,
                             sortDescriptors, keySortDesc, nil];
    
    
    id query = [[self alloc] initWithObject: options];
    return query;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.",
                                                              NSStringFromClass([self class]));

        NSString *(^sqlSelect)(NSString *, NSArray *, BOOL);
        sqlSelect = ^(NSString *tableName, NSArray *columnKeys, BOOL includingRowID) {
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
                    
                    NSString *columnHandle = condition[MTQueryKeyPredicateColumn];
                    NSString *columnValue = condition[MTQueryKeyPredicateValue];
                    [sql appendFormat:@"%@ = %@", columnHandle, columnValue];
                    counter++;
                }
                return (NSString *)sql;
            } else {
                return @"";
            }
        };

        id keyLimit = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersLimit];
        NSNumber *limitO = object[keyLimit];
        
        id keyOffset = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersOffset];
        NSNumber *offsetO = object[keyOffset];

        NSUInteger limit = limitO ? limitO.unsignedIntegerValue : NSNotFound;     // Careful not to fuck this up!
        NSUInteger offset = offsetO ? offsetO.unsignedIntegerValue : NSNotFound;  // Careful not to fuck this up!
        
        id keyTableNames = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
        NSString *tableName = object[keyTableNames];
        
        id keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
        NSArray *columnKeys = object[keyColumnKeys];
        
        id keySortDesc = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];
        NSArray *sortDesc = object[keySortDesc];
        
        id keyWhere = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersWhere];
        NSArray *whereClause = object[keyWhere];

        id keyColumns = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumns];
        NSDictionary *columns = object[keyColumns];
        
        id keyRowID = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersDropRowid];
        NSNumber *dropRowid = object[keyRowID];
        
        dispatch_queue_t queueHigh = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        __block NSString *sqlSelectText;
        dispatch_group_async(group, queueHigh, ^{
            sqlSelectText = sqlSelect(tableName, columnKeys, dropRowid.boolValue);
        });

        __block NSString *sqlOrderByText;
        dispatch_group_async(group, queueHigh, ^{
            sqlOrderByText = sqlOrderBy(sortDesc, columns);
        });
        
        __block NSString *sqlWhereText;
        dispatch_group_async(group, queueHigh, ^{
            sqlWhereText = sqlWhere(whereClause);
        });
        
        dispatch_group_leave(group);
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        NSMutableString *sql = [[NSMutableString alloc] initWithString:sqlSelectText];
        [sql appendString:sqlOrderByText];
        [sql appendString:sqlWhereText];
        
        if (limit == NSNotFound && offset == NSNotFound) {
            
        } else if (offset == NSNotFound) {
            [sql appendFormat:@" LIMIT %ld ", (unsigned long)limit];
        } else {
            [sql appendFormat:@" LIMIT %ld OFFSET %ld ", (unsigned long)limit, (unsigned long)offset];
        }
        
        self.sql = sql;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return self.sql;
}

- (BOOL)returnsResults {
    return YES;
}

@end
