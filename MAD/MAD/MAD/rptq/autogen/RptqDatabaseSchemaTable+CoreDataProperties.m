//
//  RptqDatabaseSchemaTable+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDatabaseSchemaTable+CoreDataProperties.h"

@implementation RptqDatabaseSchemaTable (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaTable *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseSchemaTable"];
}

@dynamic identifier;
@dynamic label;
@dynamic label_plural;
@dynamic name;
@dynamic queryable;
@dynamic hasFields;
@dynamic inDatabase;
@dynamic inQueryTable;

@end
