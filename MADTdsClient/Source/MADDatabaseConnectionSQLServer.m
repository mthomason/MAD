//
//  MADDatabaseConnectionSQLServer.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionSQLServer.h"
#import "MADDatabaseSQLServer.h"
#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>
#import <MADAPI/MADDatabaseType.h>

@implementation MADDatabaseConnectionSQLServer

// A linked driver is a registered driver: the constructor learns SQL Server is
// here from this, not from an import (MADDatabaseDriverRegistry.h).
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}

+ (MADDatabaseType)databaseType {
	return MADDatabaseTypeTDS;
}

+ (Class)databaseClass {
	return [MADDatabaseSQLServer class];
}

+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {
	// The type-based constructor has only one host string to offer, and a TDS
	// connection wants the server name too -- what the old switch passed both ways.
	return [[self alloc] initWithHost: host server: host database: database andPort: port];
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
										  server: credentals.server
										database: credentals.database
										 andPort: credentals.port];
	return dbConnection;
}

- (instancetype)initWithHost:(NSString *)host
					  server:(NSString *)server
					database:(NSString *)database
					 andPort:(NSInteger)port {
	
	if (self = [super init]) {
		_host = [host copy];
		NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		_server = [server stringByTrimmingCharactersInSet: whitespace];
		_database = [database copy];
		_port = port;
		_databaseType = MADDatabaseTypeTDS;
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] allocWithZone:zone] initWithHost:self.host server:self.server
													 database:self.database andPort:self.port];
	return copy;
}

- (NSString *)connectionString {
	if (!_connectionString) {
		_connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@:%@:%ld]%@",
							 self.identifier, self.host,
							 self.server, (long)self.port, self.database];
	}
	return _connectionString;
}

- (NSString *)identifier {
	return [self.class Identifier];
}

+ (NSString *)Identifier {
	return @"TDS";
}

- (BOOL)requiresCredentials {
	return YES;
}

@end
