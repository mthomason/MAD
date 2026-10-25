//
//  MADMySQLException.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLException.h"

#import "MADMySQLConnection.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>

#import <mysql.h>

static NSString *const MADMySQLExceptionConnectionKey = @"MADMySQLConnection";

@implementation MADMySQLException

// The name of a raised exception is the raising class, so a commit failure
// and a rollback failure stay distinguishable even though both subclasses
// inherit this raise.

+ (void)raiseConnection:(MADMySQLConnection *)aConnection withFormat:(NSString *)format, ... {
	va_list arguments;
	va_start(arguments, format);
	NSString *reason = [[NSString alloc] initWithFormat:format arguments:arguments];
	va_end(arguments);

	NSDictionary *userInfo = nil;
	if (aConnection != nil) {
		userInfo = @{MADMySQLExceptionConnectionKey: aConnection};
	}

	NSException *exception = [[self alloc] initWithName:NSStringFromClass(self)
												 reason:reason
											   userInfo:userInfo];
	[exception raise];
}

// Builds the NSError the fetch hands back: the caller's domain and code, with
// the server's message as the description. The message is read off the live
// handle, so this needs a session.

+ (NSError *)errorWithConnection:(MADMySQLConnection *)connection domain:(NSString *)domain andCode:(NSInteger)code {
	const char *serverMessage = connection != nil ? mysql_error(connection.connection) : "";
	NSString *description = [[NSString alloc] initWithFormat:@"MySQL says: %s", serverMessage];
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey: description,
		NSLocalizedFailureReasonErrorKey: @"Executing Error",
	};
	return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

@end
