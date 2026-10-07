//
//  MysqlTruncateTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlTruncate: the two factories and the table-name
//  guard. The truncate itself is covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MysqlTruncate.h"
#import "MysqlConnection.h"
#import "MysqlException.h"

@interface MysqlTruncateTests : XCTestCase
@end

@implementation MysqlTruncateTests

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

- (void)testFactoryWithoutATableLeavesTheNameUnset {
	MysqlConnection *connection = [self connectionWithoutAServer];
	MysqlTruncate *truncate = [MysqlTruncate truncateWithConnection:connection];

	XCTAssertNotNil(truncate);
	XCTAssertNil(truncate.tableName);
}

- (void)testFactoryWithATableStoresIt {
	MysqlConnection *connection = [self connectionWithoutAServer];
	MysqlTruncate *truncate = [MysqlTruncate truncateWithConnection:connection
														   forTable:@"mad_scratch"];

	XCTAssertEqualObjects(truncate.tableName, @"mad_scratch");
}

- (void)testFactoryAcceptsANilConnection {
	// Unlike MysqlInsert/MysqlUpdate/MysqlDelete, the truncate factory does not
	// check for a nil connection; the object comes back and -execute fails
	// later on. Pinned so the inconsistency is visible.
	XCTAssertNoThrow([MysqlTruncate truncateWithConnection:nil]);
	XCTAssertNotNil([MysqlTruncate truncateWithConnection:nil forTable:@"mad_scratch"]);
}

- (void)testTableNameIsWriteable {
	MysqlTruncate *truncate = [MysqlTruncate truncateWithConnection:[self connectionWithoutAServer]];
	truncate.tableName = @"mad_scratch";

	XCTAssertEqualObjects(truncate.tableName, @"mad_scratch");
}

- (void)testExecuteWithoutATableNameRaises {
	MysqlTruncate *truncate = [MysqlTruncate truncateWithConnection:[self connectionWithoutAServer]];

	@try {
		[truncate execute];
		XCTFail(@"A truncate with no table must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlException");
		XCTAssertEqualObjects(exception.reason, @"Truncate is missing table name");
	}
}

@end
