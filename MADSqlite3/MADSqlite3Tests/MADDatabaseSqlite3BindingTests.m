//
//  MADDatabaseSqlite3BindingTests.m
//  MADSqlite3Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the cache's bind path: a value bound under a column's declared
//  MADDataType, and the storage class it lands in.  Every pair is driven through
//  MADDatabaseDataBinding and -bindStatement:withBindings: into a NONE-affinity
//  column, so what sqlite3_column_type reports is exactly the class the bind
//  stored -- no affinity conversion.  See BUGS.md, "MADReportFormatter compares
//  untyped values through id" (the canonical-class contract).
//
//  Two tranches.  "Characterization" pins the pairs whose stored form the
//  contract keeps (NSNull -> NULL, NSNumber -> numeric, NSString -> TEXT,
//  NSData -> BLOB, and the coercions the bind has always done).  "Contract"
//  pins the pairs the contract changes: a value the bind could not represent
//  used to vanish silently (or raise); it must now be converted to the
//  column's canonical class, or stored NULL with a log -- never bound as
//  another class.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import "MADDatabaseSqlite3.h"
#import "sqlite3.h"

@interface MADDatabaseSqlite3BindingTests : XCTestCase

@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, strong) MADDatabaseSqlite3 *sqliteDatabase;

@end

@implementation MADDatabaseSqlite3BindingTests

- (void)setUp {
	[super setUp];
	XCTAssertEqual(sqlite3_open(":memory:", &_database), SQLITE_OK);
	XCTAssertEqual(sqlite3_exec(self.database, "CREATE TABLE t (c);", NULL, NULL, NULL), SQLITE_OK);
	// The binder is an instance method; it reads the handle only for error text.
	self.sqliteDatabase = [[MADDatabaseSqlite3 alloc] init];
}

- (void)tearDown {
	self.sqliteDatabase = nil;
	sqlite3_close(_database);
	_database = NULL;
	[super tearDown];
}

// Binds one value under its declared type and answers what the untyped reader
// gives back for the stored cell, with the raw storage class out.  The table is
// emptied between calls, so each pair is independent.
- (id)storedValueForType:(MADDataType)type value:(id)value storageClass:(int *)outStorageClass {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:value];
	sqlite3_stmt *statement = NULL;
	XCTAssertEqual(sqlite3_prepare_v2(self.database, "INSERT INTO t (c) VALUES (?);", -1, &statement, NULL), SQLITE_OK);
	[self.sqliteDatabase bindStatement:(void **)&statement withBindings:binding];
	XCTAssertEqual(sqlite3_step(statement), SQLITE_DONE);
	sqlite3_finalize(statement);

	XCTAssertEqual(sqlite3_prepare_v2(self.database, "SELECT c FROM t;", -1, &statement, NULL), SQLITE_OK);
	XCTAssertEqual(sqlite3_step(statement), SQLITE_ROW);
	int storage = sqlite3_column_type(statement, 0);
	id stored = [MADDatabaseSqlite3 databaseResultValue:statement columnNumber:0];
	sqlite3_finalize(statement);
	XCTAssertEqual(sqlite3_exec(self.database, "DELETE FROM t;", NULL, NULL, NULL), SQLITE_OK);

	if (outStorageClass != NULL) *outStorageClass = storage;
	return stored;
}

#pragma mark - Characterization (the pairs the contract keeps)

- (void)testNullValuesStoreNull {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeString value:[NSNull null] storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_NULL);
	XCTAssertEqual(stored, [NSNull null]);
}

- (void)testBlobDataStoresABlob {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeBlob value:data storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_BLOB);
	XCTAssertTrue([stored isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(stored, data);
}

- (void)testStringTextStoresText {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeString value:@"hello" storageClass:&storage];
	XCTAssertEqual(storage, SQLITE3_TEXT);
	XCTAssertEqualObjects(stored, @"hello");
}

- (void)testIntegerNumberStoresAnInteger {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeInteger value:@42 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_INTEGER);
	XCTAssertEqualObjects(stored, @42);
}

- (void)testDoubleNumberStoresAReal {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDouble value:@1.5 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_FLOAT);
	XCTAssertEqualWithAccuracy([(NSNumber *)stored doubleValue], 1.5, 0.0001);
}

- (void)testUnknownTypeStringifiesValues {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeUnknown value:@42 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE3_TEXT);
	XCTAssertEqualObjects(stored, @"42");
}

- (void)testDateComponentsInAStringColumnStoreTheEpoch {
	NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.calendar = gregorian;
	components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	components.year = 2020; components.month = 1; components.day = 2;
	components.hour = 3; components.minute = 4; components.second = 5;
	NSDate *expected = [gregorian dateFromComponents:components];

	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDate value:components storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_FLOAT);
	XCTAssertEqualWithAccuracy([(NSNumber *)stored doubleValue], expected.timeIntervalSince1970, 0.001);
}

