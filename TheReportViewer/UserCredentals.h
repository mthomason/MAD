//
//  UserCredentals.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Database;

@interface UserCredentals : NSManagedObject

@property (nonatomic, retain) NSString * database_driver_type;
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
@property (nonatomic, retain) NSSet *haveDatabases;
@end

@interface UserCredentals (CoreDataGeneratedAccessors)

- (void)addHaveDatabasesObject:(Database *)value;
- (void)removeHaveDatabasesObject:(Database *)value;
- (void)addHaveDatabases:(NSSet *)values;
- (void)removeHaveDatabases:(NSSet *)values;

@end
