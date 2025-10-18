//
//  MADDatabaseConnection+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseConnection+Constructor.h"
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

@implementation MADDatabaseConnection (Constructor)

+ (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
										 host:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {

	switch (databaseType) {
		case MADDatabaseTypeSqlite3:
			return [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:nil];
		case MADDatabaseTypeTDS:
			return [[MADDatabaseConnectionSQLServer alloc] initWithHost: host
																 server: host
															   database: database
																andPort: port];
		case MADDatabaseTypeMySQL:
			return [[MADDatabaseConnectionMySql alloc] initWithHost: host
														   database: database
															andPort: port];
		default:
			NSAssert(NO, @"Unknown database type");
	}
	return nil;
}

+ (instancetype)newDatabaseConnectionForUrl:(NSURL *)url {
	return [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
}

+ (instancetype)newDatabaseConnectionForObject:(id)connectionObject {
	if ([connectionObject conformsToProtocol:@protocol(MADConnectionsPropertiesProtocol)]) {
		return [self newDatabaseConnection:connectionObject];
	} else if ([connectionObject isKindOfClass:[NSURL class]]) {
		return [self newDatabaseConnectionForUrl:connectionObject];
	}
	return nil;
}

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	switch (credentals.databaseType) {
		case MADDatabaseTypeSqlite3: return [MADDatabaseConnectionSqlite3 newDatabaseConnection:credentals];
		case MADDatabaseTypeTDS: return [MADDatabaseConnectionSQLServer newDatabaseConnection:credentals];
		case MADDatabaseTypeMySQL: return [MADDatabaseConnectionMySql newDatabaseConnection:credentals];
		default:
			NSAssert(NO, @"Unknown database type");
	}
	return nil;
}

+ (NSString *)Identifier:(MADDatabaseType)databaseType {
	switch (databaseType) {
		case MADDatabaseTypeSqlite3: return [MADDatabaseConnectionSqlite3 Identifier];
		case MADDatabaseTypeTDS: return [MADDatabaseConnectionSQLServer Identifier];
		case MADDatabaseTypeMySQL: return [MADDatabaseConnectionMySql Identifier];
		default:
			NSAssert(NO, @"Unknown database type");
	}
	return nil;
}

@end
