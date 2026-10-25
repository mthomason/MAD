//
//  RptqDatabaseSchemaTable+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable.h"
@implementation RptqDatabaseSchemaTable

@end

@implementation RptqDatabaseSchemaTable (CoreDataProperties)


@dynamic identifier;
@dynamic name;
@dynamic queryable;
@dynamic hasFields;
@dynamic inDatabase;
@dynamic inQueryTable;

@end
