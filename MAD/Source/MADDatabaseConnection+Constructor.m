//
//  MADDatabaseConnection+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseConnection+Constructor.h"
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>

// The driver is looked up, not imported: which drivers a process has is a matter
// of what it links, and the registry is what a driver says there
// (MADDatabaseDriverRegistry.h; ROADMAP.md §5.1).  A type with no registered
// driver is asserted and answers nil, as the old switch's default did.
static Class <MADDatabaseDriver> MADDriverForType(MADDatabaseType databaseType) {
	Class <MADDatabaseDriver> driver = [MADDatabaseDriverRegistry driverClassForType: databaseType];
	NSCAssert(driver != Nil, @"No database driver is registered for type %d", (int)databaseType);
	return driver;
}

@implementation MADDatabaseConnection (Constructor)

+ (instancetype)newDatabaseConnectionWithType:(MADDatabaseType)databaseType
										 host:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {

	Class <MADDatabaseDriver> driver = MADDriverForType(databaseType);
	return [driver newDatabaseConnectionWithHost: host database: database port: port];
}

+ (instancetype)newDatabaseConnectionForUrl:(NSURL *)url {
	return [MADDriverForType(MADDatabaseTypeSqlite3) newDatabaseConnectionWithURL: url];
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
	return [MADDriverForType(credentals.databaseType) newDatabaseConnection: credentals];
}

+ (NSString *)Identifier:(MADDatabaseType)databaseType {
	return [MADDriverForType(databaseType) Identifier];
}

@end
