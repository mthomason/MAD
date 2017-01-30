//
//  RptqUserCredentals.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqUserCredentals_NSManagedObject_h
#define MAD_RptqUserCredentals_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface RptqUserCredentals : NSManagedObject

@property (nullable, nonatomic, copy) NSString *database_driver_type;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSNumber *inUse;
@property (nullable, nonatomic, copy) NSString *mysql_database;
@property (nullable, nonatomic, copy) NSString *mysql_host;
@property (nullable, nonatomic, copy) NSString *mysql_password;
@property (nullable, nonatomic, copy) NSNumber *mysql_port;
@property (nullable, nonatomic, copy) NSString *mysql_username;
@property (nullable, nonatomic, copy) NSString *sf_login_domain;
@property (nullable, nonatomic, copy) NSString *sf_login_identifier;
@property (nullable, nonatomic, copy) NSString *sf_login_key;
@property (nullable, nonatomic, copy) NSString *sf_login_redirect_uri;
@property (nullable, nonatomic, copy) NSString *sf_password;
@property (nullable, nonatomic, copy) NSString *sf_username;
@property (nullable, nonatomic, copy) NSString *tds_database;
@property (nullable, nonatomic, copy) NSString *tds_host;
@property (nullable, nonatomic, copy) NSString *tds_password;
@property (nullable, nonatomic, copy) NSNumber *tds_port;
@property (nullable, nonatomic, copy) NSString *tds_server;
@property (nullable, nonatomic, copy) NSString *tds_username;
@property (nullable, nonatomic, retain) RptqDatabase *inDatabase;

@end

NS_ASSUME_NONNULL_END

#endif
