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

@interface MTQueryCacheSelectLimitOffset : MTQuery

- (instancetype)initWithLimit:(NSUInteger)limit offset:(NSUInteger)offset tableName:(NSString *)tableName dropRowID:(bool)dropRowID columnKeys:(NSArray *)columnKeys
              sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns whereClause:(NSArray *)whereClause;
              
@end

#endif
