//
//  RptqQueryGroup_Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryGroup_Extras_h
#define Reports_RptqQueryGroup_Extras_h

#import "RptqQueryGroup.h"
#import "MADSortOrder.h"

@class RptqQueryField;

@interface RptqQueryGroup (Extras)

+ (instancetype)newQueryGroupQueryWithSortOrder:(MNSSortOrder)sortOrder
                        andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query;

    - (NSString *)fieldNameNice;
    - (NSString *)fieldNameQuery;
    - (NSString *)sortDisplayNice;
    - (NSInteger)lastWeightWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (NSInteger)location;

@end

#endif
