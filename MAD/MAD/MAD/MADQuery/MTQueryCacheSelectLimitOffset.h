//
//  MTQueryCacheSelectLimitOffset.h
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheSelectLimitOffset_h
#define Reports_MTQueryCacheSelectLimitOffset_h

#import "MTQuery.h"

@class MADDataColumn;

@interface MTQueryCacheSelectLimitOffset : MTQuery

    - (instancetype)initWithColumnKeys: (NSArray *)columnKeys
                             tableName: (NSString *)tableName
                       sortDescriptors: (NSArray *)sortDescriptors
                                 limit: (NSUInteger)limit
                                offset: (NSUInteger)offset
                             dropRowID: (BOOL)dropRowID
                               columns: (NSDictionary <NSString *, MADDataColumn *> *)columns;

@end

#endif
