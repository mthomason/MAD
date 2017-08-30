//
//  MTQueryCacheCreateIndex.m
//  MAD
//
//  Created by Michael Thomason on 5/7/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheIndexCreate.h"
#import <MADFoundation/MADDataColumn.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MTDatabase.h>
#import "MTDatabaseSqlite3.h"
#import "MADQueryCacheIndexCreateParameters.h"

@interface MTQueryCacheIndexCreate ()

@end

@implementation MTQueryCacheIndexCreate {
    NSString *_sql;
}

@synthesize dataDelegate = _dataDelegate;

- (void)dealloc {
    _dataDelegate = nil;
}

- (instancetype)initWithObject:(MADQueryCacheIndexCreateParameters *)object {
    if (self = [super initWithObject:object]) {
        
        NSMutableString *sql;
        NSArray *sortDescriptors = object.sortDescriptors;
        if (sortDescriptors.count == 0) return self;
        
        sql = [[NSMutableString alloc] initWithFormat: @"CREATE INDEX IF NOT EXISTS main.%@ ON %@ (",
                                                       object.groupName, object.tableName];
        
        NSDictionary *columns = object.columns;
        MADSqlite3SortDescription *sortDirection;
        NSUInteger sortCounter = 0;
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            
            NSString *keySortDescriptor = sortDescriptor.key;
            
            MADDataColumn *column = columns[keySortDescriptor];
            
            NSAssert(column != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
            sortDirection = [MTDatabaseSqlite3 newSqlite3SortDescriptionForColumnType: (MADDataType) column.nativeType
                                                                            ascending: sortDescriptor.ascending];
            [sql appendFormat:(sortCounter == 0) ? @"%@ %@" : @", %@ %@", keySortDescriptor, sortDirection];
            sortCounter++;
        }
        [sql appendString:@")"];
        _sql = sql;
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return _sql;
}

- (BOOL)returnsResults { return NO; }

- (MADQueryType)type {
    return MADQueryTypeCacheIndexCreateParameters;
}

@end
