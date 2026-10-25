//
//  MADMySQLServer.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLServer.h"

#import <Foundation/NSString.h>

#import <mysql.h>

@implementation MADMySQLServer

- (instancetype)init {
	if ((self = [super init])) {
		self.host = @"localhost";
		self.user = @"username";
		self.password = @"password";
		self.schema = @"test";
		self.port = 3306;
		self.flags = CLIENT_FOUND_ROWS;
		self.connectionTimeout = 30;
	}
	return self;
}

// The password never appears in a description: servers end up in logs and
// diagnostics all over the app.

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"MADMySQLServer (host: %@, user: %@, schema: %@, port: %u)",
			self.host, self.user, self.schema, self.port];
}

@end
