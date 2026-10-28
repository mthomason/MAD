//
//  MADDatabaseConnectionPostgres.h
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDatabaseConnectionPostgres_h
#define MADDatabaseConnectionPostgres_h

#import <Foundation/Foundation.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

#define DEFAULT_POSTGRES_PORT 5432

@interface MADDatabaseConnectionPostgres : MADDatabaseConnection
	<MADDatabaseConnectionConstructors,
	 MADDatabaseConnectionsProperties,
	 MADConnectionsPropertiesProtocol,
	 MADDatabaseDriver,
	 NSCopying>

- (instancetype)initWithHost:(NSString *)host
					database:(NSString *)database
					 andPort:(NSInteger)port;

+ (instancetype)connectionWithHost:(NSString *)host
							  port:(int32_t)port
					   andDatabase:(NSString *)database;

+ (instancetype)connectionWithHost:(NSString *)host
					   andDatabase:(NSString *)database;

- (instancetype)initWithHost:(NSString *)host
						port:(int32_t)port
				 andDatabase:(NSString *)database;

- (instancetype)initWithHost:(NSString *)host
				 andDatabase:(NSString *)database;

@end

#endif /* MADDatabaseConnectionPostgres_h */
