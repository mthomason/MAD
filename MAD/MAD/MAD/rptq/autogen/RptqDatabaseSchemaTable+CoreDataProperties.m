//
//  RptqDatabaseSchemaTable+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaTable+CoreDataProperties.h"

@implementation RptqDatabaseSchemaTable (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaTable *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseSchemaTable"];
}

@dynamic identifier;
@dynamic name;
@dynamic queryable;
@dynamic hasFields;
@dynamic inDatabase;
@dynamic inQueryTable;

@end
