//
//  MADQueryCacheRowIds.m
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

#import <MADAPI/MADQueryType.h>
#import "MADQueryCacheSelectRowIds.h"
#import "MADQuerySelectParameters.h"
#import "MADQuery+Sqlite3.h"

@interface MADQueryCacheSelectRowIds ()
    @property (nonatomic, copy) NSString *sql;

@end

@implementation MADQueryCacheSelectRowIds

@synthesize columns = _columns;

- (instancetype)initWithRowIDs:(NSArray *)rowIDs
                     tableName:(NSString *)tableName
               sortDescriptors:(NSArray *)sortDescriptors
                       columns:(NSDictionary *)columns {
    if (self = [super init]) {
        self.columns = columns.copy;
        NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ ", tableName];
        [sql appendString:[self whereClauseWithRowIds:rowIDs]];
        [sql appendString:[self orderByClauseWithSortDescriptors:sortDescriptors]];
        self.sql = sql;
        
        self.columns = nil;
    }
    return self;
}

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self = [super initWithObject:object]) {
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        id key;

        key = [[NSNumber alloc] initWithShort: MADQuerySelectRowIds];
        NSArray *rowIDs = [object objectForKey:key];
        
        if (rowIDs == nil) {
            key = [[NSNumber alloc] initWithShort: MADQuerySelectRowId];
            NSNumber *rowID = [object objectForKey: key];
            rowIDs = [[NSArray alloc] initWithObjects:rowID, nil];
        }
        
        NSNumber *keyColumns = @(MADQuerySelectColumns);
        NSDictionary *columns = object[keyColumns];
        self.columns = columns.copy;
        
        key = [[NSNumber alloc] initWithShort: MADQuerySelectTableName];
        NSString *tableName = object[key];

        key = [[NSNumber alloc] initWithShort: MADQuerySelectSortDescriptors];
        NSArray *array = object[key];
        NSArray *sortDescriptors = [NSArray arrayWithArray:array];
        
        NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT *, ROWID FROM %@ ", tableName];
        [sql appendString:[self whereClauseWithRowIds:rowIDs]];
        [sql appendString:[self orderByClauseWithSortDescriptors:sortDescriptors]];
        self.sql = sql;
        
        self.columns = nil;
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return self.sql;
}

- (MADQueryType)type {
    return MADQueryTypeCacheSelectRowIds;
}

@end
