//
//  RptqDatabase+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase+CoreDataProperties.h"

@implementation RptqDatabase (CoreDataProperties)

+ (NSFetchRequest<RptqDatabase *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabase"];
}

@dynamic databaseDriverType;
@dynamic databaseDriverTypeEnum;
@dynamic identifier;
@dynamic hasQueries;
@dynamic hasTables;
@dynamic ownedByQueryAsStaticResource;
@dynamic ownedByUser;

@end
