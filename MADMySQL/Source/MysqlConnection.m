//
//  MysqlConnection.m
//  mysql_connector
//
//  Created by Karl Kraft on 5/21/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlConnection.h"
#import "MysqlServer.h"
#import "MysqlCommitException.h"
#import "MysqlRollbackException.h"
#import <MADFoundation/madlog.h>

#import <mysql.h>

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSError.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSThread.h>
#import <string.h>


@interface MysqlConnection ()

	@property (nonatomic, readonly) MYSQL *connection;

@end

@implementation MysqlConnection

@synthesize transactionsEnabled, server;

// Common internal connection logic helper
// This new helper function is introduced to ensure parity and reduce code duplication.
// It won't change external behavior but cleans up internal logic.
+ (nullable MYSQL *)internal_connectToServer:(nonnull MysqlServer *)aServer
									outError:(NSError * __autoreleasing * _Nullable)outError {
	// Log inputs carefully, especially server details.
	// Avoid logging password directly. MysqlServer's description might be okay if it redacts sensitive info.
	// For now, logging non-sensitive parts.
	MADLogDebug("MysqlConnection: Attempting internal_connectToServer: host=\"%@\", port=%u, user=\"%@\", schema=\"%@\"",
				aServer.host, aServer.port, aServer.user, aServer.schema);
	
	MYSQL *mysqlHandle = calloc(1, sizeof(MYSQL));
	if (!mysqlHandle) {
		MADLogError("MysqlConnection: Failed to calloc memory for MYSQL handle.");
		if (outError) {
			*outError = [NSError errorWithDomain:@"MADDatabaseMySQL"
											code:mysql_errno(NULL) // Or a custom code for memory allocation failure
										userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to allocate memory for MySQL connection.", @"NSError description: the MySQL client handle could not be allocated")}];
		}
		return NULL;
	}
	mysql_init(mysqlHandle);
	
	// FIXME: Add timeout feature (original comment retained)
	// unsigned int timeout = aServer.connectionTimeout;
	// mysql_options(mysqlHandle, MYSQL_OPT_CONNECT_TIMEOUT, &timeout);
	
	const char *host_utf8 = (aServer.host).UTF8String;
	const char *user_utf8 = (aServer.user).UTF8String;
	const char *password_utf8 = (aServer.password).UTF8String; // Be careful if this gets logged inadvertently by other means
	const char *schema_utf8 = (aServer.schema).UTF8String;
	
	if (!mysql_real_connect(mysqlHandle,
							host_utf8,
							user_utf8,
							password_utf8,
							schema_utf8,
							aServer.port,
							NULL,         // default socket
							aServer.flags)) {
		
		unsigned int errNum = mysql_errno(mysqlHandle);
		const char *errMsg = mysql_error(mysqlHandle);
		MADLogError("MysqlConnection: Failed to connect to host=\"%@\" (Error %u: %s)", aServer.host, errNum, errMsg);
		
		if (outError) {
			NSString *errorDescription = [NSString stringWithUTF8String:errMsg];
			if (!errorDescription || errorDescription.length == 0) {
				errorDescription = NSLocalizedString(@"Failed to connect to MySQL server (unknown error).", @"NSError description: the MySQL client returned no error text");
			}
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription,
									   @"MySQLHostnameKey": aServer.host ?: @"<unknown_host>",
									   @"MySQLPortKey": @(aServer.port),
									   @"MySQLUserKey": aServer.user ?: @"<unknown_user>",
									   @"MySQLSchemaKey": aServer.schema ?: @"<unknown_schema>",
									   @"MySQLErrorNumberKey": @(errNum)};
			*outError = [NSError errorWithDomain:@"MADDatabaseMySQL" code:errNum userInfo:userInfo];
		}
		mysql_close(mysqlHandle); // Close if init was successful but connect failed
		free(mysqlHandle);        // Free allocated memory
		return NULL;
	} else {
		MADLogDebug("MysqlConnection: Successfully connected to host=\"%@\"", aServer.host);
	}
	
	if (mysql_set_character_set(mysqlHandle, "utf8") != 0) { // 0 is success
		MADLogInfo("MysqlConnection: Failed to set client character set to utf8 for host=\"%@\". Error %u: %s",
				   aServer.host, mysql_errno(mysqlHandle), mysql_error(mysqlHandle));
		// Not usually a fatal error, so we might continue.
	} else {
		MADLogDebug("MysqlConnection: Client character set utf8 set for host=\"%@\". Current: %s",
					aServer.host, mysql_character_set_name(mysqlHandle));
	}
	return mysqlHandle;
}

+ (MysqlConnection *)connectToServer:(MysqlServer *)server {
	MADLogDebug("MysqlConnection: +connectToServer (no error ptr) called for server: %@", server.host);
	
	NSError *connectionError = nil; // Internal error tracking
	MYSQL *mysqlHandle = [self internal_connectToServer:server outError:&connectionError];
	
	if (!mysqlHandle) {
		// The error is already logged by internal_connectToServer via MADLogError
		// No external NSError to populate here.
		return nil;
	}
	
	MysqlConnection *newObject = [[self alloc] init];
	newObject->_connection = mysqlHandle; // Assign the handle
	newObject->server = server; // Keep a reference to the server config
	
	MADLogDebug("MysqlConnection: Instance <%p> created successfully for server: %@", newObject, server.host);
	return newObject;
}

