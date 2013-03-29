//
//  RptqQuery.m
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqQueryCache.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTable.h"


@implementation RptqQuery

@dynamic cachedText;
@dynamic identifier;
@dynamic override;
@dynamic overrideText;
@dynamic hasFields;
@dynamic hasQueryCache;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasQueryTables;
@dynamic hasTables;
@dynamic inDatabase;

@end
