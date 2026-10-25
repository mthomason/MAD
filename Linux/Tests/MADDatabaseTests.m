//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

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

#pragma mark - Credential lookup

static void testCredentalsWithConnectionCopiesFromRespondingDelegate(void) {
	MADTestCredentialDelegate *delegate = [[MADTestCredentialDelegate alloc] init];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:@"alice" andPassword:@"hunter2"];
	delegate.credential = credential;

	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	MADCredential *received = [db credentalsWithConnection:connection];

	MAD_PASS(received != nil, "the credential comes back");
	MAD_PASS_EQUAL(received.username, @"alice", "the username");
	MAD_PASS_EQUAL(received.password, @"hunter2", "the password");
	// The connection string is the key the lookup is made under.
	MAD_PASS_EQUAL(delegate.lastKey, @"(MADTestCredentialConnection)[host:3306]db", "the connection string is the lookup key");
	// The delegate keeps ownership of its credential; the caller receives a copy.
	MAD_PASS(received != credential, "the caller receives a copy");
}

static void testCredentalsWithConnectionReturnsNilWhenDelegateDoesNotRespond(void) {
	MADTestSilentDelegate *delegate = [[MADTestSilentDelegate alloc] init];
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	MAD_PASS([db credentalsWithConnection:connection] == nil, "a silent delegate yields no credential");
}

static void testCredentalsWithConnectionReturnsNilWhenDelegateHasNoCredential(void) {
	MADTestCredentialDelegate *delegate = [[MADTestCredentialDelegate alloc] init];
	delegate.credential = nil;

	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";

	MADDatabase *db = [[MADDatabase alloc] init];
	db.delegate = delegate;

	MAD_PASS([db credentalsWithConnection:connection] == nil, "a delegate with no credential yields none");
}

#pragma mark - Factory

static void testNewDatabaseWithConnectionReturnsInstanceOfReceiver(void) {
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];

	MAD_PASS(db != nil, "the factory builds an instance");
	MAD_PASS_EQUAL(NSStringFromClass([db class]), NSStringFromClass([MADDatabase class]), "the instance is the receiver class");
	// The base factory ignores the connection; subclasses that care override it.
	MAD_PASS(db.databaseConnection == nil, "the base factory ignores the connection");
}

#pragma mark - NSCopying

static void testCopyPreservesState(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MADTestCredentialConnection *connection = [[MADTestCredentialConnection alloc] init];
	connection.connectionString = @"(MADTestCredentialConnection)[host:3306]db";
	db.databaseConnection = connection;
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

	MADDatabase *copy = [db copy];

	MAD_PASS(copy != db, "the copy is a different object");
	MAD_PASS(copy.isLicensedUser, "the licensed flag survives");
	MAD_PASS(copy.errors.count == (NSUInteger)1, "the errors survive");
	// The errors array is a distinct mutable array, not the original.
	MAD_PASS(copy.errors != db.errors, "the errors array is distinct");
	// The connection is copied, not shared.
	MAD_PASS(copy.databaseConnection != db.databaseConnection, "the connection is copied");
	MAD_PASS_EQUAL(copy.databaseConnection.connectionString, @"(MADTestCredentialConnection)[host:3306]db", "the connection string survives");
}

#pragma mark - NSSecureCoding

// The classic archive path still works: a permissive archiver and unarchiver use the
// same coding methods without enforcing the class allowlist.
static void testInsecureNSCodingRoundTrip(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

#if __APPLE__
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
	[archiver encodeObject:db forKey:NSKeyedArchiveRootObjectKey];
	NSData *data = archiver.encodedData;
	MAD_PASS(data != nil, "the insecure archive has bytes");

	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:NULL];
	// -initForReadingFromData:error: defaults to requiring secure coding; the classic
	// path is exercised here deliberately.
	unarchiver.requiresSecureCoding = NO;
	MADDatabase *decoded = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[unarchiver finishDecoding];
#else
	// GNUstep's NSKeyedArchiver has no instance API (-initRequiringSecureCoding:,
	// -encodedData) and its unarchiver no -initForReadingFromData:error:, so the same
	// insecure coder is reached through the class entry points -- the path the framework
	// ships on this platform.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:NO error:NULL];
	MAD_PASS(data != nil, "the insecure archive has bytes");
	MADDatabase *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
	MAD_PASS(decoded != nil, "the database round trips");
	MAD_PASS(decoded.isLicensedUser, "the licensed flag survives the round trip");
	MAD_PASS(decoded.errors.count == (NSUInteger)1, "the errors survive the round trip");
	MAD_PASS(decoded.databaseConnection == nil, "the connection does not survive");
}

