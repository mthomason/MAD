//
//  MTDatabaseConnectionMySql.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionMySql_h
#define Reports_MTDatabaseConnectionMySql_h

#import "MADDatabaseConnection.h"
#import "MADConnectionsPropertiesProtocol.h"

@interface MTDatabaseConnectionMySql : MADDatabaseConnection
    <MADDatabaseConnectionConstructors,
        MADDatabaseConnectionsProperties,
        MADConnectionsPropertiesProtocol,
        NSCopying>

    - (instancetype)initWithHost:(NSString *)host
                        database:(NSString *)database
                         andPort:(NSInteger)port;

@end

#endif
