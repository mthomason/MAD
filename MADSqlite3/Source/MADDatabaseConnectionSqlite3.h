//
//  MADDatabaseConnectionSqlite3.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDatabaseConnectionSqlite3_h
#define Reports_MTDatabaseConnectionSqlite3_h

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>

@interface MADDatabaseConnectionSqlite3 : MADDatabaseConnection <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties, MADDatabaseConnectionsPropertiesURL, MADDatabaseDriver, NSCopying>

- (instancetype)initWithUrl:(NSURL *)url;

@end

#endif
