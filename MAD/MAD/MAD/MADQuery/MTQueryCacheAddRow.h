//
//  MTQueryCacheAddRow.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddRow_h
#define Reports_MTQueryCacheAddRow_h

#import "MTQuery.h"

@interface MTQueryCacheAddRow : MTQuery

    @property (nonatomic, weak) NSArray *rowData;

    - (instancetype)initWithColumnKeys:(NSArray *)columnKeys columns:(NSDictionary *)columns
                          andTableName:(NSString *)tablename forDatabase:(MTDatabase *)database;

@end

#endif
