//
//  MADPostgresConnection.m
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADPostgresConnection.h"
#import "MADDatabaseConnectionPostgres.h"

#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <string.h>

static NSString * const MADPostgresErrorDomain = @"MADDatabasePostgres";

@interface MADPostgresConnection ()

@property (nonatomic, readwrite, nullable) PGconn *pgConn;
@property (nonatomic, readwrite, copy, nullable) NSString *errorMessage;

@end

@implementation MADPostgresConnection

- (void)dealloc {
	[self disconnect];
}

- (BOOL)isConnected {
	return (_pgConn != NULL && PQstatus(_pgConn) == CONNECTION_OK);
}

- (BOOL)connectWithHost:(NSString *)host
				   port:(int32_t)port
				   user:(NSString *)user
			   password:(nullable NSString *)password
			   database:(NSString *)database
				  error:(NSError *_Nullable __autoreleasing *_Nullable)error {
	[self disconnect];

	int32_t resolvedPort = port > 0 ? port : DEFAULT_POSTGRES_PORT;
	NSString *portString = [[NSString alloc] initWithFormat:@"%d", (int)resolvedPort];
	const char *cHost = (host ?: @"").UTF8String;
	const char *cPort = portString.UTF8String;
	const char *cUser = (user ?: @"").UTF8String;
	const char *cPassword = (password ?: @"").UTF8String;
	const char *cDatabase = (database ?: @"").UTF8String;

	const char *keywords[] = {
		"host",
		"port",
		"dbname",
		"user",
		"password",
		"connect_timeout",
		"client_encoding",
		"application_name",
		NULL
	};
	const char *values[] = {
		cHost,
		cPort,
		cDatabase,
		cUser,
		cPassword,
		"5",
		"UTF8",
		"mad",
		NULL
	};

	_pgConn = PQconnectdbParams(keywords, values, 0);
	if (_pgConn == NULL || PQstatus(_pgConn) != CONNECTION_OK) {
		const char *rawErr = _pgConn != NULL ? PQerrorMessage(_pgConn) : "PQconnectdbParams returned NULL";
		NSString *msg = (rawErr != NULL && rawErr[0] != '\0')
			? [[NSString alloc] initWithUTF8String:rawErr]
			: @"PostgreSQL connection failed.";
		if (msg == nil) {
			msg = @"PostgreSQL connection failed.";
		}
		self.errorMessage = msg;
		if (_pgConn != NULL) {
			PQfinish(_pgConn);
			_pgConn = NULL;
		}
		if (error != NULL) {
			*error = [NSError errorWithDomain:MADPostgresErrorDomain
										 code:1002
									 userInfo:@{
				NSLocalizedDescriptionKey : @"PostgreSQL connection failed.",
				NSLocalizedFailureReasonErrorKey : msg,
				@"PostgresHostnameKey" : host ?: @"",
				@"PostgresDatabaseKey" : database ?: @"",
			}];
		}
		return NO;
	}

	self.errorMessage = nil;
	return YES;
}

- (void)disconnect {
	if (_pgConn != NULL) {
		PQfinish(_pgConn);
		_pgConn = NULL;
	}
}

- (nullable NSString *)escapeLiteral:(nullable NSString *)literal {
	if (![self isConnected] || literal == nil) return nil;
	const char *utf8 = literal.UTF8String;
	if (utf8 == NULL) return nil;
	char *escaped = PQescapeLiteral(_pgConn, utf8, strlen(utf8));
	if (escaped == NULL) return nil;
	NSString *result = [[NSString alloc] initWithUTF8String:escaped];
	PQfreemem(escaped);
	return result;
}

- (nullable NSString *)escapeIdentifier:(nullable NSString *)identifier {
	if (![self isConnected] || identifier == nil) return nil;
	const char *utf8 = identifier.UTF8String;
	if (utf8 == NULL) return nil;
	char *escaped = PQescapeIdentifier(_pgConn, utf8, strlen(utf8));
	if (escaped == NULL) return nil;
	NSString *result = [[NSString alloc] initWithUTF8String:escaped];
	PQfreemem(escaped);
	return result;
}

@end
