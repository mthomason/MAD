//
//  MADDatabaseConnection+Constructor.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseConnection_Constructor_h
#define Reports_MADDatabaseConnection_Constructor_h

#import <MADAPI/MADDatabaseConnection.h>

@interface MADDatabaseConnection (Constructor)

    + (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
                                             host:(NSString *)host
                                         database:(NSString *)database
                                             port:(NSInteger)port;

    + (instancetype)newDatabaseConnectionForUrl:(NSURL *)url;

    + (instancetype)newDatabaseConnectionWithCredentals:(NSObject <MADConnectionsPropertiesProtocol> *)credentals;

    + (NSString *)Identifier:(MADDatabaseType)databaseType;

@end

#endif
