//
//  MADDatabaseSqlite3BindingTests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDatabaseSqlite3BindingTests.m: the cache's
//  bind path -- a value bound under a column's declared MADDataType, and the
//  storage class it lands in.  Every pair is driven through MADDatabaseDataBinding
//  and -bindStatement:withBindings: into a NONE-affinity column, so what
//  sqlite3_column_type reports is exactly the class the bind stored -- no
//  affinity conversion.  See BUGS.md, "MADReportFormatter compares untyped
//  values through id" (the canonical-class contract).
//
//  Two tranches.  "Characterization" pins the pairs whose stored form the
//  contract keeps; "Contract" pins the pairs the contract changes.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseDataBinding.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/sqlite3.h>

// One round trip: bind one value under its declared type into a NONE-affinity
// column, then answer what the untyped reader gives back for the stored cell,
// with the raw storage class out.
static id MADBindStoredValue(sqlite3 *database, MADDatabaseSqlite3 *sqliteDatabase,
							 MADDataType type, id value, int *outStorageClass) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:value];
	sqlite3_stmt *statement = NULL;
	MAD_PASS(sqlite3_prepare_v2(database, "INSERT INTO t (c) VALUES (?);", -1, &statement, NULL) == SQLITE_OK,
			 "the insert prepares");
	if (statement == NULL) return nil;
	[sqliteDatabase bindStatement:(void **)&statement withBindings:binding];
	sqlite3_step(statement);
	sqlite3_finalize(statement);

	MAD_PASS(sqlite3_prepare_v2(database, "SELECT c FROM t;", -1, &statement, NULL) == SQLITE_OK, "the select prepares");
	if (statement == NULL) return nil;
	MAD_PASS(sqlite3_step(statement) == SQLITE_ROW, "the select has a row");
	int storage = sqlite3_column_type(statement, 0);
	id stored = [MADDatabaseSqlite3 databaseResultValue:statement columnNumber:0];
	sqlite3_finalize(statement);
	sqlite3_exec(database, "DELETE FROM t;", NULL, NULL, NULL);

	if (outStorageClass != NULL) *outStorageClass = storage;
	return stored;
}

#pragma mark - Characterization (the pairs the contract keeps)

static void testNullValuesStoreNull(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeString, [NSNull null], &storage);
	MAD_PASS(storage == SQLITE_NULL, "a null value stores NULL");
	MAD_PASS(stored == [NSNull null], "the reader answers NSNull");

	sqlite3_close(database);
}

static void testBlobDataStoresABlob(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeBlob, data, &storage);
	MAD_PASS(storage == SQLITE_BLOB, "blob data stores a BLOB");
	MAD_PASS([stored isKindOfClass:[NSData class]], "the reader answers NSData");
	MAD_PASS_EQUAL(stored, data, "the bytes survive");

	sqlite3_close(database);
}

static void testStringTextStoresText(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeString, @"hello", &storage);
	MAD_PASS(storage == SQLITE3_TEXT, "string text stores TEXT");
	MAD_PASS_EQUAL(stored, @"hello", "the text survives");

	sqlite3_close(database);
}

static void testIntegerNumberStoresAnInteger(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeInteger, @42, &storage);
	MAD_PASS(storage == SQLITE_INTEGER, "an integer stores INTEGER");
	MAD_PASS_EQUAL(stored, @42, "the number survives");

	sqlite3_close(database);
}

static void testDoubleNumberStoresAReal(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDouble, @1.5, &storage);
	MAD_PASS(storage == SQLITE_FLOAT, "a double stores REAL");
	MAD_PASS([stored isKindOfClass:[NSNumber class]], "the reader answers NSNumber");
	MAD_PASS(((NSNumber *)stored).doubleValue > 1.49 && ((NSNumber *)stored).doubleValue < 1.51, "the double survives");

	sqlite3_close(database);
}

static void testUnknownTypeStringifiesValues(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeUnknown, @42, &storage);
	MAD_PASS(storage == SQLITE3_TEXT, "an unknown type stores TEXT");
	MAD_PASS_EQUAL(stored, @"42", "the value is stringified");

	sqlite3_close(database);
}

