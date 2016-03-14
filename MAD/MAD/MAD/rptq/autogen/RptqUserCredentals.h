//
//  RptqUserCredentals.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqUserCredentals_h
#define MAD_AutoGen_RptqUserCredentals_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase;

@interface RptqUserCredentals : NSManagedObject

@property (nonatomic, strong) NSString * database_driver_type;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * inUse;
@property (nonatomic, strong) NSString * mysql_database;
@property (nonatomic, strong) NSString * mysql_host;
@property (nonatomic, strong) NSString * mysql_password;
@property (nonatomic, strong) NSNumber * mysql_port;
@property (nonatomic, strong) NSString * mysql_username;
@property (nonatomic, strong) NSString * sf_login_domain;
@property (nonatomic, strong) NSString * sf_login_identifier;
@property (nonatomic, strong) NSString * sf_login_key;
@property (nonatomic, strong) NSString * sf_login_redirect_uri;
@property (nonatomic, strong) NSString * sf_password;
@property (nonatomic, strong) NSString * sf_username;
@property (nonatomic, strong) NSString * tds_database;
@property (nonatomic, strong) NSString * tds_host;
@property (nonatomic, strong) NSString * tds_password;
@property (nonatomic, strong) NSNumber * tds_port;
@property (nonatomic, strong) NSString * tds_server;
@property (nonatomic, strong) NSString * tds_username;
@property (nonatomic, strong) RptqDatabase *inDatabase;

@end

#endif
