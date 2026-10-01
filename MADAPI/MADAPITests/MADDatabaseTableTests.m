//
//  MADDatabaseTableTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 2 coverage for MADDatabaseTable: the value type that represents a table
//  in a database schema.  Exercises initialization, the queryable flag, and
//  NSCopying.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseTable.h>

@interface MADDatabaseTableTests : XCTestCase
@end

@implementation MADDatabaseTableTests

- (void)testInitHasNilName {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] init];
	XCTAssertNil(table.name);
	XCTAssertFalse(table.queryable);
}

- (void)testInitWithTableName {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	XCTAssertEqualObjects(table.name, @"Invoice");
	XCTAssertFalse(table.queryable);
}

- (void)testQueryableIsSettable {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	table.queryable = YES;
	XCTAssertTrue(table.queryable);
	table.queryable = NO;
	XCTAssertFalse(table.queryable);
}

- (void)testCopy {
	MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:@"Invoice"];
	table.queryable = YES;

	MADDatabaseTable *copy = [table copy];
	XCTAssertNotEqual(copy, table);
	XCTAssertEqualObjects(copy.name, @"Invoice");
	XCTAssertTrue(copy.queryable);
}

@end
