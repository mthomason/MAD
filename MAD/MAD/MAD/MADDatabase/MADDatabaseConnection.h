//
//  MADDatabaseConnection.h
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseConnection_h
#define Reports_MADDatabaseConnection_h

#import <Foundation/NSObject.h>
#import "MADDatabaseType.h"

@class RptqDatabaseCredentals;

@protocol MADDatabaseConnectionConstructors <NSObject>
    + (instancetype)newDatabaseConnectionWithCredentals:(RptqDatabaseCredentals *)credentals;
@end

@protocol MADDatabaseConnectionsProperties <NSObject>
    @property (readonly, nonatomic, assign) MADDatabaseType databaseType;
    @property (readonly, nonatomic, copy) NSString *connectionString;
    @property (readonly, nonatomic, assign) BOOL requiresCredientals;
    @property (readonly, nonatomic, copy) NSString *identifier;
    @property (readonly, class) NSString *Identifier;
@end

@protocol MADDatabaseConnectionsPropertiesCredentals <NSObject>
    @property (readonly, nonatomic, copy)      NSString  *host;
    @property (readonly, nonatomic, copy)      NSString  *server;
    @property (readonly, nonatomic, copy)      NSString  *database;
    @property (readonly, nonatomic, assign)    NSInteger port;
@end

@protocol MADDatabaseConnectionsPropertiesURL <NSObject>
    @property (readonly, nonatomic, copy) NSURL *databaseUrl;
@end

@interface MADDatabaseConnection : NSObject
    <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties>

    + (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
                                             host:(NSString *)host
                                         database:(NSString *)database
                                             port:(NSInteger)port;

    + (instancetype)newDatabaseConnectionForUrl:(NSURL *)url;

    + (instancetype)newDatabaseConnectionForObject:(id)connectionObject;

    + (NSString *)Identifier:(MADDatabaseType)databaseType;

@end

#endif
