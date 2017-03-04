//
//  MTDatabaseConnectionSqlServer.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlServer_h
#define Reports_MTDatabaseConnectionSqlServer_h

#import "MADDatabaseConnection.h"
#import "MADDatabaseConnectionsPropertiesCredentals.h"

@interface MTDatabaseConnectionSqlServer : MADDatabaseConnection
    <MADDatabaseConnectionConstructors,
        MADDatabaseConnectionsProperties,
        MADDatabaseConnectionsPropertiesCredentals,
        NSCopying>
    
    - (instancetype)initWithHost:(NSString *)host
                          server:(NSString *)server
                        database:(NSString *)database
                         andPort:(NSInteger)port;

@end

#endif
