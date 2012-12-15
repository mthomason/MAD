//
//  RptqQuery.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "RptqField.h"
#import "RptqQueryCache.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqTable.h"


@implementation RptqQuery

@dynamic cachedText;
@dynamic override;
@dynamic overrideText;
@dynamic identifier;
@dynamic hasFields;
@dynamic hasQueryCache;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasTables;
@dynamic inDatabase;

@end
