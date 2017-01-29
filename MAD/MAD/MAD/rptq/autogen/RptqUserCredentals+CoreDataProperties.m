//
//  RptqUserCredentals+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqUserCredentals+CoreDataProperties.h"

@implementation RptqUserCredentals (CoreDataProperties)

+ (NSFetchRequest<RptqUserCredentals *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqUserCredentals"];
}

@dynamic database_driver_type;
@dynamic identifier;
@dynamic inUse;
@dynamic mysql_database;
@dynamic mysql_host;
@dynamic mysql_password;
@dynamic mysql_port;
@dynamic mysql_username;
@dynamic sf_login_domain;
@dynamic sf_login_identifier;
@dynamic sf_login_key;
@dynamic sf_login_redirect_uri;
@dynamic sf_password;
@dynamic sf_username;
@dynamic tds_database;
@dynamic tds_host;
@dynamic tds_password;
@dynamic tds_port;
@dynamic tds_server;
@dynamic tds_username;
@dynamic inDatabase;

@end