static void testDateComponentsInAStringColumnStoreTheEpoch(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.calendar = gregorian;
	components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	components.year = 2020; components.month = 1; components.day = 2;
	components.hour = 3; components.minute = 4; components.second = 5;
	NSDate *expected = [gregorian dateFromComponents:components];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDate, components, &storage);
	MAD_PASS(storage == SQLITE_FLOAT, "date components store REAL");
	MAD_PASS(((NSNumber *)stored).doubleValue > expected.timeIntervalSince1970 - 0.001 &&
			 ((NSNumber *)stored).doubleValue < expected.timeIntervalSince1970 + 0.001,
			 "the epoch is the components' date");

	sqlite3_close(database);
}

static void testNumberInABlobColumnStoresNull(void) {
	// Never silently another class: a number cannot be blob bytes, so the cell
	// is NULL -- silently before the contract, logged once under it.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeBlob, @1, &storage);
	MAD_PASS(storage == SQLITE_NULL, "a number in a blob column stores NULL");
	MAD_PASS(stored == [NSNull null], "the reader answers NSNull");

	sqlite3_close(database);
}

static void testTextInAnIntegerColumnParsesTheNumber(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeInteger, @"42", &storage);
	MAD_PASS(storage == SQLITE_INTEGER, "a numeric string stores INTEGER");
	MAD_PASS_EQUAL(stored, @42, "the string is parsed");

	sqlite3_close(database);
}

static void testTextInADoubleColumnCoercesTheNumber(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDouble, @"1.5", &storage);
	MAD_PASS(storage == SQLITE_FLOAT, "a numeric string stores REAL");
	MAD_PASS(((NSNumber *)stored).doubleValue > 1.49 && ((NSNumber *)stored).doubleValue < 1.51, "the string is coerced");

	sqlite3_close(database);
}

#pragma mark - Contract (the pairs the contract changes)

static void testDateInAStringColumnStoresNullWithoutRaising(void) {
	// The old bind stored nothing and the cell came back NULL.  A plain string
	// column is not a date-family type -- only Date/DateTime/TimeStamp/Time get
	// the epoch form -- so an NSDate cannot be represented here: NULL with a
	// one-time log, never a crash and never another class.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeString, date, &storage);
	MAD_PASS(storage == SQLITE_NULL, "a date in a plain string column stores NULL");
	MAD_PASS(stored == [NSNull null], "the reader answers NSNull");

	sqlite3_close(database);
}

static void testDateInADateTimeColumnStoresTheEpoch(void) {
	// BUGS.md: NSDate is not NSString, so the old bind stored nothing and the
	// cell came back NULL.  The date family's canonical class is the epoch
	// number, which is what the display path reads.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDateTime, date, &storage);
	MAD_PASS(storage == SQLITE_FLOAT, "a date stores REAL");
	MAD_PASS(((NSNumber *)stored).doubleValue > 1234567890.49 && ((NSNumber *)stored).doubleValue < 1234567890.51,
			 "the epoch is the date's");

	sqlite3_close(database);
}

static void testTextInABlobColumnStoresUtf8Data(void) {
	// BUGS.md: the old bind stored the string as TEXT -- a different storage
	// class than the column's.  The canonical blob class is NSData.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeBlob, @"abc", &storage);
	MAD_PASS(storage == SQLITE_BLOB, "text in a blob column stores BLOB");
	MAD_PASS([stored isKindOfClass:[NSData class]], "the reader answers NSData");
	MAD_PASS_EQUAL(stored, [@"abc" dataUsingEncoding:NSUTF8StringEncoding], "the UTF-8 bytes survive");

	sqlite3_close(database);
}

static void testNumberInAStringColumnStoresItsText(void) {
	// BUGS.md: the old bind stored nothing and the cell came back NULL.  The
	// canonical string class is NSString, and a number has a string form.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeString, @42, &storage);
	MAD_PASS(storage == SQLITE3_TEXT, "a number in a string column stores TEXT");
	MAD_PASS_EQUAL(stored, @"42", "the number's text survives");

	sqlite3_close(database);
}

static void testTextInADateColumnParsesTheEpoch(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDate, @"1234567890", &storage);
	MAD_PASS(storage == SQLITE_FLOAT, "an epoch string stores REAL");
	MAD_PASS(((NSNumber *)stored).doubleValue > 1234567889.0 && ((NSNumber *)stored).doubleValue < 1234567891.0,
			 "the string is parsed as the epoch");

	sqlite3_close(database);
}

static void testDataInAnIntegerColumnStoresNullWithoutRaising(void) {
	// The old bind sent -longLongValue to the NSData and raised; a value the
	// column cannot represent must be NULL with a log, never a crash.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeInteger, data, &storage);
	MAD_PASS(storage == SQLITE_NULL, "data in an integer column stores NULL");
	MAD_PASS(stored == [NSNull null], "the reader answers NSNull");

	sqlite3_close(database);
}

