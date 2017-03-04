//
//  MTDatabaseConnectionSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlite3_h
#define Reports_MTDatabaseConnectionSqlite3_h

#import "MADDatabaseConnection.h"
#import "MADDatabaseConnectionsPropertiesURLProtocol.h"

@interface MTDatabaseConnectionSqlite3 : MADDatabaseConnection
    <MADDatabaseConnectionConstructors,
        MADDatabaseConnectionsProperties,
        MADDatabaseConnectionsPropertiesURL,
        NSCopying>

    - (instancetype)initWithUrl:(NSURL *)url;

@end

#endif
