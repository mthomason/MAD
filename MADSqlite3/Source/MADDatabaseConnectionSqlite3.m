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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSURL.h>

#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import <MADAPI/MADConnectionsPropertiesProtocol.h>

static BOOL MADSqliteFileIsValidNonEmptyAtPath(NSString *path) {
	if (path.length == 0) {
		return NO;
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (![fm fileExistsAtPath:path isDirectory:&isDir] || isDir) {
		return NO;
	}
	NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
	if ([attrs fileSize] == 0) {
		// Remove 0-byte artifact left by a prior SQLITE_OPEN_CREATE open on a missing path.
		[fm removeItemAtPath:path error:nil];
		return NO;
	}
	return YES;
}

static NSURL *MADSqliteDefaultApplicationSupportBaseDirectory(void) {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *groupID = [MADApplication groupIdentifier];
#if __APPLE__
	if (groupID.length > 0 && [fm containerURLForSecurityApplicationGroupIdentifier:groupID] != nil) {
		return [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:groupID];
	}
	return [MADURLFactory newURLForLocalApplicationSupportDirectory];
#else
	(void)fm;
	return [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID:groupID];
#endif
}

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

+ (instancetype)newDatabaseConnectionWithHost:(NSString *__unused)host
									 database:(NSString *__unused)database
										 port:(NSInteger __unused)port {
	// A file-backed driver has no host to dial; the type-based constructor built an
	// empty connection for this type, and it still does.
	return [[self alloc] initWithUrl: nil];
}

+ (instancetype)newDatabaseConnectionWithURL:(NSURL *)url {
	return [[self alloc] initWithUrl: url];
}

@synthesize databaseUrl = _databaseUrl;

@dynamic identifier;

+ (NSURL *)resolvedDatabaseURLForCredentials:(NSObject <MADConnectionsPropertiesProtocol> *)credentals
								 documentURL:(NSURL *)documentURL {
	NSURL *defaultBaseDir = MADSqliteDefaultApplicationSupportBaseDirectory();
	if (credentals == nil) {
		return defaultBaseDir;
	}

	// 1. Exact path in credentals.host or credentals.database (if absolute and non-empty).
	if (credentals.host.length > 0 && [credentals.host hasPrefix:@"/"] && MADSqliteFileIsValidNonEmptyAtPath(credentals.host)) {
		return [NSURL fileURLWithPath:credentals.host isDirectory:NO];
	}
	if (credentals.database.length > 0 && [credentals.database hasPrefix:@"/"] && MADSqliteFileIsValidNonEmptyAtPath(credentals.database)) {
		return [NSURL fileURLWithPath:credentals.database isDirectory:NO];
	}

	NSString *dbName = credentals.database.lastPathComponent;
	if (dbName.length == 0 && credentals.host.length > 0) {
		dbName = credentals.host.lastPathComponent;
	}

	// 2. Sibling file in the same directory as the .mad document.
	if (documentURL.isFileURL && dbName.length > 0) {
		NSURL *docDir = [documentURL URLByDeletingLastPathComponent];
		NSURL *siblingURL = [docDir URLByAppendingPathComponent:dbName isDirectory:NO];
		if (MADSqliteFileIsValidNonEmptyAtPath(siblingURL.path)) {
			return siblingURL;
		}
	}

	// 3. Local Application Support directory (group container and app-specific directory).
	if (dbName.length > 0) {
		NSURL *groupCandidate = [defaultBaseDir URLByAppendingPathComponent:dbName isDirectory:NO];
		if (MADSqliteFileIsValidNonEmptyAtPath(groupCandidate.path)) {
			return groupCandidate;
		}
#if __APPLE__
		NSURL *localAppSupport = [MADURLFactory newURLForLocalApplicationSupportDirectory];
		if (localAppSupport != nil) {
			NSURL *localCandidate = [localAppSupport URLByAppendingPathComponent:dbName isDirectory:NO];
			if (MADSqliteFileIsValidNonEmptyAtPath(localCandidate.path)) {
				return localCandidate;
			}
		}
#endif
	}

	// 4. App bundle resource, if present.
	if (dbName.length > 0) {
		NSURL *bundled = [[NSBundle mainBundle] URLForResource:dbName.stringByDeletingPathExtension
												 withExtension:dbName.pathExtension];
		if (bundled != nil && MADSqliteFileIsValidNonEmptyAtPath(bundled.path)) {
			return bundled;
		}
	}

	// Fallback when no non-empty file was found at any candidate location: preserve
	// the expected path so error alerts and the "Locate File…" dialog report it clearly.
	if (credentals.host.length > 0 && [credentals.host hasPrefix:@"/"]) {
		return [NSURL fileURLWithPath:credentals.host isDirectory:NO];
	}
	if (credentals.database.length > 0 && [credentals.database hasPrefix:@"/"]) {
		return [NSURL fileURLWithPath:credentals.database isDirectory:NO];
	}
	if (documentURL.isFileURL && dbName.length > 0) {
		return [[documentURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:dbName isDirectory:NO];
	}
	return dbName.length > 0 ? [defaultBaseDir URLByAppendingPathComponent:dbName isDirectory:NO] : defaultBaseDir;
}

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals
						  documentURL:(NSURL *)documentURL {
	NSURL *dbUrl = [self resolvedDatabaseURLForCredentials:credentals documentURL:documentURL];
	return [[self alloc] initWithUrl:dbUrl];
}

+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentals {
	return [self newDatabaseConnection:credentals documentURL:nil];
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