static void testDateInADoubleColumnStoresNullWithoutRaising(void) {
	// The old bind sent -doubleValue to the NSDate and raised.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeDouble, date, &storage);
	MAD_PASS(storage == SQLITE_NULL, "a date in a double column stores NULL");
	MAD_PASS(stored == [NSNull null], "the reader answers NSNull");

	sqlite3_close(database);
}

static void testBitStoresAnInteger(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeBit, @1, &storage);
	MAD_PASS(storage == SQLITE_INTEGER, "a bit stores INTEGER");
	MAD_PASS_EQUAL(stored, @1, "the bit survives");

	sqlite3_close(database);
}

static void testSetYearAndGeometryStoreText(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSArray<NSNumber *> *types = @[@(MADDataTypeSet), @(MADDataTypeYear), @(MADDataTypeGeometry)];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		int storage = 0;
		id stored = MADBindStoredValue(database, sqliteDatabase, type, @"x", &storage);
		MAD_PASS(storage == SQLITE3_TEXT, "set/year/geometry store TEXT");
		MAD_PASS_EQUAL(stored, @"x", "the text survives");
	}

	sqlite3_close(database);
}

static void testImageStoresABlob(void) {
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = MADBindStoredValue(database, sqliteDatabase, MADDataTypeImage, data, &storage);
	MAD_PASS(storage == SQLITE_BLOB, "an image stores BLOB");
	MAD_PASS([stored isKindOfClass:[NSData class]], "the reader answers NSData");
	MAD_PASS_EQUAL(stored, data, "the bytes survive");

	sqlite3_close(database);
}

static void testHandBuiltBindingOutsideTheContractAsserts(void) {
	// A binding that bypasses -initWithDataType:fieldIndex:value: reaches the
	// binder with a class its type cannot have: debug asserts; release logs
	// once and stores NULL.  KVC writes through the readonly property's ivar,
	// the way a hand-built binding would.
	sqlite3 *database = NULL;
	sqlite3_open(":memory:", &database);
	sqlite3_exec(database, "CREATE TABLE t (c);", NULL, NULL, NULL);
	MADDatabaseSqlite3 *sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];

	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@1];
	[binding setValue:@"not a number" forKey:@"value"];

	sqlite3_stmt *statement = NULL;
	MAD_PASS(sqlite3_prepare_v2(database, "INSERT INTO t (c) VALUES (?);", -1, &statement, NULL) == SQLITE_OK,
			 "the insert prepares");
	if (statement != NULL) {
		MAD_THROWS_NAMED([sqliteDatabase bindStatement:(void **)&statement withBindings:binding],
						 @"NSInternalInconsistencyException", "a hand-built binding outside the contract asserts");
		sqlite3_finalize(statement);
	}

	sqlite3_close(database);
}

MAD_TEST_MAIN("MADDatabaseSqlite3BindingTests",
	MAD_TEST(testNullValuesStoreNull),
	MAD_TEST(testBlobDataStoresABlob),
	MAD_TEST(testStringTextStoresText),
	MAD_TEST(testIntegerNumberStoresAnInteger),
	MAD_TEST(testDoubleNumberStoresAReal),
	MAD_TEST(testUnknownTypeStringifiesValues),
	MAD_TEST(testDateComponentsInAStringColumnStoreTheEpoch),
	MAD_TEST(testNumberInABlobColumnStoresNull),
	MAD_TEST(testTextInAnIntegerColumnParsesTheNumber),
	MAD_TEST(testTextInADoubleColumnCoercesTheNumber),
	MAD_TEST(testDateInAStringColumnStoresNullWithoutRaising),
	MAD_TEST(testDateInADateTimeColumnStoresTheEpoch),
	MAD_TEST(testTextInABlobColumnStoresUtf8Data),
	MAD_TEST(testNumberInAStringColumnStoresItsText),
	MAD_TEST(testTextInADateColumnParsesTheEpoch),
	MAD_TEST(testDataInAnIntegerColumnStoresNullWithoutRaising),
	MAD_TEST(testDateInADoubleColumnStoresNullWithoutRaising),
	MAD_TEST(testBitStoresAnInteger),
	MAD_TEST(testSetYearAndGeometryStoreText),
	MAD_TEST(testImageStoresABlob),
	MAD_TEST(testHandBuiltBindingOutsideTheContractAsserts));
