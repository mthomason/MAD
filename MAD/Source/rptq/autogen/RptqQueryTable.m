//
//  RptqQueryTable+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
