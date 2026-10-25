//
//  RptqQuery+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTable.h"

@implementation RptqQuery

@end

@implementation RptqQuery (CoreDataProperties)



@dynamic cachedText;
@dynamic identifier;
@dynamic override;
@dynamic overrideText;
@dynamic sqlSourceText;
@dynamic hasFields;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasQueryTables;
@dynamic inDatabase;

@end