// MADDatabase declares NSSecureCoding.  Apple's strict archiver round-trips it; GNUstep
// has no secure archiving at all -- the strict archive is nil with no error
// (Linux/README.md) -- so only the codec claim and the refusal can be asserted there.
static void testSecureCodingRoundTrip(void) {
	MAD_PASS([MADDatabase supportsSecureCoding], "the class claims secure coding");

	MADDatabase *db = [[MADDatabase alloc] init];
	[db.errors addObject:[NSError errorWithDomain:@"com.example.tests" code:9 userInfo:nil]];
	[db setValue:@YES forKey:@"isLicensedUser"];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:YES error:&error];

#if __APPLE__
	MAD_PASS(data != nil, "the strict archive has bytes");
	MAD_PASS(error == nil, "the strict archive succeeds");

	MADDatabase *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabase class]
														   fromData:data
															  error:&error];
	MAD_PASS(error == nil, "the strict unarchive succeeds");
	MAD_PASS(decoded != nil, "the database round trips");
	MAD_PASS(decoded.isLicensedUser, "the licensed flag survives the round trip");
	MAD_PASS(decoded.errors.count == (NSUInteger)1, "the errors survive the round trip");
	MAD_PASS(decoded.databaseConnection == nil, "the connection does not survive");
#else
	// GNUstep's strict archiver answers nil with no error (Linux/README.md).  The
	// permissive round trip is testInsecureNSCodingRoundTrip's job.
	MAD_PASS(data == nil, "GNUstep refuses the strict archive");
	MAD_PASS(error == nil, "GNUstep refuses without an error");
#endif
}

// A decoded instance must be constructed the way -copyWithZone: constructs one -- through
// the concrete subclass's -init -- so its own setup (an observer, a queue) is not skipped.
static void testDecodingRunsTheSubclassInitializer(void) {
	MADTestInitializedDatabase *db = [[MADTestInitializedDatabase alloc] init];
	MAD_PASS(db.didRunInit, "the subclass initializer runs on construction");

#if __APPLE__
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:YES error:&error];
	MAD_PASS(error == nil, "the strict archive succeeds");
	MADTestInitializedDatabase *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADTestInitializedDatabase class]
																		   fromData:data
																			  error:&error];
	MAD_PASS(error == nil, "the strict unarchive succeeds");
#else
	// GNUstep has no secure archiving; the permissive coder is the platform's path
	// (Linux/README.md).
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:db requiringSecureCoding:NO error:NULL];
	MAD_PASS(data != nil, "the permissive archive has bytes");
	MADTestInitializedDatabase *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
	MAD_PASS(decoded != nil, "the database round trips");
	MAD_PASS(decoded.didRunInit, "decoding runs the subclass initializer");
}

#pragma mark - Literal escaping limits

// The base class escapes only the quote character.  A backslash is deliberately left
// alone: whether it escapes the following character depends on the session's
// NO_BACKSLASH_ESCAPES setting, which only the dialect's connection object knows.  See
// MADDatabaseSQLProtocol.h and BUGS.md.
static void testNewSafeLiteralLeavesBackslashUntouched(void) {
	MADDatabase *db = [[MADDatabase alloc] init];
	MAD_PASS_EQUAL([db newSafeLiteral:@"a\\b"], @"'a\\b'", "a backslash is left alone");
	MAD_PASS_EQUAL([db newSafeLiteral:@"a\\'b"], @"'a\\''b'", "a backslash before a quote stays as written");
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
	MAD_TEST(testReadRowPostsNotification),
	MAD_TEST(testCredentalsWithConnectionCopiesFromRespondingDelegate),
	MAD_TEST(testCredentalsWithConnectionReturnsNilWhenDelegateDoesNotRespond),
	MAD_TEST(testCredentalsWithConnectionReturnsNilWhenDelegateHasNoCredential),
	MAD_TEST(testNewDatabaseWithConnectionReturnsInstanceOfReceiver),
	MAD_TEST(testCopyPreservesState),
	MAD_TEST(testInsecureNSCodingRoundTrip),
	MAD_TEST(testSecureCodingRoundTrip),
	MAD_TEST(testDecodingRunsTheSubclassInitializer),
	MAD_TEST(testNewSafeLiteralLeavesBackslashUntouched));
