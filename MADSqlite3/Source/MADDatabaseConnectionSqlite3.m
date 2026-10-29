//
//  MADDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionSqlite3.h"
#import "MADDatabaseSqlite3.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSURL.h>

#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADAPI/MADConnectionsPropertiesProtocol.h>

@implementation MADDatabaseConnectionSqlite3

// A linked driver is a registered driver: the constructor learns Sqlite3 is here
// from this, not from an import (MADDatabaseDriverRegistry.h).
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

+ (MADDatabaseType)databaseType {
	return MADDatabaseTypeSqlite3;
}

+ (Class)databaseClass {
	return [MADDatabaseSqlite3 class];
}

+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
									 database:(NSString *)database
										 port:(NSInteger)port {
	// A file-backed driver has no host to dial; the type-based constructor built an
	// empty connection for this type, and it still does.
	return [[self alloc] initWithUrl: nil];
}

+ (instancetype)newDatabaseConnectionWithURL:(NSURL *)url {
	return [[self alloc] initWithUrl: url];
}

@synthesize databaseUrl = _databaseUrl;

@dynamic identifier;

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	NSFileManager *fm = [NSFileManager defaultManager];
	if (credentals.host.length > 0 && [credentals.host hasPrefix:@"/"] && [fm fileExistsAtPath:credentals.host]) {
		return [[self alloc] initWithUrl:[NSURL fileURLWithPath:credentals.host isDirectory:NO]];
	}
	if (credentals.database.length > 0 && [credentals.database hasPrefix:@"/"] && [fm fileExistsAtPath:credentals.database]) {
		return [[self alloc] initWithUrl:[NSURL fileURLWithPath:credentals.database isDirectory:NO]];
	}
	NSString *groupID = [MADApplication groupIdentifier];
	NSURL *baseDir = nil;
#if __APPLE__
	if (groupID.length > 0 && [fm containerURLForSecurityApplicationGroupIdentifier:groupID] != nil) {
		baseDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:groupID];
	} else {
		baseDir = [MADURLFactory newURLForLocalApplicationSupportDirectory];
	}
#else
	baseDir = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:groupID];
#endif
	NSURL *dbUrl = credentals.database.length > 0 ? [baseDir URLByAppendingPathComponent:credentals.database isDirectory:NO] : baseDir;
	if (credentals.database.length > 0 && ![fm fileExistsAtPath:dbUrl.path]) {
		NSURL *bundled = [[NSBundle mainBundle] URLForResource:credentals.database.stringByDeletingPathExtension
												 withExtension:credentals.database.pathExtension];
		if (bundled != nil) {
			dbUrl = bundled;
		}
	}
	return [[self alloc] initWithUrl:dbUrl];
}

- (instancetype)initWithUrl:(NSURL *)url {
	if (self = [super init]) {
		_databaseUrl = url.copy;
		_databaseType = MADDatabaseTypeSqlite3;
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] allocWithZone:zone] initWithUrl:self.databaseUrl];
	return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder: coder];
	[coder encodeObject:_databaseUrl forKey:NSStringFromSelector(@selector(databaseUrl))];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder: decoder]) {
		_databaseUrl = [decoder decodeObjectOfClass:[NSURL class]
											forKey:NSStringFromSelector(@selector(databaseUrl))];
	}
	return self;
}

- (NSString *)connectionString {
	if (!_connectionString) {
		_connectionString = [[NSString alloc] initWithFormat:@"(%@)[%@]",
							 self.identifier, self.databaseUrl];
	}
	return _connectionString;
;
}

- (NSString *)identifier {
	return [[self class] Identifier];
}

+ (NSString *)Identifier {
	return @"Sqlite 3";
}

- (MADDatabaseType)databaseType {
	return _databaseType;
}

- (BOOL)requiresCredentials {
	return NO;
}

@end
