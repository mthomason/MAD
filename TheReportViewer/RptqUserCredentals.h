//
//  RptqUserCredentals.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase;

@interface RptqUserCredentals : NSManagedObject

@property (nonatomic, retain) NSString * database_driver_type;
@property (nonatomic, retain) NSNumber * inUse;
@property (nonatomic, retain) NSString * mysql_database;
@property (nonatomic, retain) NSString * mysql_host;
@property (nonatomic, retain) NSString * mysql_password;
@property (nonatomic, retain) NSNumber * mysql_port;
@property (nonatomic, retain) NSString * mysql_username;
@property (nonatomic, retain) NSString * sf_login_domain;
@property (nonatomic, retain) NSString * sf_login_identifier;
@property (nonatomic, retain) NSString * sf_login_key;
@property (nonatomic, retain) NSString * sf_login_redirect_uri;
@property (nonatomic, retain) NSString * sf_password;
@property (nonatomic, retain) NSString * sf_username;
@property (nonatomic, retain) RptqDatabase *inDatabase;

@end
