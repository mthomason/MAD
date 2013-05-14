//
//  RptqDatabase.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqUserCredentals.h"


@implementation RptqDatabase

@dynamic databaseDriverType;
@dynamic databaseDriverTypeEnum;
@dynamic identifier;
@dynamic hasQueries;
@dynamic hasTables;
@dynamic ownedByQueryAsStaticResource;
@dynamic ownedByUser;

@end
