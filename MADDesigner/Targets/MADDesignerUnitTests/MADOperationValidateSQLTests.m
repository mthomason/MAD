//
//  MADOperationValidateSQLTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Non-UI tests for the SQL validation probe's construction half
//  (MAD_SQL_ENTRY.md §7, §10.5): the zero-row wrapper, the derived-table alias,
//  the `WHERE 1=0` fold, per driver.  No server, no connection -- the class
//  lives in the app target and is reached through the host app, so its
//  interface is declared locally rather than imported.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperation.h>
#import <MADAPI/MADDatabase.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>

#pragma mark - App interfaces

@class MADocument;

@interface MADOperationValidateSQL : MADOperation
- (instancetype)initWithDocument:(MADocument *)document
					   statement:(NSString *)statement
			   expectedColumns:(NSDictionary<NSString *, NSNumber *> *)expectedColumns;
@property (readonly) BOOL probeRan;
@property (readonly) BOOL skipped;
@property (readonly, copy) NSArray<NSString *> *warnings;
+ (NSString *)probeSQLForStatement:(NSString *)statement database:(MADDatabase *)database;
@end

@interface MADOperationValidateSQLTests : XCTestCase
@end

@implementation MADOperationValidateSQLTests

- (void)testProbeWrapsTheStatementAsAZeroRowDerivedTable {
	NSString *probe = [MADOperationValidateSQL probeSQLForStatement:@"SELECT name FROM customers"
														   database:[[MADDatabase alloc] init]];
	XCTAssertEqualObjects(probe,
		@"SELECT * FROM (SELECT name FROM customers) AS _mad_probe WHERE 1=0");
}

- (void)testProbeStripsTrailingSemicolonsAndWhitespace {
	NSString *probe = [MADOperationValidateSQL probeSQLForStatement:@"  SELECT name FROM customers;  "
														   database:[[MADDatabase alloc] init]];
	XCTAssertEqualObjects(probe,
		@"SELECT * FROM (SELECT name FROM customers) AS _mad_probe WHERE 1=0");
}

- (void)testProbeFormIsTheSameForEveryDriver {
	// The derived-table alias is mandatory in MySQL and valid in T-SQL, so the
	// one form serves every dialect; the database is the seam a future dialect
	// would diverge at, and today it does not.
	NSString *statement = @"SELECT id FROM invoices";
	NSString *base = [MADOperationValidateSQL probeSQLForStatement:statement database:[[MADDatabase alloc] init]];
	NSString *mysql = [MADOperationValidateSQL probeSQLForStatement:statement database:[[MADDatabaseMySQL alloc] init]];
	NSString *tds = [MADOperationValidateSQL probeSQLForStatement:statement database:[[MADDatabaseSQLServer alloc] init]];

	XCTAssertEqualObjects(mysql, base);
	XCTAssertEqualObjects(tds, base);
	XCTAssertEqualObjects(base, @"SELECT * FROM (SELECT id FROM invoices) AS _mad_probe WHERE 1=0");
}

- (void)testProbeKeepsTheStatementVerboseInsideTheWrapper {
	// The wrapper folds the rows, not the text: comments and line breaks survive
	// exactly as typed, so the server sees the user's own statement.
	NSString *statement = @"-- the invoices\nSELECT id FROM invoices /* everything */";
	NSString *probe = [MADOperationValidateSQL probeSQLForStatement:statement database:[[MADDatabase alloc] init]];
	XCTAssertEqualObjects(probe,
		@"SELECT * FROM (-- the invoices\nSELECT id FROM invoices /* everything */) AS _mad_probe WHERE 1=0");
}

- (void)testProbeOfAnEmptyStatementIsNil {
	XCTAssertNil([MADOperationValidateSQL probeSQLForStatement:@"" database:[[MADDatabase alloc] init]]);
	XCTAssertNil([MADOperationValidateSQL probeSQLForStatement:@"   " database:[[MADDatabase alloc] init]]);
}

@end
