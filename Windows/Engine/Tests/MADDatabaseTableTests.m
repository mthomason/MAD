//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseTableTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseTableTests.m: the value type that
//  represents a table in a database schema -- initialization, the queryable
//  flag and NSCopying.
//

#import "MADTestSupport.h"
#import <MADAPI/MADDatabaseTable.h>

static void testInitHasNilName(void) {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] init];
	MAD_PASS(table.name == nil, "a new table has no name");
	MAD_PASS(!table.queryable, "a new table is not queryable");
}

static void testInitWithTableName(void) {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	MAD_PASS_EQUAL(table.name, @"Invoice", "the name is stored");
	MAD_PASS(!table.queryable, "a named table starts unqueryable");
}

static void testQueryableIsSettable(void) {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	table.queryable = YES;
	MAD_PASS(table.queryable, "queryable can be set");
	table.queryable = NO;
	MAD_PASS(!table.queryable, "queryable can be cleared");
}

static void testCopy(void) {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	table.queryable = YES;

	MADDatabaseTable *copy = [table copy];
	MAD_PASS(copy != table, "the copy is a different object");
	MAD_PASS_EQUAL(copy.name, @"Invoice", "the copy carries the name");
	MAD_PASS(copy.queryable, "the copy carries the queryable flag");
}

MAD_TEST_MAIN("MADDatabaseTableTests",
	MAD_TEST(testInitHasNilName),
	MAD_TEST(testInitWithTableName),
	MAD_TEST(testQueryableIsSettable),
	MAD_TEST(testCopy));
