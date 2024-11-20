//
//  MADDatabaseConnectionMySql.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionMySql_h
#define Reports_MTDatabaseConnectionMySql_h

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

@interface MADDatabaseConnectionMySql : MADDatabaseConnection
    <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties,
        MADConnectionsPropertiesProtocol, NSCopying>

    - (instancetype)initWithHost:(NSString *)host
                        database:(NSString *)database
                         andPort:(NSInteger)port;

@end

#endif
