//
//  MADMySQLDeleteTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MADMySQLDelete: the factory, the statement it builds, and
//  the two guards in -execute. A real delete is covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MADMySQLDelete.h"
#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

// Implemented in MADMySQLDelete.m but declared in no header.
@interface MADMySQLDelete (MADMySQLTestsInternal)
- (NSString *)command;
@end

@interface MADMySQLDeleteTests : XCTestCase
@end

@implementation MADMySQLDeleteTests

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
- (MADMySQLConnection *)connectionWithoutAServer {
	return [[MADMySQLConnection alloc] init];
}

- (void)testFactoryRejectsANilConnection {
	XCTAssertThrowsSpecificNamed([MADMySQLDelete deleteWithConnection:nil],
								 MADMySQLException, @"MADMySQLException");
}

- (void)testFactoryStoresTheConnectionAndStartsEmpty {
	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:[self connectionWithoutAServer]];

	XCTAssertNotNil(delete);
	XCTAssertNil(delete.tableName);
	XCTAssertNil(delete.qualifier);
	XCTAssertNil(delete.affectedRows);
}

- (void)testCommandPairsTheTableWithTheQualifier {
	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";
	delete.qualifier = @"id=1";

	XCTAssertEqualObjects([delete command], @"DELETE FROM mad_scratch WHERE id=1");
}

- (void)testCommandFormatsAMissingQualifierAsTheLiteralNull {
	// The qualifier is pasted into the statement with %@, so a nil one becomes
	// the string "(null)" rather than an error.  -execute refuses to run it.
	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";

	XCTAssertEqualObjects([delete command], @"DELETE FROM mad_scratch WHERE (null)");
}

- (void)testExecuteWithoutATableNameRaises {
	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.qualifier = @"id=1";

	@try {
		[delete execute];
		XCTFail(@"A delete with no table must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.name, @"MADMySQLException");
		XCTAssertEqualObjects(exception.reason, @"Delete is missing table name");
	}
}

- (void)testExecuteWithoutAQualifierRaises {
	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";

	@try {
		[delete execute];
		XCTFail(@"An unqualified delete must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.reason,
							  @"Delete is unqualified. Use TRUNCATE to wipe out tables");
	}
}

@end
