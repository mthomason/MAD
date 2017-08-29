//
//  MTQuery+Sqlite3.m
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery+Sqlite3.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSException.h>

#import <MADFoundation/MADDataColumn.h>

#import "MTDatabaseSqlite3.h"   //FIXME: Should only be included in Cache subset

@implementation MTQuery (Sqlite3)

- (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    if (sortDescriptors.count > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        
        NSString *key;
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            if (sortCounter != 0) [sql appendString:@", "];
            MADDataColumn *dataColumn = nil;
            if (self.columns) {
                if ((key = sortDescriptor.key)) {
                    dataColumn = self.columns[key];
                }
            }
            NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
            MADSqlite3SortDescription *sortDirection;
            sortDirection = [MTDatabaseSqlite3 newSqlite3SortDescriptionForColumnType: dataColumn.nativeType
                                                                            ascending: sortDescriptor.ascending];
            [sql appendFormat:@"%@ %@", sortDescriptor.key, sortDirection];
            sortCounter++;
        }
    }
    return sql;
}

@end
