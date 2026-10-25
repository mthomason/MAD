//
//  MADMySQLConnection.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLConnection_h
#define MAD_MADMySQLConnection_h

#import <Foundation/NSObject.h>

@class MADMySQLServer;

/*
	A live session with one MySQL server. Connections are made with the
	connectToServer: family, which tries each server in turn; the transaction
	methods, the session toggles and the escape helper run on the wrapped
	MYSQL handle, synchronized so one connection is never driven from two
	threads at once.
 */
@interface MADMySQLConnection : NSObject

	@property(nonatomic, readonly) BOOL transactionsEnabled;
	@property(nonatomic, readonly) MADMySQLServer *server;

	- (unsigned int)errorNumber;
	- (const char *)errorText NS_RETURNS_INNER_POINTER;

	- (void *)connection NS_RETURNS_INNER_POINTER;

	+ (MADMySQLConnection *)connectToServers:(NSArray *)arrayOfServers;
	+ (MADMySQLConnection *)connectToServer:(MADMySQLServer *)server;
	+ (MADMySQLConnection *)connectToServer:(MADMySQLServer *)server error:(NSError * __autoreleasing *)error;

	- (void)enableTransactions;
	- (void)disableTransactions;
	- (void)commitTransaction;
	- (void)rollbackTransaction;

	- (void)enableStrictSql;

	- (void)enableTriggers;
	- (void)disableTriggers;

	- (void)startIdle;

	- (NSString *)mysqlEscapeString:(NSString *)string;

@end

#endif
