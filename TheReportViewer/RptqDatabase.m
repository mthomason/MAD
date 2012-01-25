//
//  RptqDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase.h"
#import "RptqDocument.h"
#import "RptqRelationship.h"
#import "RptqTable.h"
#import "RptqUserCredentals.h"


@implementation RptqDatabase

@dynamic name;
@dynamic hasRelationships;
@dynamic hasTables;
@dynamic ownedByUser;
@dynamic ownedByQueryAsStaticResource;

@end
