//
//  RptqQuery.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery.h"
#import "RptqDocument.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTables.h"


@implementation RptqQuery

@dynamic override;
@dynamic overrideText;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasQueryTables;
@dynamic inQueryBuilderDocument;

@end
