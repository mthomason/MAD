//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADMySQLFetchFieldTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLFetchFieldTests.m: offline coverage for
//  MADMySQLFetchField, the per-column descriptor the fetch builds out of a
//  MYSQL_FIELD.  The struct is filled in by hand here, which is what lets the
//  mapping (and the primary-key flag test) be checked without a server.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADMySQLFetchField.h>
#import <mysql.h>
#import <string.h>

static MYSQL_FIELD fieldOfType(enum enum_field_types type,
							   unsigned long length,
							   unsigned int decimals,
							   unsigned int flags) {
	MYSQL_FIELD field;
	memset(&field, 0, sizeof(field));
	field.name = (char *)"emp_no";
	field.type = type;
	field.length = length;
	field.decimals = decimals;
	field.flags = flags;
	return field;
}

static void testFieldCopiesTheNameAndTypeDetails(void) {
	MYSQL_FIELD raw = fieldOfType(MYSQL_TYPE_LONG, 11, 0, 0);

	MADMySQLFetchField *field = [[MADMySQLFetchField alloc] initWithField:raw fieldName:@"emp_no"];

	MAD_PASS_EQUAL(field.name, @"emp_no", "the name is carried over");
	MAD_PASS(field.fieldType == (NSInteger)MYSQL_TYPE_LONG, "the type is carried over");
	MAD_PASS(field.width == (NSUInteger)11, "the width is carried over");
	MAD_PASS(field.decimals == (NSUInteger)0, "the decimals are carried over");
	MAD_PASS(!field.primaryKey, "a plain column is not a key");
}

static void testFieldKeepsANameDifferentFromTheStructs(void) {
	MYSQL_FIELD raw = fieldOfType(MYSQL_TYPE_VAR_STRING, 16, 0, 0);

	MADMySQLFetchField *field = [[MADMySQLFetchField alloc] initWithField:raw fieldName:@"first_name"];

	// The caller's name wins over the struct's own char *.
	MAD_PASS_EQUAL(field.name, @"first_name", "the caller's name wins");
	MAD_PASS(field.fieldType == (NSInteger)MYSQL_TYPE_VAR_STRING, "the type is carried over");
}

static void testDecimalPlacesAreCarriedThrough(void) {
	MYSQL_FIELD raw = fieldOfType(MYSQL_TYPE_NEWDECIMAL, 8, 2, 0);

	MADMySQLFetchField *field = [[MADMySQLFetchField alloc] initWithField:raw fieldName:@"salary"];

	MAD_PASS(field.decimals == (NSUInteger)2, "the decimal places are kept");
	MAD_PASS(field.width == (NSUInteger)8, "the width is kept");
}

static void testPrimaryKeyComesFromTheFlagBits(void) {
	MYSQL_FIELD key = fieldOfType(MYSQL_TYPE_LONG, 11, 0, PRI_KEY_FLAG);
	MYSQL_FIELD notKey = fieldOfType(MYSQL_TYPE_LONG, 11, 0, NOT_NULL_FLAG);

	MADMySQLFetchField *keyField = [[MADMySQLFetchField alloc] initWithField:key fieldName:@"id"];
	MADMySQLFetchField *notKeyField = [[MADMySQLFetchField alloc] initWithField:notKey fieldName:@"id"];

	MAD_PASS(keyField.primaryKey, "the primary-key bit marks a key");
	MAD_PASS(!notKeyField.primaryKey, "another flag does not");
}

static void testPrimaryKeyFlagIsDetectedAlongsideOtherFlags(void) {
	// IS_PRI_KEY only looks at its own bit, so a column that is both a key and
	// NOT NULL (a normal AUTO_INCREMENT primary key) still reads as a key.
	MYSQL_FIELD raw = fieldOfType(MYSQL_TYPE_LONG, 11, 0,
								  (PRI_KEY_FLAG | NOT_NULL_FLAG | UNSIGNED_FLAG));

	MADMySQLFetchField *field = [[MADMySQLFetchField alloc] initWithField:raw fieldName:@"id"];

	MAD_PASS(field.primaryKey, "the key bit is found among the other flags");
}

static void testDefaultInitialisationLeavesTheFlagsOff(void) {
	MADMySQLFetchField *field = [[MADMySQLFetchField alloc] init];

	MAD_PASS(field.name == nil, "a bare field has no name");
	MAD_PASS(field.width == (NSUInteger)0, "a bare field has no width");
	MAD_PASS(!field.primaryKey, "a bare field is not a key");
}

MAD_TEST_MAIN("MADMySQLFetchFieldTests",
	MAD_TEST(testFieldCopiesTheNameAndTypeDetails),
	MAD_TEST(testFieldKeepsANameDifferentFromTheStructs),
	MAD_TEST(testDecimalPlacesAreCarriedThrough),
	MAD_TEST(testPrimaryKeyComesFromTheFlagBits),
	MAD_TEST(testPrimaryKeyFlagIsDetectedAlongsideOtherFlags),
	MAD_TEST(testDefaultInitialisationLeavesTheFlagsOff));
