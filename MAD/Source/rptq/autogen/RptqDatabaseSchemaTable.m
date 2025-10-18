//
//  RptqDatabaseSchemaTable+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable.h"
@implementation RptqDatabaseSchemaTable

@end

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
