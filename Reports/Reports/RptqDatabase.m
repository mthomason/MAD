//
//  RptqDatabase.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqRelationship.h"
#import "RptqUserCredentals.h"


@implementation RptqDatabase

@dynamic database_driver_type;
@dynamic identifier;
@dynamic hasQueries;
@dynamic hasRelationships;
@dynamic hasTables;
@dynamic ownedByQueryAsStaticResource;
@dynamic ownedByUser;

@end
