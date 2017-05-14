//
//  RptqQueryGroup_Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryGroup_Extras_h
#define Reports_RptqQueryGroup_Extras_h

#import "RptqQueryGroup.h"
#import "MADSortOrder.h"

@class RptqQueryField;

@interface RptqQueryGroup (Extras)

    + (instancetype)newQueryGroupQueryWithSortOrder:(MADSortOrder)sortOrder
                            andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (NSString *)keyPathHasField;
    + (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query;
    + (NSUInteger)numberOfGroupsForQueryID:(NSManagedObjectID *)objectID
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (NSString *)fieldNameNice;
    - (NSString *)fieldNameQuery;
    - (NSString *)sortDisplayNice;
    - (int16_t)lastWeightWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (NSInteger)location;

@end

#endif
