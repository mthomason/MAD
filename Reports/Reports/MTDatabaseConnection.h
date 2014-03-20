//
//  MNSDatabaseConnection.h
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnection_h
#define Reports_MTDatabaseConnection_h

#import <Foundation/Foundation.h>
#import "Constants.h"

@class RptqUserCredentals;

@interface MTDatabaseConnection : NSObject

@property (nonatomic, strong) NSString  *databaseTypeIdentifier;
@property (nonatomic, strong) NSURL     *databaseUrl;
@property (nonatomic, strong) NSString  *username;
@property (nonatomic, strong) NSString  *password;
@property (nonatomic, strong) NSString  *server;
@property (nonatomic, strong) NSString  *database;
@property (nonatomic, strong) NSString  *host;
@property (nonatomic, assign) NSInteger port;

- (NSString *)appname;

+ (id)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier;
+ (id)databaseConnectionFactory:(RptqUserCredentals *)credentals;

- (NSString *)identifier;
+ (NSString *)identifier;

@end

#endif
