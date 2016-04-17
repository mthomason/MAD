//
//  RptqDatabaseSchemaTable.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaTable.h"
#import <MAD/RptqDatabase.h>
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
