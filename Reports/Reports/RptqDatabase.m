//
//  RptqDatabase.m
//  Reports
//
//  Created by Michael Thomason on 12/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqRelationship.h"
#import "RptqTable.h"
#import "RptqUserCredentals.h"


@implementation RptqDatabase

@dynamic connection_id;
@dynamic database_driver_type;
@dynamic hasQueries;
@dynamic hasRelationships;
@dynamic hasTables;
@dynamic ownedByQueryAsStaticResource;
@dynamic ownedByUser;

@end
