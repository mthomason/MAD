//
//  MADMySQLUpdate.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLUpdate.h"

#import "MADMySQLConnection.h"
#import "MADMySQLException.h"
#import "MADMySQLLiteral.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>

#import <mysql.h>
#import <stdlib.h>
#import <string.h>

@interface MADMySQLUpdate ()

	@property(nonatomic, strong, readwrite) MADMySQLConnection *connection;
	@property(nonatomic, strong, readwrite) NSNumber *affectedRows;

@end

static void MADMySQLFreeBindings(MYSQL_BIND *bindings, void **buffers, NSUInteger count) {
	for (NSUInteger i = 0; i < count; i++) {
		free(buffers[i]);
		free(bindings[i].length);
		free(bindings[i].is_null);
	}
	free(buffers);
	free(bindings);
}

@implementation MADMySQLUpdate

+ (MADMySQLUpdate *)updateWithConnection:(MADMySQLConnection *)aConnection {
	if (aConnection == nil) {
		[MADMySQLException raiseConnection:nil withFormat:@"An update requires a connection."];
	}
	MADMySQLUpdate *update = [[self alloc] init];
	update.connection = aConnection;
	return update;
}

- (void)execute {
	// The three guards run before any session call, and in the same
	// nil-connection form: the caller's mistake, not a server state.
	if (self.table == nil) {
		[MADMySQLException raiseConnection:nil withFormat:@"table must be specified to perform an update"];
	}
	if (self.rowData == nil || self.rowData.count == 0) {
		[MADMySQLException raiseConnection:nil withFormat:@"row data must be specified to perform an update"];
	}
	if (self.qualifier == nil || self.qualifier.count == 0) {
		[MADMySQLException raiseConnection:nil withFormat:@"a qualifier must be specified to perform an update"];
	}

	for (id value in self.rowData.allValues) {
		if (!([value isKindOfClass:[NSNull class]] || [value isKindOfClass:[NSString class]] ||
			  [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSNumber class]])) {
			[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL update does not support a %@ value.",
			 [value class]];
		}
	}

	NSArray *columns = self.rowData.allKeys;
	NSString *statementText = [self statementForColumns:columns qualifier:self.qualifier];

	MYSQL_STMT *statement = mysql_stmt_init(self.connection.connection);
	if (statement == NULL) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL could not allocate a statement: %s",
		 mysql_error(self.connection.connection)];
	}

	const char *sql = statementText.UTF8String;
	if (mysql_stmt_prepare(statement, sql, strlen(sql))) {
		unsigned int code = mysql_stmt_errno(statement);
		NSString *message = [[NSString alloc] initWithUTF8String:mysql_stmt_error(statement)];
		mysql_stmt_close(statement);
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %@.", code, message];
	}

	NSUInteger count = columns.count;
	MYSQL_BIND *bindings = calloc(count, sizeof(MYSQL_BIND));
	void **buffers = calloc(count, sizeof(void *));
	if (bindings == NULL || buffers == NULL) {
		free(bindings);
		free(buffers);
		mysql_stmt_close(statement);
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL update could not allocate bindings."];
	}

	for (NSUInteger i = 0; i < count; i++) {
		[self fillBinding:&bindings[i] buffer:&buffers[i] withValue:self.rowData[columns[i]]];
	}

	if (mysql_stmt_bind_param(statement, bindings)) {
		unsigned int code = mysql_stmt_errno(statement);
		NSString *message = [[NSString alloc] initWithUTF8String:mysql_stmt_error(statement)];
		MADMySQLFreeBindings(bindings, buffers, count);
		mysql_stmt_close(statement);
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %@.", code, message];
	}

	int executeResult = mysql_stmt_execute(statement);
	unsigned int executeErrno = mysql_stmt_errno(statement);
	NSString *executeMessage = nil;
	if (executeResult) {
		executeMessage = [[NSString alloc] initWithUTF8String:mysql_stmt_error(statement)];
	}

	self.affectedRows = @(mysql_stmt_affected_rows(statement));

	MADMySQLFreeBindings(bindings, buffers, count);
	mysql_stmt_close(statement);

	if (executeResult) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %@.", executeErrno, executeMessage];
	}
}

