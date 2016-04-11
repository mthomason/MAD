//
//  MTQuerySelectItemsForGroup.h
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySelectItemsForGroup_h
#define Reports_MTQuerySelectItemsForGroup_h

#import "MTQuery.h"

@interface MTQuerySelectItemsForGroup : MTQuery

    - (instancetype)initWithTableName:(NSString *)tableName sortDescriptors:(NSArray *)sortDescriptors
                           columnKeys:(NSArray *)columnKeys whereClause:(NSArray *)whereClause columns:(NSDictionary *)columns;

@end

#endif
