//
//  RptqDatabase+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument.h"
#import "RptqQuery.h"
#import "RptqDatabaseCredentals.h"
@implementation RptqDatabase

@end

@implementation RptqDatabase (CoreDataProperties)


@dynamic databaseDriverType;
@dynamic databaseDriverTypeEnum;
@dynamic identifier;
@dynamic hasQueries;
@dynamic hasTables;
@dynamic ownedByQueryAsStaticResource;
@dynamic ownedByUser;

@end
