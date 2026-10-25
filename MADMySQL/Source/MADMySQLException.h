//
//  MADMySQLException.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLException_h
#define MAD_MADMySQLException_h

#import <Foundation/NSException.h>

@class MADMySQLConnection;

/*
	The exception the connector layer raises when a statement fails on the
	server. The connection that failed travels in the exception's userInfo
	under "MADMySQLConnection"; the commit and rollback failures have their
	own subclasses so a caller can tell the two apart.
 */
@interface MADMySQLException : NSException

	+ (void)raiseConnection:(MADMySQLConnection *)aConnection withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3) __attribute__((noreturn));
	+ (NSError *)errorWithConnection:(MADMySQLConnection *)connection domain:(NSString *)domain andCode:(NSInteger)code;

@end

#endif
