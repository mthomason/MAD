//
//  MysqlDeleteTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlDelete: the factory, the statement it builds, and
//  the two guards in -execute. A real delete is covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MysqlDelete.h"
#import "MysqlConnection.h"
#import "MysqlException.h"

// Implemented in MysqlDelete.m but declared in no header.
@interface MysqlDelete (MADMySQLTestsInternal)
- (NSString *)command;
@end

@interface MysqlDeleteTests : XCTestCase
@end

@implementation MysqlDeleteTests

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

- (void)testFactoryRejectsANilConnection {
	XCTAssertThrowsSpecificNamed([MysqlDelete deleteWithConnection:nil],
								 MysqlException, @"MysqlException");
}

- (void)testFactoryStoresTheConnectionAndStartsEmpty {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:[self connectionWithoutAServer]];

	XCTAssertNotNil(delete);
	XCTAssertNil(delete.tableName);
	XCTAssertNil(delete.qualifier);
	XCTAssertNil(delete.affectedRows);
}

- (void)testCommandPairsTheTableWithTheQualifier {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";
	delete.qualifier = @"id=1";

	XCTAssertEqualObjects([delete command], @"DELETE FROM mad_scratch WHERE id=1");
}

- (void)testCommandFormatsAMissingQualifierAsTheLiteralNull {
	// The qualifier is pasted into the statement with %@, so a nil one becomes
	// the string "(null)" rather than an error.  -execute refuses to run it.
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";

	XCTAssertEqualObjects([delete command], @"DELETE FROM mad_scratch WHERE (null)");
}

- (void)testExecuteWithoutATableNameRaises {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.qualifier = @"id=1";

	@try {
		[delete execute];
		XCTFail(@"A delete with no table must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlException");
		XCTAssertEqualObjects(exception.reason, @"Delete is missing table name");
	}
}

- (void)testExecuteWithoutAQualifierRaises {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:[self connectionWithoutAServer]];
	delete.tableName = @"mad_scratch";

	@try {
		[delete execute];
		XCTFail(@"An unqualified delete must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason,
							  @"Delete is unqualified. Use TRUNCATE to wipe out tables");
	}
}

@end
