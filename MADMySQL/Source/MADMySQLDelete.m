//
//  MADMySQLDelete.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLDelete.h"

#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

#import <Foundation/NSString.h>

#import <mysql.h>
#import <string.h>

@interface MADMySQLDelete ()

	@property(nonatomic, strong, readwrite) MADMySQLConnection *connection;
	@property(nonatomic, strong, readwrite) NSNumber *affectedRows;

@end

@implementation MADMySQLDelete

+ (MADMySQLDelete *)deleteWithConnection:(MADMySQLConnection *)aConnection {
	if (aConnection == nil) {
		[MADMySQLException raiseConnection:nil withFormat:@"A delete requires a connection."];
	}
	MADMySQLDelete *delete = [[self alloc] init];
	delete.connection = aConnection;
	return delete;
}

- (void)execute {
	if (self.tableName == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"Delete is missing table name"];
	}
	if (self.qualifier == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"Delete is unqualified. Use TRUNCATE to wipe out tables"];
	}

	const char *sql = self.command.UTF8String;
	if (mysql_real_query(self.connection.connection, sql, strlen(sql))) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %s.",
		 mysql_errno(self.connection.connection), mysql_error(self.connection.connection)];
	}
	self.affectedRows = @(mysql_affected_rows(self.connection.connection));
}

// The full statement, pasted together verbatim; a nil qualifier formats as
// the literal "(null)", which -execute refuses to run.

- (NSString *)command {
	return [[NSString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@", self.tableName, self.qualifier];
}

@end
