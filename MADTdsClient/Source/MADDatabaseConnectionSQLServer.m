//
//  MADDatabaseConnectionSQLServer.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionSQLServer.h"
#import "MADDatabaseSQLServer.h"
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>
#import <MADAPI/MADDatabaseType.h>

@implementation MADDatabaseConnectionSQLServer

// A linked driver is a registered driver: the constructor learns SQL Server is
// here from this, not from an import (MADDatabaseDriverRegistry.h).
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}

+ (BOOL)supportsSecureCoding {
	return YES;
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

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder: coder];
	[coder encodeObject:_host forKey:NSStringFromSelector(@selector(host))];
	[coder encodeObject:_server forKey:NSStringFromSelector(@selector(server))];
	[coder encodeObject:_database forKey:NSStringFromSelector(@selector(database))];
	[coder encodeInteger:_port forKey:NSStringFromSelector(@selector(port))];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder: decoder]) {
		_host = [decoder decodeObjectOfClass:[NSString class]
									  forKey:NSStringFromSelector(@selector(host))];
		_server = [decoder decodeObjectOfClass:[NSString class]
										forKey:NSStringFromSelector(@selector(server))];
		_database = [decoder decodeObjectOfClass:[NSString class]
										  forKey:NSStringFromSelector(@selector(database))];
		_port = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(port))];
	}
	return self;
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

- (MADDatabaseType)databaseType {
	return _databaseType;
}

- (BOOL)requiresCredentials {
	return YES;
}

@end
