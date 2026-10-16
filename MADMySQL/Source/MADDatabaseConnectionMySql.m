//
//  MADDatabaseConnectionMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionMySql.h"
#import "MADDatabaseMySQL.h"
#import <Foundation/NSCharacterSet.h>

@implementation MADDatabaseConnectionMySql

// A linked driver is a registered driver: the constructor learns MySQL is here
// from this, not from an import (MADDatabaseDriverRegistry.h).
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}

+ (MADDatabaseType)databaseType {
	return MADDatabaseTypeMySQL;
}

+ (Class)databaseClass {
	return [MADDatabaseMySQL class];
}

+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {
	return [[self alloc] initWithHost: host database: database andPort: port];
}

@synthesize database = _database;
@synthesize server = _server;
@synthesize host = _host;
@synthesize port = _port;
@synthesize connectionString = _connectionString;
@synthesize databaseType = _databaseType;

@dynamic identifier;

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	id dbConnection = [[self alloc] initWithHost: credentals.host
										database: credentals.database
										 andPort: credentals.port];
	return dbConnection;
}

- (instancetype)initWithHost:(NSString *)host
					database:(NSString *)database
					 andPort:(NSInteger)port {
	if (self = [super init]) {
		_server = [host stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		_host = [host copy];
		_database = [database copy];
		_port = port;
		_databaseType = MADDatabaseTypeMySQL;
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] allocWithZone:zone] initWithHost: _host
													 database: _database
													  andPort: _port];
	return copy;
}

- (NSString *)identifier {
	return [[self class] Identifier];
}

+ (NSString *)Identifier {
	return @"MySQL";
}

- (NSString *)connectionString {
	return [[NSString alloc] initWithFormat:@"(%@)[%@:%ld]%@", self.identifier, self.server, (long)_port, _database];
}

- (BOOL)requiresCredentials {
	return YES;
}

@end
