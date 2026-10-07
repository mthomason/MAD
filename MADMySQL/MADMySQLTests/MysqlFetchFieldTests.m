//
//  MysqlFetchFieldTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlFetchField, the per-column descriptor the fetch
//  builds out of a MYSQL_FIELD. The struct is filled in by hand here, which is
//  what lets the mapping (and the primary-key flag test) be checked without a
//  server.
//

#import <XCTest/XCTest.h>
#import <string.h>

#import "MysqlFetchField.h"
#import <mysql.h>

@interface MysqlFetchFieldTests : XCTestCase
@end

@implementation MysqlFetchFieldTests

- (MYSQL_FIELD)fieldOfType:(enum enum_field_types)type
					length:(unsigned long)length
				  decimals:(unsigned int)decimals
					 flags:(unsigned int)flags {
	MYSQL_FIELD field;
	memset(&field, 0, sizeof(field));
	field.name = (char *)"emp_no";
	field.type = type;
	field.length = length;
	field.decimals = decimals;
	field.flags = flags;
	return field;
}

- (void)testFieldCopiesTheNameAndTypeDetails {
	MYSQL_FIELD raw = [self fieldOfType:MYSQL_TYPE_LONG length:11 decimals:0 flags:0];

	MysqlFetchField *field = [[MysqlFetchField alloc] initWithField:raw fieldName:@"emp_no"];

	XCTAssertEqualObjects(field.name, @"emp_no");
	XCTAssertEqual(field.fieldType, (NSInteger)MYSQL_TYPE_LONG);
	XCTAssertEqual(field.width, (NSUInteger)11);
	XCTAssertEqual(field.decimals, (NSUInteger)0);
	XCTAssertFalse(field.primaryKey);
}

- (void)testFieldKeepsANameDifferentFromTheStructs {
	MYSQL_FIELD raw = [self fieldOfType:MYSQL_TYPE_VAR_STRING length:16 decimals:0 flags:0];

	MysqlFetchField *field = [[MysqlFetchField alloc] initWithField:raw fieldName:@"first_name"];

	// The caller's name wins over the struct's own char *.
	XCTAssertEqualObjects(field.name, @"first_name");
	XCTAssertEqual(field.fieldType, (NSInteger)MYSQL_TYPE_VAR_STRING);
}

- (void)testDecimalPlacesAreCarriedThrough {
	MYSQL_FIELD raw = [self fieldOfType:MYSQL_TYPE_NEWDECIMAL length:8 decimals:2 flags:0];

	MysqlFetchField *field = [[MysqlFetchField alloc] initWithField:raw fieldName:@"salary"];

	XCTAssertEqual(field.decimals, (NSUInteger)2);
	XCTAssertEqual(field.width, (NSUInteger)8);
}

- (void)testPrimaryKeyComesFromTheFlagBits {
	MYSQL_FIELD key = [self fieldOfType:MYSQL_TYPE_LONG length:11 decimals:0 flags:PRI_KEY_FLAG];
	MYSQL_FIELD notKey = [self fieldOfType:MYSQL_TYPE_LONG length:11 decimals:0 flags:NOT_NULL_FLAG];

	MysqlFetchField *keyField = [[MysqlFetchField alloc] initWithField:key fieldName:@"id"];
	MysqlFetchField *notKeyField = [[MysqlFetchField alloc] initWithField:notKey fieldName:@"id"];

	XCTAssertTrue(keyField.primaryKey);
	XCTAssertFalse(notKeyField.primaryKey);
}

- (void)testPrimaryKeyFlagIsDetectedAlongsideOtherFlags {
	// IS_PRI_KEY only looks at its own bit, so a column that is both a key and
	// NOT NULL (a normal AUTO_INCREMENT primary key) still reads as a key.
	MYSQL_FIELD raw = [self fieldOfType:MYSQL_TYPE_LONG length:11 decimals:0
								 flags:(PRI_KEY_FLAG | NOT_NULL_FLAG | UNSIGNED_FLAG)];

	MysqlFetchField *field = [[MysqlFetchField alloc] initWithField:raw fieldName:@"id"];

	XCTAssertTrue(field.primaryKey);
}

- (void)testDefaultInitialisationLeavesTheFlagsOff {
	MysqlFetchField *field = [[MysqlFetchField alloc] init];

	XCTAssertNil(field.name);
	XCTAssertEqual(field.width, (NSUInteger)0);
	XCTAssertFalse(field.primaryKey);
}

@end
