//
//  MTDatabaseConnectionSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlServer_h
#define Reports_MTDatabaseConnectionSqlServer_h

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

@interface MADDatabaseConnectionSQLServer : MADDatabaseConnection
    <MADDatabaseConnectionConstructors,
        MADDatabaseConnectionsProperties,
        MADConnectionsPropertiesProtocol,
        NSCopying>
    
    - (instancetype)initWithHost:(NSString *)host
                          server:(NSString *)server
                        database:(NSString *)database
                         andPort:(NSInteger)port;

@end

#endif
