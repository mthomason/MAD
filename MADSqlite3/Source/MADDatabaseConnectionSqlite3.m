//
//  MADDatabaseConnectionSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseConnectionSqlite3.h"
#import "MADDatabaseSqlite3.h"
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
@synthesize connectionString = _connectionString;
@synthesize databaseType = _databaseType;

@dynamic identifier;

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	// FIXME: When we start using Sqlite3 for users to make there own, we will also have to search
	//          the users documents directory.  Right now, only chinook.sqlite3 should be in the sqlite3 files types.
	//          Also hacked as fuck, because I'm using the mysql storage place to do this, but fuck it!
	NSURL *dbUrl = [[MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: [MADApplication groupIdentifier]] URLByAppendingPathComponent: credentals.database
																																	   isDirectory: NO];
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

- (BOOL)requiresCredentials {
	return NO;
}

@end
