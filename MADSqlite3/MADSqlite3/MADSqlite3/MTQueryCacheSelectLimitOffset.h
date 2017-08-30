//
//  MTQueryCacheSelectLimitOffset.h
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheSelectLimitOffset_h
#define Reports_MTQueryCacheSelectLimitOffset_h

#import <MADAPI/MTQuery.h>

@class MADDataColumn, NSSortDescriptor;

@interface MTQueryCacheSelectLimitOffset : MTQuery

    - (instancetype)initWithColumnKeys: (NSArray <NSString *> *)columnKeys
                             tableName: (NSString *)tableName
                       sortDescriptors: (NSArray <NSSortDescriptor *> *)sortDescriptors
                                 limit: (NSUInteger)limit
                                offset: (NSUInteger)offset
                             dropRowID: (BOOL)dropRowID
                               columns: (NSDictionary <NSString *, MADDataColumn *> *)columns;

@end

#endif
