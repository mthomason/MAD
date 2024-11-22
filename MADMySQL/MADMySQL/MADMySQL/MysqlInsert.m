//
//  MysqlInsert.m
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlInsert.h"

#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>

#import <string.h>
#import <mysql.h>

#import "mysqld_error.h"
#import "MysqlConnection.h"
#import "NSString+MysqlEscape.h"
#import "MysqlException.h"


@implementation MysqlInsert

@synthesize table, rowData, affectedRows, rowid, ignoreDuplicateErrors;

+ (MysqlInsert *)insertWithConnection:(MysqlConnection *)aConnection {

	if (!aConnection) {
		[MysqlException raiseConnection:nil withFormat:@"Connection is nil"];
	}
	
	MysqlInsert *newObject=[[self alloc] init];
	newObject->rowData = nil;
	newObject->connection = aConnection;
	return newObject;
}


- (void)execute {

	if (!table) {
		[MysqlException raiseConnection:connection withFormat: @"No table specified for insert"];
	}
	
	if (rowData==nil) {
		[MysqlException raiseConnection:connection withFormat: @"No rowData specified for insert"];
	}
	
	@synchronized(connection) {
		
		NSArray *keys = rowData.allKeys;
		NSMutableString *cmd = [NSMutableString new];
		[cmd appendFormat:@"INSERT INTO %@ ( ",table];
		BOOL firstAdd=YES;
		NSString *columnName, *columnNameEscaped;
		for (columnName in keys) {
			columnNameEscaped = [columnName mysqlEscapeInConnection:connection];
			if (firstAdd) {
				[cmd appendFormat:@" %@ ", columnNameEscaped];
				firstAdd=NO;
			} else {
				[cmd appendFormat:@", %@ ", columnNameEscaped];
			}
		}
		
		[cmd appendFormat:@" ) values ( "];
		
		firstAdd=YES;
		for (NSUInteger i=0; i<keys.count; i++) {
			if (firstAdd) {
				[cmd appendString:@" ? "];
				firstAdd=NO;
			} else {
				[cmd appendString:@", ? "];
			}
		}
		[cmd appendFormat:@" ) "];
		
		MYSQL_STMT *myStatement = mysql_stmt_init(connection.connection);
		const char *utf8EncodedString = cmd.UTF8String;
		if (mysql_stmt_prepare(myStatement, utf8EncodedString,strlen(utf8EncodedString))) {
			[MysqlException raiseConnection:connection withFormat: @"mysql_stmt_prepare failed %@ %s",cmd, mysql_stmt_error(myStatement)];
		}
		
		MYSQL_BIND *binding=calloc(sizeof(MYSQL_BIND),keys.count?keys.count:1);
		
		for (NSUInteger x=0; x < keys.count;x++) {
			NSString *key= keys[x];
			NSObject *object = rowData[key];
			if ([object isKindOfClass:[NSString class]]) {
				NSString *s = (NSString *)object;
				const char *ch = s.UTF8String;
				binding[x].is_null= 0;
				binding[x].buffer_type = MYSQL_TYPE_STRING;
				binding[x].buffer = (void *)ch;
				binding[x].buffer_length= strlen(ch);
			} else if ([object isKindOfClass:[NSData class]]) {
				NSData *data = (NSData *)object;
				binding[x].is_null= 0;
				binding[x].buffer_type = MYSQL_TYPE_BLOB;
				binding[x].buffer = (void *)data.bytes;
				binding[x].buffer_length= data.length;
			} else if ([object isKindOfClass:[NSNumber class]]) {
				NSString *s = (NSString *)object.description;
				const char *ch = s.UTF8String;
				binding[x].is_null= 0;
				binding[x].buffer_type = MYSQL_TYPE_STRING;
				binding[x].buffer = (void *)ch;
				binding[x].buffer_length= strlen(ch);
			} else if ([object isKindOfClass:[NSNull class]]) {
				my_bool *aBool = calloc(1,sizeof(my_bool));
				*aBool=1;
				binding[x].is_null= aBool;
			} else {
				NSString *s = (NSString *)object.description;
				const char *ch = s.UTF8String;
				binding[x].is_null= 0;
				binding[x].buffer = (void *)ch;
				binding[x].buffer_type = MYSQL_TYPE_STRING;
				binding[x].buffer_length= strlen(ch);
			}
		}
		
		if (mysql_stmt_bind_param(myStatement,(MYSQL_BIND *)binding)) {
			[MysqlException raiseConnection:connection withFormat:@"mysql_stmt_bind_param failed %s", mysql_stmt_error(myStatement)];
		}
		
		if (mysql_stmt_execute(myStatement)) {
			if (ignoreDuplicateErrors && mysql_errno(connection.connection)==ER_DUP_ENTRY) {
				//NSLog(@"mysql_stmt_execute failure ignore %s", mysql_stmt_error(myStatement));
			} else {
				[MysqlException raiseConnection:connection withFormat:@"mysql_stmt_execute failed %s", mysql_stmt_error(myStatement)];
			}
		}
		
		unsigned long long rowCount = mysql_affected_rows(connection.connection);
		affectedRows = @(rowCount);
		rowid=@(mysql_insert_id(connection.connection));
		if (mysql_stmt_close(myStatement)) {
			[MysqlException raiseConnection:connection withFormat:@" mysql_stmt_close failed %s", mysql_stmt_error(myStatement)];
		}
		
		for (NSUInteger x=0; x < keys.count;x++) {
			NSString *key= keys[x];
			NSObject *object = rowData[key];
			if ([object isKindOfClass:[NSNull class]]) {
				free(binding[x].is_null);
			}
		}
		
		free(binding);
	}
}

@end
