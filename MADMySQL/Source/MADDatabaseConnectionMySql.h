//
//  MADDatabaseConnectionMySql.h
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTDatabaseConnectionMySql_h
#define Reports_MTDatabaseConnectionMySql_h

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

@interface MADDatabaseConnectionMySql : MADDatabaseConnection <MADDatabaseConnectionConstructors, MADDatabaseConnectionsProperties, MADConnectionsPropertiesProtocol, MADDatabaseDriver, NSCopying>

- (instancetype)initWithHost:(NSString *)host
					database:(NSString *)database
					 andPort:(NSInteger)port;

@end

#endif
