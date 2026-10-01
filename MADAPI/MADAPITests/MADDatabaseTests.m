//
//  MADDatabaseTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for MADDatabase, the abstract base class for all database
//  drivers.  This exercises the concrete SQL-generation helper methods and the
//  "subclass me" contract: the connection/query methods throw an internal-
//  inconsistency exception when called on the base class, while the safe stub
//  methods return inert defaults.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADNotificationDidReadRows.h>

@interface MADDatabaseTests : XCTestCase
@end

@implementation MADDatabaseTests

#pragma mark - Class-level defaults

- (void)testClassLevelDefaults {
	XCTAssertEqualObjects([MADDatabase imageIconName], @"");
	XCTAssertEqualObjects([MADDatabase driverName], @"");
	XCTAssertEqualObjects([MADDatabase identifier], @"NONE");
}

- (void)testInstanceIdentifier {
	XCTAssertEqualObjects([[MADDatabase alloc] init].identifier, @"NONE");
}

- (void)testInitInitializesErrors {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertNotNil(db.errors);
	XCTAssertEqual(db.errors.count, (NSUInteger)0);
}

- (void)testMADSqlTextFromPartConstant {
	XCTAssertEqualObjects(MADSqlTextFromPart, @"\nFROM\n");
}

#pragma mark - Safe identifiers and aliases

- (void)testNewSafeQueryField {
	XCTAssertEqualObjects([MADDatabase newSafeQueryField:@"name" andTable:@"Invoice"], @"Invoice.name");
}

- (void)testQueryKey {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db queryKey:@"name" table:@"Invoice"], @"Invoice.name");
}

- (void)testNewSafeIdentifier {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db newSafeIdentifier:@"Invoice"], @"Invoice");
}

- (void)testTableAliasForTable {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db tableAliasForTable:@"Invoice"], @"Invoice");
}

- (void)testTableAliasConnector {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db tableAliasConnector], @" AS ");
}

- (void)testFieldAliasForFieldAndTableName {
	// The legacy alias method concatenates the field and table name directly,
	// without a separator.
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db fieldAliasForField:@"name" andTableName:@"Invoice"], @"nameInvoice");
}

- (void)testFieldAliasForFieldWithSafeTableName {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db fieldAliasForField:@"name" withSafeTableName:@"Invoice"], @"Invoice.name");
}

#pragma mark - SQL fragments

- (void)testSelectParts {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db selectPart], @"SELECT\n");
	XCTAssertEqualObjects([db selectPartWithLimitedResults:10], @"SELECT\n");
}

- (void)testSqlLimitClause {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db sqlLimitClause], @"");
	XCTAssertEqualObjects([db sqlLimitClause:0], @"");
	XCTAssertEqualObjects([db sqlLimitClause:10], @"\nLIMIT 10");
	XCTAssertEqualObjects([db sqlLimitClause:NSUIntegerMax], @"");
}

- (void)testSqlRangeClause {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db sqlRangeClauseWithLimit:10 offset:20], @"LIMIT 10 OFFSET 20");
}

- (void)testSqlDefaultRequiredOrderByClause {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db sqlDefaultRequiredOrderByClause], @"");
}

- (void)testSqlSampleDataForFieldAndTable {
	MADDatabase *db = [[MADDatabase alloc] init];
	NSString *sql = [db sqlSampleDataForField:@"name" andTable:@"MyTable"];
	XCTAssertTrue([sql containsString:@"DISTINCT"]);
	XCTAssertTrue([sql containsString:@"MyTable.name"]);
	XCTAssertTrue([sql containsString:@"LIMIT 511;"]);
}

// The base emits the ANSI literal.  A value is single-quoted, and an interior quote is
// doubled -- not backslash-escaped, and never wrapped in a double quote, which SQL reads as
// a *name*.  Writing "London" is what made a text filter fail once SQLITE_DQS stopped
// forgiving it.  See BUGS.md.
- (void)testNewSafeLiteralQuotesAndEscapes {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db newSafeLiteral:@"London"], @"'London'");
	XCTAssertEqualObjects([db newSafeLiteral:@"O'Brien"], @"'O''Brien'");
	XCTAssertEqualObjects([db newSafeLiteral:@"it''s"], @"'it''''s'");
	XCTAssertEqualObjects([db newSafeLiteral:@""], @"''");
}

// nil is a value the caller did not set, and SQL spells that NULL.  Emitting '' instead
// would silently ask for rows whose column is the empty string.
- (void)testNewSafeLiteralNilIsNull {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db newSafeLiteral:nil], @"NULL");
}

- (void)testSqlAggregateFunctions {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db sqlAggregateFunctionLength], @"LENGTH");
	XCTAssertEqualObjects([db sqlAggregateFunctionMax], @"MAX");
}

#pragma mark - "Subclass me" contract

- (void)testAbstractMethodsThrow {
	MADDatabase *db = [[MADDatabase alloc] init];

	XCTAssertThrowsSpecificNamed([db executeQuery:nil withError:NULL], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db executeQuery:nil withDataTable:nil andError:NULL], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db getTables:nil], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db executeSQL:nil fieldKeys:nil onConnection:nil intoResultTable:nil withError:NULL], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db getTablesFromConnection:nil error:NULL], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db enumerateTablesFromConnection:nil usingBlock:nil completion:nil], NSException, NSInternalInconsistencyException);
	XCTAssertThrowsSpecificNamed([db fieldsForTable:nil connection:nil error:NULL], NSException, NSInternalInconsistencyException);
}

- (void)testInertStubsReturnDefaults {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertNil([db connectWithConnection:nil credentals:nil connectionError:NULL]);
	XCTAssertNoThrow([db closeConnection:nil]);
}

#pragma mark - Read-row notification

- (void)testReadRowPostsNotification {
	MADDatabase *db = [[MADDatabase alloc] init];

	__block NSNumber *capturedRow = nil;
	__block id capturedObject = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationDidReadRowsName
																	object:db
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		capturedRow = note.userInfo[MADDatabaseNumberOfRowsReadKey];
		capturedObject = note.object;
	}];

	[db readRow:7];
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	XCTAssertEqualObjects(capturedRow, @7);
	XCTAssertEqual(capturedObject, db);
}

@end
