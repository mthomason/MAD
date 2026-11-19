//
//  MADDatabaseConnection+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDatabaseConnection+Constructor.h"
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <objc/runtime.h>

// The driver is looked up, not imported: which drivers a process has is a matter
// of what it links, and the registry is what a driver says there
// (MADDatabaseDriverRegistry.h; docs/project/ROADMAP.md §5.1).  A type with no registered
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
	return [self newDatabaseConnection:credentals documentURL:nil];
}

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals
						  documentURL:(NSURL *)documentURL {
	Class <MADDatabaseDriver> driver = MADDriverForType(credentals.databaseType);
	if (documentURL != nil) {
		// Every driver inherits this category method, so respondsToSelector: is
		// true even for a driver that does not answer the optional message.
		// Dispatching to such a driver calls this method again with the same
		// class -- unbounded recursion -- so compare the implementation a driver
		// actually resolves against this one.
		SEL selector = @selector(newDatabaseConnection:documentURL:);
		Method driverMethod = class_getClassMethod((Class)driver, selector);
		Method baseMethod = class_getClassMethod([MADDatabaseConnection class], selector);
		if (driverMethod != NULL && baseMethod != NULL &&
			method_getImplementation(driverMethod) != method_getImplementation(baseMethod)) {
			return [driver newDatabaseConnection:credentals documentURL:documentURL];
		}
	}
	return [driver newDatabaseConnection:credentals];
}

+ (NSString *)Identifier:(MADDatabaseType)databaseType {
	return [MADDriverForType(databaseType) Identifier];
}

@end
