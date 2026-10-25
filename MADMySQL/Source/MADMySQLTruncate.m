//
//  MADMySQLTruncate.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLTruncate.h"

#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

#import <Foundation/NSString.h>

#import <mysql.h>
#import <string.h>

@interface MADMySQLTruncate ()

	@property(nonatomic, strong, readwrite) MADMySQLConnection *connection;

@end

@implementation MADMySQLTruncate

// Unlike the insert/update/delete factories, these take a nil connection and
// hand back an object that fails at -execute instead. Deliberately left as
// the other three had it (see docs/project/BUGS.md, MADMySQL).

+ (MADMySQLTruncate *)truncateWithConnection:(MADMySQLConnection *)aConnection {
	MADMySQLTruncate *truncate = [[self alloc] init];
	truncate.connection = aConnection;
	return truncate;
}

+ (MADMySQLTruncate *)truncateWithConnection:(MADMySQLConnection *)aConnection forTable:(NSString *)aTableName {
	MADMySQLTruncate *truncate = [self truncateWithConnection:aConnection];
	truncate.tableName = aTableName;
	return truncate;
}

- (void)execute {
	if (self.tableName == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"Truncate is missing table name"];
	}
	if (self.connection == nil) {
		[MADMySQLException raiseConnection:nil withFormat:@"A truncate requires a connection."];
	}

	NSString *sql = [[NSString alloc] initWithFormat:@"TRUNCATE TABLE %@", self.tableName];
	if (mysql_real_query(self.connection.connection, sql.UTF8String, strlen(sql.UTF8String))) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %s.",
		 mysql_errno(self.connection.connection), mysql_error(self.connection.connection)];
	}
}

@end
