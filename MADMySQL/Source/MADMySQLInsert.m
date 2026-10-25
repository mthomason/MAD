//
//  MADMySQLInsert.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLInsert.h"

#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>

#import <mysql.h>
#import <mysqld_error.h>
#import <stdlib.h>
#import <string.h>

@interface MADMySQLInsert ()

	@property(nonatomic, strong, readwrite) MADMySQLConnection *connection;
	@property(nonatomic, strong, readwrite) NSNumber *affectedRows;
	@property(nonatomic, strong, readwrite) NSNumber *rowid;

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

@implementation MADMySQLInsert

+ (MADMySQLInsert *)insertWithConnection:(MADMySQLConnection *)aConnection {
	if (aConnection == nil) {
		[MADMySQLException raiseConnection:nil withFormat:@"An insert requires a connection."];
	}
	MADMySQLInsert *insert = [[self alloc] init];
	insert.connection = aConnection;
	return insert;
}

- (void)execute {
	if (self.table == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"No table specified for insert"];
	}
	if (self.rowData == nil) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"No rowData specified for insert"];
	}

	// One pass over the values before anything is allocated, so a bad value
	// class raises with no bindings to leak.
	for (id value in self.rowData.allValues) {
		if (!([value isKindOfClass:[NSNull class]] || [value isKindOfClass:[NSString class]] ||
			  [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSNumber class]])) {
			[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL insert does not support a %@ value.",
			 [value class]];
		}
	}

	NSArray *columns = self.rowData.allKeys;
	NSString *statementText = [self statementForColumns:columns];

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
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL insert could not allocate bindings."];
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

	// Read on every path: for a statement that did not run the client answers
	// (my_ulonglong)-1, and an ignored duplicate is deliberately reported that
	// way (see docs/project/BUGS.md, MADMySQL).
	self.affectedRows = @(mysql_stmt_affected_rows(statement));
	self.rowid = @(mysql_stmt_insert_id(statement));

	MADMySQLFreeBindings(bindings, buffers, count);
	mysql_stmt_close(statement);

	if (executeResult && !(self.ignoreDuplicateErrors && executeErrno == ER_DUP_ENTRY)) {
		[MADMySQLException raiseConnection:self.connection withFormat:@"MySQL says %d! %@.", executeErrno, executeMessage];
	}
}

// Builds "INSERT INTO `table` (`a`, `b`) VALUES (?, ?)" with the columns in
// the same order the bindings below are filled.

- (NSString *)statementForColumns:(NSArray *)columns {
	NSMutableString *statement = [[NSMutableString alloc] initWithFormat:@"INSERT INTO `%@` (", self.table];
	for (NSUInteger i = 0; i < columns.count; i++) {
		if (i > 0) {
			[statement appendString:@", "];
		}
		[statement appendFormat:@"`%@`", columns[i]];
	}
	[statement appendString:@") VALUES ("];
	for (NSUInteger i = 0; i < columns.count; i++) {
		if (i > 0) {
			[statement appendString:@", "];
		}
		[statement appendString:@"?"];
	}
	[statement appendString:@")"];
	return statement;
}

// Every binding owns its length and is_null cells; buffer points at the
// malloc'd storage this method writes into buffers[i], so the caller can free
// the whole set with MADMySQLFreeBindings. Strings and blobs get a
// NUL-terminated copy, numbers the widest storage the client supports.

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
