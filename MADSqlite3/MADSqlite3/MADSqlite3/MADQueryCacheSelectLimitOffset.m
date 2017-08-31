//
//  MADQueryCacheSelectLimitOffset.m
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryCacheSelectLimitOffset.h"
#import <dispatch/dispatch.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import "MADQueryCacheSelectLimitOffsetParamaters.h"
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheSelectLimitOffset ()
    @property (nonatomic, strong) NSString *sql;
@end

@implementation MADQueryCacheSelectLimitOffset

- (instancetype)initWithColumnKeys: (NSArray <NSString *> *)columnKeys
                         tableName: (NSString *)tableName
                   sortDescriptors: (NSArray <NSSortDescriptor *> *)sortDescriptors
                             limit: (NSUInteger)limit
                            offset: (NSUInteger)offset
                         dropRowID: (BOOL)dropRowID
                           columns: (NSDictionary <NSString *, MADDataColumn *> *)columns {
    if (self = [super initWithObject:nil]) {

        NSString *(^sqlSelect)(void);
        sqlSelect = ^() {
            NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT "];
            if (columnKeys.count == 0) {
                [sql appendString: @" rowid FROM "];
                [sql appendString: tableName];
            } else {
                
                NSUInteger columnCounter = 0;
                for (NSString *key in columnKeys) {
                    if (columnCounter != 0) {
                        [sql appendString:@", "];
                    }
                    [sql appendFormat:@"\"%@\"", key];
                    columnCounter++;
                }
                if (dropRowID) {
                    [sql appendString: @" FROM "];
                    [sql appendString: tableName];
                } else {
                    [sql appendString: @", rowid FROM "];
                    [sql appendString: tableName];
                }
            }
            return sql;
        };
        
        dispatch_queue_t queueHigh = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        
        __block NSString *sqlSelectText;
        
        dispatch_group_async(group, queueHigh, ^{
            sqlSelectText = sqlSelect();
        });
        
        __block NSString *sqlOrderByText;
        
        dispatch_group_async(group, queueHigh, ^{
            if (sortDescriptors.count > 0) {
                NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
                NSUInteger sortCounter = 0;
                [sql appendString:@" ORDER BY "];
                for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
                    if (sortCounter != 0) [sql appendString:@", "];
                    
                    MADDataColumn *dataColumn = nil;
                    if (columns) {
                        NSString *key = sortDescriptor.key;
                        dataColumn = columns[key];
                        key = nil;
                    }
                    MADSqlite3SortDescription *sortDescription;
                    sortDescription = [MADDatabaseSqlite3 newSqlite3SortDescriptionForColumnType: (MADDataType)dataColumn.nativeType
                                                                                      ascending: sortDescriptor.ascending];
                    [sql appendFormat:@"%@ %@", sortDescriptor.key, sortDescription];
                    sortCounter++;
                }
                sqlOrderByText = sql;
            } else {
                sqlOrderByText = @"";
            }
        });
        
        dispatch_group_leave(group);
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        NSMutableString *sql = [[NSMutableString alloc] initWithString:sqlSelectText];
        [sql appendString:sqlOrderByText];
        
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

- (instancetype)initWithObject:(id)object {

    NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.",
             NSStringFromClass([self class]));

    id keyLimit = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersLimit];
    NSNumber *limitO = object[keyLimit];
    
    id keyOffset = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersOffset];
    NSNumber *offsetO = object[keyOffset];
    
    NSUInteger limit = limitO ? limitO.unsignedIntegerValue : NSNotFound;     // Careful not to fuck this up!
    NSUInteger offset = offsetO ? offsetO.unsignedIntegerValue : NSNotFound;  // Careful not to fuck this up!
    
    id keyTableNames = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersTableNames];
    NSString *tableName = object[keyTableNames];
    
    id keyColumnKeys = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersColumnKeys];
    NSArray *columnKeys = object[keyColumnKeys];
    
    id keySortDesc = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersSortDesc];
    NSArray *sortDesc = object[keySortDesc];
    
    
    id keyColumns = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersColumns];
    NSDictionary *columns = object[keyColumns];
    
    id keyRowID = [[NSNumber alloc] initWithShort: MADQueryCacheSelectLimitOffsetParamatersDropRowid];
    NSNumber *dropRowid = object[keyRowID];
    

    if (self = [self initWithColumnKeys:columnKeys
                              tableName:tableName
                        sortDescriptors:sortDesc
                                  limit:limit offset:offset
                              dropRowID:dropRowid.boolValue
                                columns:columns]) {
        
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return self.sql;
}

- (MADQueryType)type {
    return MADQueryTypeCacheSelectLimitOffset;
}

- (BOOL)returnsResults {
    return YES;
}

@end
