//
//  MADDatabaseTests.m
//  MADAPITests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
#import <MADAPI/MADDatabaseConnection.h>
#import <MADFoundation/MADCredential.h>

// -newDatabaseWithConnection: is implemented on the base class but declared nowhere
// public; this test-only category is the deliberate bridge.
@interface MADDatabase (TestFactory)
+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;
@end

#pragma mark - Test doubles

// A delegate that implements the optional credential lookup, standing in for the
// application object that vends keychain credentials to a database.
@interface MADTestCredentialDelegate : NSObject <MADDatabaseResultsProtocol>
@property (nonatomic, strong) MADCredential *credential;
@property (nonatomic, copy) NSString *lastKey;
@end

@implementation MADTestCredentialDelegate
- (MADCredential *)getCredentialsForKey:(NSString *)key {
	self.lastKey = key;
	return self.credential;
}
@end

// A delegate that does not implement the optional lookup at all.
@interface MADTestSilentDelegate : NSObject <MADDatabaseResultsProtocol>
@end

@implementation MADTestSilentDelegate
@end

// The smallest concrete connection: the base class throws from every property, so
// anything that reads a connection asks a subclass.  Mirrors MADDatabaseConnectionMySql.
@interface MADTestCredentialConnection : MADDatabaseConnection
@property (nonatomic, copy) NSString *connectionString;
@end

@implementation MADTestCredentialConnection
- (NSString *)connectionString { return _connectionString; }
- (void)setConnectionString:(NSString *)connectionString { _connectionString = [connectionString copy]; }

- (MADDatabaseType)databaseType { return MADDatabaseTypeSample1; }
- (BOOL)requiresCredentials { return YES; }
- (NSString *)identifier { return [[self class] Identifier]; }
+ (NSString *)Identifier { return @"MADTestCredentialConnection"; }

- (instancetype)copyWithZone:(NSZone *)zone {
	MADTestCredentialConnection *copy = [[[self class] allocWithZone:zone] init];
	copy.connectionString = self.connectionString;
	return copy;
}

@end

// Records whether its -init ran.  Decoding should construct the instance the same way
// -copyWithZone: does, through the concrete subclass's initializer.
@interface MADTestInitializedDatabase : MADDatabase
@property (nonatomic, assign) BOOL didRunInit;
@end

@implementation MADTestInitializedDatabase
- (instancetype)init {
	if (self = [super init]) {
		_didRunInit = YES;
	}
	return self;
}
@end

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

#pragma mark - Credential lookup

- (void)testCredentalsWithConnectionCopiesFromRespondingDelegate {
	MADTestCredentialDelegate *delegate = [[MADTestCredentialDelegate alloc] init];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"hunter2"];
	delegate.credential = credential;

	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	MADCredential *received = [db credentalsWithConnection:connection];

	XCTAssertNotNil(received);
	XCTAssertEqualObjects(received.username, @"alice");
	XCTAssertEqualObjects(received.password, @"hunter2");
	// The connection string is the key the lookup is made under.
	XCTAssertEqualObjects(delegate.lastKey, @"(MADTestCredentialConnection)[host:3306]db");
	// The delegate keeps ownership of its credential; the caller receives a copy.
	XCTAssertNotEqual(received, credential);
}

- (void)testCredentalsWithConnectionReturnsNilWhenDelegateDoesNotRespond {
	MADTestSilentDelegate *delegate = [[MADTestSilentDelegate alloc] init];
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	XCTAssertNil([db credentalsWithConnection:connection]);
}

- (void)testCredentalsWithConnectionReturnsNilWhenDelegateHasNoCredential {
	MADTestCredentialDelegate *delegate = [[MADTestCredentialDelegate alloc] init];
	delegate.credential = nil;

	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	XCTAssertNil([db credentalsWithConnection:connection]);
}

#pragma mark - Factory

- (void)testNewDatabaseWithConnectionReturnsInstanceOfReceiver {
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];

	XCTAssertNotNil(db);
	XCTAssertEqualObjects(NSStringFromClass([db class]), NSStringFromClass([MADDatabase class]));
	// The base factory ignores the connection; subclasses that care override it.
	XCTAssertNil(db.databaseConnection);
}

#pragma mark - NSCopying

- (void)testCopyPreservesState {
	MADDatabase *db = [[MADDatabase alloc] init];
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";
	db.databaseConnection = connection;
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

	MADDatabase *copy = [db copy];

	XCTAssertNotEqual(copy, db);
	XCTAssertTrue(copy.isLicensedUser);
	XCTAssertEqual(copy.errors.count, (NSUInteger)1);
	// The errors array is a distinct mutable array, not the original.
	XCTAssertNotEqual(copy.errors, db.errors);
	// The connection is copied, not shared.
	XCTAssertNotEqual(copy.databaseConnection, db.databaseConnection);
	XCTAssertEqualObjects(copy.databaseConnection.connectionString, @"(MADTestCredentialConnection)[host:3306]db");
}

#pragma mark - NSSecureCoding

- (void)testSupportsSecureCoding {
	XCTAssertTrue([MADDatabase supportsSecureCoding]);
}

// The classic archive path still works: a permissive archiver and unarchiver use the
// same coding methods without enforcing the class allowlist.
- (void)testInsecureNSCodingRoundTrip {
	MADDatabase *db = [[MADDatabase alloc] init];
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
	[archiver encodeObject:db forKey:NSKeyedArchiveRootObjectKey];
	NSData *data = archiver.encodedData;
	XCTAssertNotNil(data);

	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:NULL];
	// -initForReadingFromData:error: defaults to requiring secure coding; the classic
	// path is exercised here deliberately.
	unarchiver.requiresSecureCoding = NO;
	MADDatabase *decoded = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[unarchiver finishDecoding];

	XCTAssertNotNil(decoded);
	XCTAssertTrue(decoded.isLicensedUser);
	XCTAssertEqual(decoded.errors.count, (NSUInteger)1);
	XCTAssertNil(decoded.databaseConnection);
}

// The errors array holds NSError, which the secure decoder must name in its allowlist;
// without that, the strict unarchive fails rather than losing the array.
- (void)testSecureCodingRoundTrip {
	MADDatabase *db = [[MADDatabase alloc] init];
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADDatabase *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabase class]
														   fromData:data
															  error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertTrue(decoded.isLicensedUser);
	XCTAssertEqual(decoded.errors.count, (NSUInteger)1);
	XCTAssertNil(decoded.databaseConnection);
}

// A decoded instance must be constructed the way -copyWithZone: constructs one -- through
// the concrete subclass's -init -- so its own setup (an observer, a queue) is not skipped.
- (void)testDecodingRunsTheSubclassInitializer {
	MADTestInitializedDatabase *db = [[MADTestInitializedDatabase alloc] init];
	XCTAssertTrue(db.didRunInit);

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADTestInitializedDatabase *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADTestInitializedDatabase class]
																		   fromData:data
																			  error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertTrue(decoded.didRunInit);
}

#pragma mark - Literal escaping limits

// The base class escapes only the quote character.  A backslash is deliberately left
// alone: whether it escapes the following character depends on the session's
// NO_BACKSLASH_ESCAPES setting, which only the dialect's connection object knows.  See
// MADDatabaseSQLProtocol.h and BUGS.md.
- (void)testNewSafeLiteralLeavesBackslashUntouched {
	MADDatabase *db = [[MADDatabase alloc] init];
	XCTAssertEqualObjects([db newSafeLiteral:@"a\\b"], @"'a\\b'");
	XCTAssertEqualObjects([db newSafeLiteral:@"a\\'b"], @"'a\\''b'");
}

@end
