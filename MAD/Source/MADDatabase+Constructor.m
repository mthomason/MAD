//
//  MADDatabase+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDatabase+Constructor.h"
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>

@implementation MADDatabase (Constructor)

// The driver is looked up, not imported: which drivers a process has is a matter
// of what it links, and the registry is what a driver says there
// (MADDatabaseDriverRegistry.h; ROADMAP.md §5.1).  A type with no registered
// driver builds nothing, the way the old switch's default did -- but the driver
// being absent is now a link fact rather than a compile error here.
+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {

	Class <MADDatabaseDriver> driver = [MADDatabaseDriverRegistry driverClassForType: connection.databaseType];
	MADDatabase *result = [[[driver databaseClass] alloc] init];

	[result setDatabaseConnection: connection];

	if ([result respondsToSelector: @selector(openDatabase)]) {
		[result openDatabase];
	}

	return result;
}

- (void)openDatabase {

}

@end
