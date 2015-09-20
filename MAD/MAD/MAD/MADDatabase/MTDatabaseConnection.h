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
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

extern NSString * const MADIdentifierDatabaseMySQL;
extern NSString * const MADIdentifierDatabaseTDS;
extern NSString * const MADIdentifierDatabaseSqlite3;

@interface MTDatabaseConnection : NSObject

@property (nonatomic, strong) NSString  *databaseTypeIdentifier;
@property (nonatomic, strong) NSURL     *databaseUrl;
@property (nonatomic, strong) NSString  *username;
@property (nonatomic, strong) NSString  *password;
@property (nonatomic, strong) NSString  *server;
@property (nonatomic, strong) NSString  *database;
@property (nonatomic, strong) NSString  *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong, readonly) NSString *IPAddressOrServer;

- (NSString *)appname;

+ (instancetype)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier;
+ (instancetype)databaseConnectionFactoryWithType:(NSString *)typeIdentifier
                                             host:(NSString *)host
                                         database:(NSString *)database
                                             port:(NSInteger)port;
+ (instancetype)databaseConnectionFactory:(id)credentals;

- (NSString *)identifier;
+ (NSString *)identifier;

- (NSString *)connectionString;
- (void)testConnection:(void(^)(BOOL success, NSArray *errors))completion;

@end

#endif
