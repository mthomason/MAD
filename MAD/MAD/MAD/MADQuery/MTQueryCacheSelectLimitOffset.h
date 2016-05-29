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
#import <MADFoundation/MADMutableMapDataColumns.h>

@interface MTQueryCacheSelectLimitOffset : MTQuery

+ (instancetype)newQueryCacheSelectLimitOffsetWithTableName:(NSString *)tableName
                                                 columnKeys:(NSArray *)columnKeys
                                            sortDescriptors:(NSArray *)sortDescriptors;

+ (instancetype)newQueryCacheSelectLimitOffsetWithTableName:(NSString *)tableName
                                                 columnKeys:(NSArray *)columnKeys
                                                    columns:(MADMutableMapDataColumns *)columns
                                            sortDescriptors:(NSArray *)sortDescriptors;

@end

#endif