+ (MysqlConnection *)connectToServer:(MysqlServer *)server error:(NSError * __autoreleasing *)error {
	MADLogDebug("MysqlConnection: +connectToServer (with error ptr) called for server: %@", server.host);
	
	NSError *connectionError = nil;
	MYSQL *mysqlHandle = [self internal_connectToServer:server outError:&connectionError]; // Pass the error pointer
	if (connectionError != nil && error != NULL) {
		*error = [connectionError copy];
	}
	
	if (!mysqlHandle) {
		// Error is logged by internal_connectToServer and *error is populated.
		return nil;
	}
	
	MysqlConnection *newObject = [[self alloc] init];
	newObject->_connection = mysqlHandle;
	newObject->server = server;
	
	MADLogDebug("MysqlConnection: Instance <%p> created successfully for server: %@", newObject, server.host);
	if (error) *error = nil; // Explicitly clear error on success
	return newObject;
}

- (void)dealloc {
	MADLogDebug("MysqlConnection <%p> dealloc: Closing connection to server: %@",
				self, self.server.host);
	if (_connection) {
		mysql_close(_connection);
		free(_connection);
		_connection = NULL;
	}
}

- (NSString *)mysqlEscapeString:(NSString *)string {
	if (!string) {
		MADLogDebug("MysqlConnection <%p:%@> mysqlEscapeString: called with nil string. Returning nil.", self, [self class]);
		return nil;
	}
	if (!self.connection) {
		MADLogError("MysqlConnection <%p:%@> mysqlEscapeString: No valid connection available. Cannot escape string.", self, [self class]);
		// Or throw an exception, depending on desired behavior for calling this on a disconnected instance
		return nil; // Or consider returning the original string with a warning, though that's risky for SQL injection
	}
	const char *ch = string.UTF8String;
	char *buf=malloc(strlen(ch)*2+1);
	if (!buf) {
		MADLogError("MysqlConnection <%p:%@> mysqlEscapeString: Failed to allocate memory for escape buffer.", self, [self class]);
		return nil;
	}
	unsigned long escapeStringSize = mysql_real_escape_string(self.connection, buf, ch, strlen(ch));
	if (escapeStringSize < 0) {
		MADLogError("MysqlConnection <%p:%@> mysqlEscapeString: mysql_real_escape_string failed.", self, [self class]);
	}
	NSString *retval=@(buf);
	free(buf);
	return retval;
}

- (unsigned int)errorNumber {
	return mysql_errno(self.connection);
}

- (const char *)errorText {
	return mysql_error(self.connection);
}

+ (MysqlConnection *)connectToServers:(NSArray<MysqlServer *> *)arrayOfServers {
	MADLogDebug("MysqlConnection: +connectToServers called with %lu servers.", (unsigned long)arrayOfServers.count);
	for (MysqlServer *aServer in arrayOfServers) {
		MADLogDebug("MysqlConnection:   Attempting connection to server: %@", aServer.host);
		// Using the version without the explicit error pointer, as this method doesn't propagate it.
		// Internal errors will still be logged by MADLogError within connectToServer:
		MysqlConnection *aConnection = [self connectToServer:aServer];
		if (aConnection) {
			MADLogInfo("MysqlConnection:   Successfully connected to server: %@ (out of %lu attempts).",
					   aServer.host, (unsigned long)arrayOfServers.count);
			return aConnection;
		} else {
			MADLogInfo("MysqlConnection:   Failed to connect to server: %@. Trying next if available.", aServer.host);
		}
	}
	MADLogError("MysqlConnection: Failed to connect to any server in the provided list of %lu servers.", (unsigned long)arrayOfServers.count);
	return nil;
}


- (void)enableStrictSql {
	@synchronized (self) {
		if (mysql_query(_connection, "set sql_mode=strict_all_tables")) {
			[MysqlException raiseConnection:self
								 withFormat:@"Could not set sql_mode #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
		}
	}
}

- (void)enableTriggers {
	@synchronized (self) {
		if (mysql_query(_connection, "set @DISABLE_TRIGGERS = NULL")) {
			[MysqlException raiseConnection:self
								 withFormat:@"Could not enable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
		}
	}
}

- (void)disableTriggers {
	@synchronized (self) {
		if (mysql_query(_connection, "set @DISABLE_TRIGGERS = 1")) {
			[MysqlException raiseConnection:self
								 withFormat:@"Could not disable triggers #%d:%s",mysql_errno(_connection), mysql_error(_connection)];
		}
	}
}

- (void)enableTransactions {
	@synchronized (self) {
		transactionsEnabled=YES;
		mysql_autocommit(_connection, 0);
	}
}

- (void)disableTransactions {
	@synchronized (self) {
		transactionsEnabled=NO;
		mysql_autocommit(_connection, 1);
	}
}

- (void)commitTransaction {
	@synchronized (self) {
		if (mysql_commit(_connection)) {
			[MysqlCommitException raiseConnection:self withFormat:@"Transaction commit failed (%s)",mysql_error(_connection)];
		}
	}
}

- (void)rollbackTransaction {
	@synchronized (self) {
		if (mysql_rollback(_connection)) {
			[MysqlRollbackException raiseConnection:self withFormat:@"Transaction rollback failed (%s)",mysql_error(_connection)];
		}
	}
}

- (void)sendIdle __attribute__ ((noreturn)) {
	@autoreleasepool {
		[NSThread currentThread].name = @"Mysql Idle Thread";
		while (YES) {
			[NSThread sleepForTimeInterval:20.0];
			@synchronized (self) {
				mysql_query(_connection, "select 'MysqlConnect:idleTmer'");
				MYSQL_RES *theResults = mysql_use_result(_connection);
				mysql_free_result(theResults);
			}
		}
	}
}

- (void)startIdle {
	[self performSelectorInBackground: @selector(sendIdle)
						   withObject: nil];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p> Server: %@, Connected: %s",
			[self class], self, self.server.host, (_connection != NULL) ? "YES" : "NO"];
}

@end
