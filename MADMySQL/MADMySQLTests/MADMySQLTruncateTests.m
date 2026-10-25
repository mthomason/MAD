//
//  MADMySQLTruncateTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MADMySQLTruncate: the two factories and the table-name
//  guard. The truncate itself is covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MADMySQLTruncate.h"
#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

@interface MADMySQLTruncateTests : XCTestCase
@end

@implementation MADMySQLTruncateTests

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
- (MADMySQLConnection *)connectionWithoutAServer {
	return [[MADMySQLConnection alloc] init];
}

- (void)testFactoryWithoutATableLeavesTheNameUnset {
	MADMySQLConnection *connection = [self connectionWithoutAServer];
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connection];

	XCTAssertNotNil(truncate);
	XCTAssertNil(truncate.tableName);
}

- (void)testFactoryWithATableStoresIt {
	MADMySQLConnection *connection = [self connectionWithoutAServer];
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connection
														   forTable:@"mad_scratch"];

	XCTAssertEqualObjects(truncate.tableName, @"mad_scratch");
}

- (void)testFactoryAcceptsANilConnection {
	// Unlike MADMySQLInsert/MADMySQLUpdate/MADMySQLDelete, the truncate factory does not
	// check for a nil connection; the object comes back and -execute fails
	// later on. Pinned so the inconsistency is visible.
	XCTAssertNoThrow([MADMySQLTruncate truncateWithConnection:nil]);
	XCTAssertNotNil([MADMySQLTruncate truncateWithConnection:nil forTable:@"mad_scratch"]);
}

- (void)testTableNameIsWriteable {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:[self connectionWithoutAServer]];
	truncate.tableName = @"mad_scratch";

	XCTAssertEqualObjects(truncate.tableName, @"mad_scratch");
}

- (void)testExecuteWithoutATableNameRaises {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:[self connectionWithoutAServer]];

	@try {
		[truncate execute];
		XCTFail(@"A truncate with no table must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.name, @"MADMySQLException");
		XCTAssertEqualObjects(exception.reason, @"Truncate is missing table name");
	}
}

@end