- (void)testNumberInABlobColumnStoresNull {
	// Never silently another class: a number cannot be blob bytes, so the cell
	// is NULL -- silently today, logged once under the contract.
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeBlob value:@1 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_NULL);
	XCTAssertEqual(stored, [NSNull null]);
}

- (void)testTextInAnIntegerColumnParsesTheNumber {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeInteger value:@"42" storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_INTEGER);
	XCTAssertEqualObjects(stored, @42);
}

- (void)testTextInADoubleColumnCoercesTheNumber {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDouble value:@"1.5" storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_FLOAT);
	XCTAssertEqualWithAccuracy([(NSNumber *)stored doubleValue], 1.5, 0.0001);
}

#pragma mark - Contract (the pairs the contract changes)

- (void)testDateInAStringColumnStoresNullWithoutRaising {
	// The old bind stored nothing and the cell came back NULL.  A plain string
	// column is not a date-family type -- only Date/DateTime/TimeStamp/Time get
	// the epoch form -- so an NSDate cannot be represented here: NULL with a
	// one-time log, never a crash and never another class.
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeString value:date storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_NULL);
	XCTAssertEqual(stored, [NSNull null]);
}

- (void)testDateInADateTimeColumnStoresTheEpoch {
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDateTime value:date storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_FLOAT);
	XCTAssertEqualWithAccuracy([(NSNumber *)stored doubleValue], date.timeIntervalSince1970, 0.001);
}

- (void)testTextInABlobColumnStoresUtf8Data {
	// BUGS.md: the old bind stored the string as TEXT -- a different storage
	// class than the column's.  The canonical blob class is NSData.
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeBlob value:@"abc" storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_BLOB);
	XCTAssertTrue([stored isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(stored, [@"abc" dataUsingEncoding:NSUTF8StringEncoding]);
}

- (void)testNumberInAStringColumnStoresItsText {
	// BUGS.md: the old bind stored nothing and the cell came back NULL.  The
	// canonical string class is NSString, and a number has a string form.
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeString value:@42 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE3_TEXT);
	XCTAssertEqualObjects(stored, @"42");
}

- (void)testTextInADateColumnParsesTheEpoch {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDate value:@"1234567890" storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_FLOAT);
	XCTAssertEqualWithAccuracy([(NSNumber *)stored doubleValue], 1234567890.0, 0.001);
}

- (void)testDataInAnIntegerColumnStoresNullWithoutRaising {
	// The old bind sent -longLongValue to the NSData and raised; a value the
	// column cannot represent must be NULL with a log, never a crash.
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeInteger value:data storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_NULL);
	XCTAssertEqual(stored, [NSNull null]);
}

- (void)testDateInADoubleColumnStoresNullWithoutRaising {
	// The old bind sent -doubleValue to the NSDate and raised.
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeDouble value:date storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_NULL);
	XCTAssertEqual(stored, [NSNull null]);
}

- (void)testBitStoresAnInteger {
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeBit value:@1 storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_INTEGER);
	XCTAssertEqualObjects(stored, @1);
}

- (void)testSetYearAndGeometryStoreText {
	for (NSNumber *boxed in @[@(MADDataTypeSet), @(MADDataTypeYear), @(MADDataTypeGeometry)]) {
		MADDataType type = (MADDataType)boxed.intValue;
		int storage = 0;
		id stored = [self storedValueForType:type value:@"x" storageClass:&storage];
		XCTAssertEqual(storage, SQLITE3_TEXT, @"%@ stores TEXT", NSStringFromMADDataType(type));
		XCTAssertEqualObjects(stored, @"x");
	}
}

- (void)testImageStoresABlob {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	int storage = 0;
	id stored = [self storedValueForType:MADDataTypeImage value:data storageClass:&storage];
	XCTAssertEqual(storage, SQLITE_BLOB);
	XCTAssertTrue([stored isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(stored, data);
}

- (void)testHandBuiltBindingOutsideTheContractAsserts {
	// A binding that bypasses -initWithDataType:fieldIndex:value: reaches the
	// binder with a class its type cannot have: debug asserts; release logs
	// once and stores NULL.  KVC writes through the readonly property's ivar,
	// the way a hand-built binding would.
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@1];
	[binding setValue:@"not a number" forKey:@"value"];

	sqlite3_stmt *statement = NULL;
	XCTAssertEqual(sqlite3_prepare_v2(self.database, "INSERT INTO t (c) VALUES (?);", -1, &statement, NULL), SQLITE_OK);
	XCTAssertThrowsSpecificNamed([self.sqliteDatabase bindStatement:(void **)&statement withBindings:binding],
								 NSException, NSInternalInconsistencyException);
	sqlite3_finalize(statement);
}

@end
