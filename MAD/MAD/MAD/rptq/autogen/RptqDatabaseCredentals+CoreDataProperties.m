//
//  RptqDatabaseCredentals+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseCredentals+CoreDataProperties.h"

@implementation RptqDatabaseCredentals (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseCredentals"];
}

@dynamic driver_type;
@dynamic identifier;
@dynamic inUse;
@dynamic database;
@dynamic host;
@dynamic port;
@dynamic server;
@dynamic domain;
@dynamic key;
@dynamic url;
@dynamic inDatabase;

@end
