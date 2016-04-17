//
//  RptqDatabase.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <MAD/RptqDatabase.h>
#import "RptqDatabaseSchemaTable.h"
#import <MAD/RptqDocument.h>
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
