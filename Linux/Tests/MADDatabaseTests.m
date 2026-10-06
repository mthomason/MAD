//
//  MADDatabaseTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseTests.m: MADDatabase, the abstract base
//  class for all database drivers -- its concrete SQL-generation helpers
//  (the headless path's query-to-SQL core) and the "subclass me" contract.
//

#import "MADTestSupport.h"
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADNotificationDidReadRows.h>

#pragma mark - Class-level defaults

static void testClassLevelDefaults(void) {
	MAD_PASS_EQUAL([MADDatabase imageIconName], @"", "the base has no icon name");
	MAD_PASS_EQUAL([MADDatabase driverName], @"", "the base has no driver name");
	MAD_PASS_EQUAL([MADDatabase identifier], @"NONE", "the base identifier is NONE");
}

static void testInstanceIdentifier(void) {
	MAD_PASS_EQUAL([[MADDatabase alloc] init].identifier, @"NONE", "the instance identifier is NONE");
}

static void testInitInitializesErrors(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS(db.errors != nil, "the error container exists");
	MAD_PASS(db.errors.count == (NSUInteger)0, "the error container starts empty");
}

static void testMADSqlTextFromPartConstant(void) {
	MAD_PASS_EQUAL(MADSqlTextFromPart, @"\nFROM\n", "the FROM part constant");
}

#pragma mark - Safe identifiers and aliases

static void testNewSafeQueryField(void) {
	MAD_PASS_EQUAL([MADDatabase newSafeQueryField:@"name" andTable:@"Invoice"], @"Invoice.name",
				   "a safe query field is table-dot-field");
}

static void testQueryKey(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db queryKey:@"name" table:@"Invoice"], @"Invoice.name", "the query key is table-dot-field");
}

static void testNewSafeIdentifier(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db newSafeIdentifier:@"Invoice"], @"Invoice", "the base leaves the identifier alone");
}

static void testTableAliasForTable(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db tableAliasForTable:@"Invoice"], @"Invoice", "the base leaves the table name alone");
}

static void testTableAliasConnector(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db tableAliasConnector], @" AS ", "the alias connector");
}

static void testFieldAliasForFieldAndTableName(void) {
	// The legacy alias method concatenates the field and table name directly,
	// without a separator.
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db fieldAliasForField:@"name" andTableName:@"Invoice"], @"nameInvoice",
				   "the legacy alias concatenates without a separator");
}

static void testFieldAliasForFieldWithSafeTableName(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db fieldAliasForField:@"name" withSafeTableName:@"Invoice"], @"Invoice.name",
				   "the safe alias is table-dot-field");
}

#pragma mark - SQL fragments

static void testSelectParts(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db selectPart], @"SELECT\n", "the select part");
	MAD_PASS_EQUAL([db selectPartWithLimitedResults:10], @"SELECT\n", "the limited select part");
}

static void testSqlLimitClause(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db sqlLimitClause], @"", "no limit by default");
	MAD_PASS_EQUAL([db sqlLimitClause:0], @"", "zero means no limit");
	MAD_PASS_EQUAL([db sqlLimitClause:10], @"\nLIMIT 10", "a real limit");
	MAD_PASS_EQUAL([db sqlLimitClause:NSUIntegerMax], @"", "the maximum means no limit");
}

static void testSqlRangeClause(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db sqlRangeClauseWithLimit:10 offset:20], @"LIMIT 10 OFFSET 20", "the range clause");
}

static void testSqlDefaultRequiredOrderByClause(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db sqlDefaultRequiredOrderByClause], @"", "the base has no required order by");
}

static void testSqlSampleDataForFieldAndTable(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	NSString *sql = [db sqlSampleDataForField:@"name" andTable:@"MyTable"];
	MAD_PASS([sql containsString:@"DISTINCT"], "the sample asks for distinct values");
	MAD_PASS([sql containsString:@"MyTable.name"], "the sample names the field");
	MAD_PASS([sql containsString:@"LIMIT 511;"], "the sample is capped");
}

