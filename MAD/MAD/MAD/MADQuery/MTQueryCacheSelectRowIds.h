//
//  MTQueryCacheRowIds.h
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheSelectRowIds_h
#define Reports_MTQueryCacheSelectRowIds_h

#import "MTQuery.h"

@interface MTQueryCacheSelectRowIds : MTQuery

    - (instancetype)initWithTableName:(NSString *)tableName rowIDs:(NSArray *)rowIDs
                      sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns;

@end

#endif
