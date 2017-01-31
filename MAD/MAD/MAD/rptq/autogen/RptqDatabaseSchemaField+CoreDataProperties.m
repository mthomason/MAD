//
//  RptqDatabaseSchemaField+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaField+CoreDataProperties.h"

@implementation RptqDatabaseSchemaField (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaField *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseSchemaField"];
}

@dynamic dataType;
@dynamic dataTypeNative;
@dynamic dataTypeNativeDescription;
@dynamic decimals;
@dynamic identifier;
@dynamic label;
@dynamic name;
@dynamic primaryKey;
@dynamic width;
@dynamic inQuery;
@dynamic inQueryField;
@dynamic inTable;

@end