// Builds "UPDATE `table` SET `a`=?, `b`=? WHERE `id`=1 AND `k`='escaped'"
// with the WHERE columns inlined by -qualifierExpressionForKey:value:.

- (NSString *)statementForColumns:(NSArray *)columns qualifier:(NSDictionary *)qualifier {
	NSMutableString *statement = [[NSMutableString alloc] initWithFormat:@"UPDATE `%@` SET ", self.table];
	for (NSUInteger i = 0; i < columns.count; i++) {
		if (i > 0) {
			[statement appendString:@", "];
		}
		[statement appendFormat:@"`%@`=?", columns[i]];
	}
	[statement appendString:@" WHERE "];

	NSArray *qualifierKeys = qualifier.allKeys;
	for (NSUInteger i = 0; i < qualifierKeys.count; i++) {
		if (i > 0) {
			[statement appendString:@" AND "];
		}
		[statement appendFormat:@"`%@`%@", qualifierKeys[i], [self qualifierExpressionForKey:qualifierKeys[i]
																						value:qualifier[qualifierKeys[i]]]];
	}
	return statement;
}

- (NSString *)qualifierExpressionForKey:(NSString *)key value:(id)value {
	if ([value isKindOfClass:[NSNull class]]) {
		return @" IS NULL";
	}
	if ([value isKindOfClass:[NSNumber class]]) {
		return [[NSString alloc] initWithFormat:@"=%@", value];
	}
	if ([value isKindOfClass:[MADMySQLLiteral class]]) {
		return [[NSString alloc] initWithFormat:@"=%@", [value string]];
	}
	NSString *escaped = [self.connection mysqlEscapeString:value];
	if (escaped == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL update could not escape the qualifier for %@.", key];
	}
	return [[NSString alloc] initWithFormat:@"='%@'", escaped];
}

// Mirrors MADMySQLInsert's binding: every cell owns its length and is_null,
// and buffer points at malloc'd storage freed by MADMySQLFreeBindings.

- (void)fillBinding:(MYSQL_BIND *)binding buffer:(void **)buffer withValue:(id)value {
	binding->length = calloc(1, sizeof(unsigned long));
	binding->is_null = calloc(1, sizeof(*binding->is_null));

	if ([value isKindOfClass:[NSNull class]]) {
		binding->buffer_type = MYSQL_TYPE_NULL;
		binding->buffer = NULL;
		binding->buffer_length = 0;
		*binding->is_null = 1;
		return;
	}
	if ([value isKindOfClass:[NSString class]]) {
		NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
		*buffer = malloc(data.length + 1);
		if (data.length > 0) {
			memcpy(*buffer, data.bytes, data.length);
		}
		((char *)*buffer)[data.length] = '\0';
		binding->buffer_type = MYSQL_TYPE_STRING;
		binding->buffer = *buffer;
		binding->buffer_length = data.length;
		*binding->length = data.length;
		return;
	}
	if ([value isKindOfClass:[NSData class]]) {
		NSData *data = value;
		*buffer = malloc(data.length + 1);
		if (data.length > 0) {
			memcpy(*buffer, data.bytes, data.length);
		}
		((char *)*buffer)[data.length] = '\0';
		binding->buffer_type = MYSQL_TYPE_BLOB;
		binding->buffer = *buffer;
		binding->buffer_length = data.length;
		*binding->length = data.length;
		return;
	}
	NSNumber *number = value;
	if (strcmp(number.objCType, @encode(double)) == 0 || strcmp(number.objCType, @encode(float)) == 0) {
		*buffer = malloc(sizeof(double));
		*(double *)*buffer = number.doubleValue;
		binding->buffer_type = MYSQL_TYPE_DOUBLE;
	} else {
		*buffer = malloc(sizeof(long long));
		*(long long *)*buffer = number.longLongValue;
		binding->buffer_type = MYSQL_TYPE_LONGLONG;
	}
	binding->buffer = *buffer;
	binding->buffer_length = 0;
}

@end
