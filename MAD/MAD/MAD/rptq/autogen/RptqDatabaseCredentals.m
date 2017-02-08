//
//  RptqDatabaseCredentals+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseCredentals.h"
#import "RptqDatabase.h"
@implementation RptqDatabaseCredentals

@end

@implementation RptqDatabaseCredentals (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseCredentals"];
}

@dynamic driverID;
@dynamic identifier;
@dynamic inUse;
@dynamic dbname;
@dynamic host;
@dynamic port;
@dynamic server;
@dynamic domain;
@dynamic key;
@dynamic url;
@dynamic inDatabase;

@end
