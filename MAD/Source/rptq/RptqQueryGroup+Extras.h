//
//  RptqQueryGroup_Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqQueryGroup_Extras_h
#define Reports_RptqQueryGroup_Extras_h

#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADSortOrder.h>

@class RptqQueryField;

@interface RptqQueryGroup (Extras)

	+ (instancetype)newQueryGroupQueryWithSortOrder:(MADSortOrder)sortOrder
							andManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	+ (NSString *)keyPathHasField;
	+ (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query;
	+ (NSUInteger)numberOfGroupsForQueryID:(int64_t)objectID
					  managedObjectContext:(RptqStoreContext *)managedObjectContext;
	- (NSString *)fieldNameNice;
	- (NSString *)fieldNameQuery;
	- (NSString *)sortDisplayNice;
	- (int16_t)lastWeightWithManagedObjectContext:(RptqStoreContext *)managedObjectContext;
	- (NSInteger)location;

@end

#endif
