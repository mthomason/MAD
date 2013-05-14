//
//  RptqDatabaseSchemaTable.m
//  Reports
//
//  Created by Michael Thomason on 5/14/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable.h"


@implementation RptqDatabaseSchemaTable

@dynamic identifier;
@dynamic label;
@dynamic label_plural;
@dynamic name;
@dynamic queryable;
@dynamic hasFields;
@dynamic inDatabase;
@dynamic inQueryTable;

@end
