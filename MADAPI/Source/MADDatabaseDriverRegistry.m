//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseDriverRegistry.m
//  MADAPI
//
//  See MADDatabaseDriverRegistry.h for what this is and why it exists.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseDriverRegistry.h"

#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#import <dispatch/dispatch.h>

// Registration runs from +load, before anything else can be holding the
// registry, so the table needs no lock: writers are done before the first
// reader, and every reader only reads.
static NSMutableDictionary <NSNumber *, Class> *MADDatabaseDriverTable(void) {
	static NSMutableDictionary <NSNumber *, Class> *table = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		table = [NSMutableDictionary dictionary];
	});
	return table;
}

@implementation MADDatabaseDriverRegistry

+ (void)registerDriverClass:(Class <MADDatabaseDriver>)driverClass {
	if (driverClass == Nil) return;

	NSNumber *key = @([driverClass databaseType]);
	Class registered = MADDatabaseDriverTable()[key];
	if (registered == driverClass) return;

	if (registered != Nil) {
		// Two drivers claiming one type is a link-time mistake the process cannot
		// recover from -- the constructor would build one of them and never say
		// which -- so it stops here, where the stack names the new one.
		[NSException raise: NSInternalInconsistencyException
					format: @"%@ and %@ both register as database driver type %d",
							NSStringFromClass(registered), NSStringFromClass(driverClass), (int)key.intValue];
	}
	MADDatabaseDriverTable()[key] = driverClass;
}

+ (Class <MADDatabaseDriver>)driverClassForType:(MADDatabaseType)databaseType {
	return MADDatabaseDriverTable()[@(databaseType)];
}

+ (NSArray <Class <MADDatabaseDriver>> *)registeredDriverClasses {
	return MADDatabaseDriverTable().allValues;
}

@end
