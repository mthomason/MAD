//
//  MNSDatabaseConnection.h
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnection_h
#define Reports_MTDatabaseConnection_h

#import <Foundation/NSObject.h>
#import <MADCocoaExtensions/BDHost.h>
#import <MADFileManager/MADFileManager.h>

extern NSString * const MADIdentifierDatabaseMySQL;
extern NSString * const MADIdentifierDatabaseTDS;
extern NSString * const MADIdentifierDatabaseSqlite3;

@interface MTDatabaseConnection : NSObject
    <NSCopying>

    + (NSString *)IPAddressForServer:(NSString *)server;

    @property (nonatomic, strong) NSString  *databaseTypeIdentifier;


    + (instancetype)databaseConnectionFactoryEmpty:(NSString *)typeIdentifier NS_RETURNS_RETAINED;

    + (instancetype)databaseConnectionFactoryWithType:(NSString *)typeIdentifier
                                                 host:(NSString *)host
                                             database:(NSString *)database
                                                 port:(NSInteger)port NS_RETURNS_RETAINED;
    + (instancetype)newDatabaseConnectionForObject:(id)credentals NS_RETURNS_RETAINED;

    - (NSString *)appname;

    - (NSString *)identifier;
    + (NSString *)identifier;

    - (NSString *)connectionString;

    //Convinence functions.. only return valid values if subclasses implement them.
    - (NSURL *)databaseUrl;
    - (NSString *)database;
    - (NSString *)server;
    - (NSInteger)port;

@end

#endif
