//
//  RptqQueryTable+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqQueryTable.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqQueryTable

@end

@implementation RptqQueryTable (CoreDataProperties)


@dynamic alias;
@dynamic dropIndex;
@dynamic identifier;
@dynamic databaseSchemaTable;
@dynamic hasQueryFields;
@dynamic inQuery;

@end