// The base emits the ANSI literal.  A value is single-quoted, and an interior
// quote is doubled -- not backslash-escaped, and never wrapped in a double
// quote, which SQL reads as a *name*.  See BUGS.md.
static void testNewSafeLiteralQuotesAndEscapes(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db newSafeLiteral:@"London"], @"'London'", "a plain value is single-quoted");
	MAD_PASS_EQUAL([db newSafeLiteral:@"O'Brien"], @"'O''Brien'", "an interior quote is doubled");
	MAD_PASS_EQUAL([db newSafeLiteral:@"it''s"], @"'it''''s'", "existing pairs double again");
	MAD_PASS_EQUAL([db newSafeLiteral:@""], @"''", "an empty value is an empty literal");
}

// nil is a value the caller did not set, and SQL spells that NULL.  Emitting
// '' instead would silently ask for rows whose column is the empty string.
static void testNewSafeLiteralNilIsNull(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db newSafeLiteral:nil], @"NULL", "nil literalises as NULL");
}

static void testSqlAggregateFunctions(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db sqlAggregateFunctionLength], @"LENGTH", "the length aggregate");
	MAD_PASS_EQUAL([db sqlAggregateFunctionMax], @"MAX", "the max aggregate");
}

#pragma mark - "Subclass me" contract

static void testAbstractMethodsThrow(void) {
	MADDatabase *db = [[MADDatabase alloc] init];

	MAD_THROWS_NAMED([db executeQuery:nil withError:NULL], NSInternalInconsistencyException, "executeQuery:withError: throws");
	MAD_THROWS_NAMED([db executeQuery:nil withDataTable:nil andError:NULL], NSInternalInconsistencyException, "executeQuery:withDataTable:andError: throws");
	MAD_THROWS_NAMED([db getTables:nil], NSInternalInconsistencyException, "getTables: throws");
	MAD_THROWS_NAMED([db executeSQL:nil fieldKeys:nil onConnection:nil intoResultTable:nil withError:NULL], NSInternalInconsistencyException, "executeSQL: throws");
	MAD_THROWS_NAMED([db getTablesFromConnection:nil error:NULL], NSInternalInconsistencyException, "getTablesFromConnection:error: throws");
	MAD_THROWS_NAMED([db enumerateTablesFromConnection:nil usingBlock:nil completion:nil], NSInternalInconsistencyException, "enumerateTables... throws");
	MAD_THROWS_NAMED([db fieldsForTable:nil connection:nil error:NULL], NSInternalInconsistencyException, "fieldsForTable: throws");
}

static void testInertStubsReturnDefaults(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS([db connectWithConnection:nil credentals:nil connectionError:NULL] == nil, "the base connect returns nil");
	MAD_NO_THROW([db closeConnection:nil], "the base close does not throw");
}

#pragma mark - Read-row notification

static void testReadRowPostsNotification(void) {
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

	MAD_PASS_EQUAL(capturedRow, @7, "the notification carries the row number");
	MAD_PASS(capturedObject == db, "the notification's object is the database");
}

MAD_TEST_MAIN("MADDatabaseTests",
	MAD_TEST(testClassLevelDefaults),
	MAD_TEST(testInstanceIdentifier),
	MAD_TEST(testInitInitializesErrors),
	MAD_TEST(testMADSqlTextFromPartConstant),
	MAD_TEST(testNewSafeQueryField),
	MAD_TEST(testQueryKey),
	MAD_TEST(testNewSafeIdentifier),
	MAD_TEST(testTableAliasForTable),
	MAD_TEST(testTableAliasConnector),
	MAD_TEST(testFieldAliasForFieldAndTableName),
	MAD_TEST(testFieldAliasForFieldWithSafeTableName),
	MAD_TEST(testSelectParts),
	MAD_TEST(testSqlLimitClause),
	MAD_TEST(testSqlRangeClause),
	MAD_TEST(testSqlDefaultRequiredOrderByClause),
	MAD_TEST(testSqlSampleDataForFieldAndTable),
	MAD_TEST(testNewSafeLiteralQuotesAndEscapes),
	MAD_TEST(testNewSafeLiteralNilIsNull),
	MAD_TEST(testSqlAggregateFunctions),
	MAD_TEST(testAbstractMethodsThrow),
	MAD_TEST(testInertStubsReturnDefaults),
	MAD_TEST(testReadRowPostsNotification));
