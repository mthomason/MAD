//
//  RptqDatabaseSchemaField+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqDatabaseSchemaField

@end

@implementation RptqDatabaseSchemaField (CoreDataProperties)


@dynamic dataType;
@dynamic dataTypeNative;
@dynamic decimals;
@dynamic identifier;
@dynamic name;
@dynamic primaryKey;
@dynamic width;
@dynamic inQuery;
@dynamic inQueryField;
@dynamic inTable;

@end
