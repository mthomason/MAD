//
//  MADMySQLConnection.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLConnection.h"

#import "MADMySQLServer.h"
#import "MADMySQLException.h"
#import "MADMySQLCommitException.h"
#import "MADMySQLRollbackException.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>

#import <mysql.h>
#import <stdlib.h>
#import <string.h>

static NSString *const MADMySQLConnectErrorDomain = @"MADDatabaseMySQL";
static NSString *const MADMySQLErrorNumberKey = @"MySQLErrorNumberKey";
static NSString *const MADMySQLHostnameKey = @"MySQLHostnameKey";
static NSString *const MADMySQLSchemaKey = @"MySQLSchemaKey";

@interface MADMySQLConnection ()

	@property(nonatomic, assign, readwrite) BOOL transactionsEnabled;
	@property(nonatomic, readonly) BOOL connected;
	@property(nonatomic, readonly) MYSQL *mysqlHandle;

@end

@implementation MADMySQLConnection

#pragma mark -
#pragma mark Factories

+ (MADMySQLConnection *)connectToServers:(NSArray *)arrayOfServers {
	for (MADMySQLServer *server in arrayOfServers) {
		MADMySQLConnection *connection = [self connectToServer:server];
		if (connection != nil) {
			return connection;
		}
	}
	return nil;
}

+ (MADMySQLConnection *)connectToServer:(MADMySQLServer *)server {
	return [self connectToServer:server error:NULL];
}

+ (MADMySQLConnection *)connectToServer:(MADMySQLServer *)server error:(NSError * __autoreleasing *)error {
	MADMySQLConnection *connection = [[self alloc] init];
	if ([connection openWithServer:server]) {
		return connection;
	}
	// The failed connection carries the server's message on its handle; the
	// caller's error pointer is optional, so the write must be guarded.
	if (error != NULL) {
		*error = [connection connectionFailureError];
	}
	return nil;
}

#pragma mark -
#pragma mark Lifecycle

// The handle's storage is allocated here and handed to mysql_init, which
// leaves the client's free_me flag off: mysql_close tears down the session
// but does not free the struct, so the free below is this class's job.

- (instancetype)init {
	if ((self = [super init])) {
		_mysqlHandle = calloc(1, sizeof(MYSQL));
		mysql_init(_mysqlHandle);
	}
	return self;
}

- (void)dealloc {
	if (_mysqlHandle != NULL) {
		mysql_close(_mysqlHandle);
		free(_mysqlHandle);
		_mysqlHandle = NULL;
	}
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"MADMySQLConnection (connected: %@, host: %@)",
			self.connected ? @"YES" : @"NO", self.server.host ?: @"(none)"];
}

#pragma mark -
#pragma mark Connecting

- (BOOL)openWithServer:(MADMySQLServer *)server {
	_server = server;

	if (server.connectionTimeout > 0) {
		unsigned int timeout = server.connectionTimeout;
		mysql_options(_mysqlHandle, MYSQL_OPT_CONNECT_TIMEOUT, &timeout);
	}

	MYSQL *handle = mysql_real_connect(_mysqlHandle,
									   server.host.UTF8String,
									   server.user.UTF8String,
									   server.password.UTF8String,
									   server.schema.UTF8String,
									   server.port,
									   NULL,
									   server.flags);
	if (handle == NULL) {
		return NO;
	}
	_connected = YES;
	return YES;
}

- (NSError *)connectionFailureError {
	unsigned int code = mysql_errno(_mysqlHandle);
	const char *message = mysql_error(_mysqlHandle);
	NSDictionary *userInfo = @{
		MADMySQLErrorNumberKey: @(code),
		MADMySQLHostnameKey: self.server.host ?: @"",
		MADMySQLSchemaKey: self.server.schema ?: @"",
		NSLocalizedDescriptionKey: [[NSString alloc] initWithUTF8String:message],
	};
	return [NSError errorWithDomain:MADMySQLConnectErrorDomain code:(NSInteger)code userInfo:userInfo];
}

#pragma mark -
#pragma mark State

- (void *)connection {
	return (void *)_mysqlHandle;
}

- (unsigned int)errorNumber {
	return mysql_errno(_mysqlHandle);
}

- (const char *)errorText {
	return mysql_error(_mysqlHandle);
}

#pragma mark -
#pragma mark Transactions

- (void)enableTransactions {
	if (mysql_autocommit(_mysqlHandle, 0)) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL could not start a transaction: %s",
		 mysql_error(_mysqlHandle)];
	}
	self.transactionsEnabled = YES;
}

- (void)disableTransactions {
	if (mysql_autocommit(_mysqlHandle, 1)) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL could not end the transaction: %s",
		 mysql_error(_mysqlHandle)];
	}
	self.transactionsEnabled = NO;
}

- (void)commitTransaction {
	if (mysql_commit(_mysqlHandle)) {
		[MADMySQLCommitException raiseConnection:self withFormat:@"MySQL commit failed: %s",
		 mysql_error(_mysqlHandle)];
	}
}

- (void)rollbackTransaction {
	if (mysql_rollback(_mysqlHandle)) {
		[MADMySQLRollbackException raiseConnection:self withFormat:@"MySQL rollback failed: %s",
		 mysql_error(_mysqlHandle)];
	}
}

#pragma mark -
#pragma mark Session settings

- (void)enableStrictSql {
	const char *sql = "SET SESSION sql_mode = IF(LOCATE('STRICT_ALL_TABLES', @@sql_mode), "
					  "@@sql_mode, CONCAT(@@sql_mode, ',STRICT_ALL_TABLES'))";
	if (mysql_real_query(_mysqlHandle, sql, strlen(sql))) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL could not enable strict SQL mode: %s",
		 mysql_error(_mysqlHandle)];
	}
}

- (void)disableTriggers {
	const char *sql = "SET @DISABLE_TRIGGERS = 1";
	if (mysql_real_query(_mysqlHandle, sql, strlen(sql))) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL could not disable triggers: %s",
		 mysql_error(_mysqlHandle)];
	}
}

- (void)enableTriggers {
	const char *sql = "SET @DISABLE_TRIGGERS = NULL";
	if (mysql_real_query(_mysqlHandle, sql, strlen(sql))) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL could not enable triggers: %s",
		 mysql_error(_mysqlHandle)];
	}
}

- (void)startIdle {
	if (mysql_ping(_mysqlHandle)) {
		[MADMySQLException raiseConnection:self withFormat:@"MySQL ping failed: %s",
		 mysql_error(_mysqlHandle)];
	}
}

#pragma mark -
#pragma mark Escaping

- (NSString *)mysqlEscapeString:(NSString *)string {
	if (string == nil) {
		return nil;
	}
	const char *source = string.UTF8String;
	unsigned long sourceLength = strlen(source);
	// An escape can double every character.
	char *buffer = malloc(sourceLength * 2 + 1);
	if (buffer == NULL) {
		return nil;
	}
	unsigned long escapedLength = mysql_real_escape_string(_mysqlHandle, buffer, source, sourceLength);
	NSString *escaped = [[NSString alloc] initWithBytes:buffer length:escapedLength encoding:NSUTF8StringEncoding];
	free(buffer);
	return escaped;
}

@end
