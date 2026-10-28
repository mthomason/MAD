//
//  MADDatabaseConnectionPostgres.m
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionPostgres.h"
#import "MADDatabasePostgres.h"

#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

@implementation MADDatabaseConnectionPostgres

+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass:self];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

+ (MADDatabaseType)databaseType {
	return MADDatabaseTypePostgres;
}

+ (Class)databaseClass {
	return [MADDatabasePostgres class];
}

+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {
	return [[self alloc] initWithHost:host database:database andPort:port];
}

@synthesize database = _database;
@synthesize server = _server;
@synthesize host = _host;
@synthesize port = _port;

@dynamic identifier;

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	return [[self alloc] initWithHost:credentals.host
							 database:credentals.database
							  andPort:credentals.port];
}

+ (instancetype)connectionWithHost:(NSString *)host
							  port:(int32_t)port
					   andDatabase:(NSString *)database {
	return [[self alloc] initWithHost:host port:port andDatabase:database];
}

+ (instancetype)connectionWithHost:(NSString *)host
					   andDatabase:(NSString *)database {
	return [[self alloc] initWithHost:host andDatabase:database];
}

- (instancetype)initWithHost:(NSString *)host
					database:(NSString *)database
					 andPort:(NSInteger)port {
	if (self = [super init]) {
		_server = [host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		_host = [host copy];
		_database = [database copy];
		_port = (port <= 0) ? DEFAULT_POSTGRES_PORT : port;
		_databaseType = MADDatabaseTypePostgres;
		_requiresCredentials = YES;
		_identifier = [[self class] Identifier];
	}
	return self;
}

- (instancetype)initWithHost:(NSString *)host
						port:(int32_t)port
				 andDatabase:(NSString *)database {
	return [self initWithHost:host database:database andPort:(NSInteger)port];
}

- (instancetype)initWithHost:(NSString *)host
				 andDatabase:(NSString *)database {
	return [self initWithHost:host database:database andPort:DEFAULT_POSTGRES_PORT];
}

- (instancetype)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithHost:_host
												  database:_database
												   andPort:_port];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:_host forKey:NSStringFromSelector(@selector(host))];
	[coder encodeObject:_database forKey:NSStringFromSelector(@selector(database))];
	[coder encodeInteger:_port forKey:NSStringFromSelector(@selector(port))];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		_host = [decoder decodeObjectOfClass:[NSString class]
									  forKey:NSStringFromSelector(@selector(host))];
		_database = [decoder decodeObjectOfClass:[NSString class]
										  forKey:NSStringFromSelector(@selector(database))];
		NSInteger decodedPort = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(port))];
		_port = (decodedPort <= 0) ? DEFAULT_POSTGRES_PORT : decodedPort;
		_server = [_host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		_databaseType = MADDatabaseTypePostgres;
		_requiresCredentials = YES;
		_identifier = [[self class] Identifier];
	}
	return self;
}

- (NSString *)identifier {
	return [[self class] Identifier];
}

+ (NSString *)Identifier {
	return @"PostgreSQL";
}

- (NSString *)connectionString {
	return [[NSString alloc] initWithFormat:@"(%@)[%@:%ld]%@", self.identifier, self.server, (long)_port, _database];
}

- (MADDatabaseType)databaseType {
	return _databaseType;
}

- (BOOL)requiresCredentials {
	return YES;
}

@end
