//
//  MADDatabaseSqlite3Tests.m
//  MADSqlite3Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Stateless (no live database) coverage for the MADSqlite3 framework:
//    * MADDatabaseSqlite3 class methods (type/affinity mapping, safe identifiers,
//      sort descriptions, native types) and the C helpers it exposes.
//    * MADDatabaseConnectionSqlite3 (the connection value object).
//    * Every MADQueryCache* SQL builder plus the MADQuery (Sqlite3) category.
//

#import <XCTest/XCTest.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADQueryCacheBeginTransaction.h>
#import <MADSqlite3/MADQueryCacheEndTransaction.h>
#import <MADSqlite3/MADQueryCacheSyncOff.h>
#import <MADSqlite3/MADQueryCacheSyncDefault.h>
#import <MADSqlite3/MADQueryCacheJournalModeOverride.h>
#import <MADSqlite3/MADQueryCacheDropTable.h>
#import <MADSqlite3/MADQueryCacheDeleteAllFromTable.h>
#import <MADSqlite3/MADQueryCacheSelectRowId.h>
#import <MADSqlite3/MADQueryCacheSelectRowIds.h>
#import <MADSqlite3/MADQuerySelectParameters.h>
#import <MADSqlite3/MADQuery+Sqlite3.h>

#import "MADQueryCacheAddColumn.h"
#import "MADQueryCacheAddRow.h"
#import "MADQueryCacheIndexCreate.h"
#import "MADQueryCacheIndexDrop.h"
#import "MADQueryCacheSelectLimitOffset.h"
#import "MADQueryCacheVacuum.h"
#import "MADQuerySelectItemsForGroup.h"
#import "MADQueryCacheAddColumnParameters.h"
#import "MADQueryCacheDeleteAllFromTableParameters.h"
#import "MADQueryCacheIndexCreateParameters.h"
#import "MADQueryCacheIndexDropParameters.h"
#import "MADQueryParameters.h"
#import "sqlite3.h"

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSString+Comparison.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADDatabaseDataBinding.h>
#import <MADAPI/MADDatabaseType.h>

// MADDatabaseSqlite3 implements several class methods that are intentionally not
// declared on its public header (they are treated as framework-private).  Declare
// them here so the tests can exercise them without a spurious compiler warning.
@interface MADDatabaseSqlite3 (TestAccess)
+ (MADDataType)dataTypeForNativeType:(NSString *)nativeType;
+ (MADDataType)dataTypeForAffentyType:(int)affentyType;
+ (MADDataType)dataTypeForNativeTypeNumeric:(MADDataType)dataType;
@end

// -type is implemented on the MADQuery subclasses but never declared in a header.
@interface MADQuery (TestQueryType)
- (MADQueryType)type;
@end

// Test double that conforms to the column/protocol contracts the category methods
// in MADQuery+Sqlite3 need.
@interface MADQuerySqlite3ColumnDouble : MADQuery <MADQueryColumnsProtocol, MADQueryDataBindingProtocol>
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSMutableArray *binaryBindings;
@end

@implementation MADQuerySqlite3ColumnDouble
@end

// Test double that feeds MADQueryCacheAddRow its four data-source protocols.
@interface MADQueryCacheAddRowTestDelegate : NSObject
	<MADQueryParametersStandardProtocol,
	MADQueryParametersColumnKeysProtocol,
	MADQueryParametersColumnMetaProtocol,
	MADQueryParametersColumnDataProtocol>
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, strong) NSArray <NSString *> *columnKeys;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *rowData;
@end

@implementation MADQueryCacheAddRowTestDelegate

- (NSString *)queryTableName { return self.tableName; }
- (NSArray <NSString *> *)queryColumnKeys { return self.columnKeys; }
- (NSDictionary *)queryColumns { return self.columns; }
- (NSArray *)queryRowData { return self.rowData; }

@end

@interface MADDatabaseSqlite3Tests : XCTestCase
@end

@implementation MADDatabaseSqlite3Tests

#pragma mark - Type / affinity mapping

- (void)testDataTypeForNativeTypeMapsIntegerAffinities {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"INT"], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"INTEGER"], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"BIGINT"], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"TINYINT"], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"SMALLINT"], MADDataTypeInteger);
}

- (void)testDataTypeForNativeTypeMapsTextAffinities {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"CHAR"], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"TEXT"], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"CLOB"], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"VARCHAR(255)"], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"NCHAR"], MADDataTypeString);
}

- (void)testDataTypeForNativeTypeMapsBlobAndEmpty {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"BLOB"], MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@""], MADDataTypeBlob);
	// nil maps to MADDataTypeInteger (not Blob): [nil rangeOfString:] returns a zeroed
	// NSRange whose location (0) != NSNotFound, so isInteger is treated as YES.
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:nil], MADDataTypeInteger);
}

- (void)testDataTypeForNativeTypeMapsRealAndNumericAffinities {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"REAL"], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"FLOAT"], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"DOUBLE"], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"DOUBLE PRECISION"], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"NUMERIC"], MADDataTypeNumber);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"DECIMAL(10,5)"], MADDataTypeNumber);
}

- (void)testDataTypeForNativeTypeDefaultsToNumber {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"BOOLEAN"], MADDataTypeNumber);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeType:@"SOMETHING"], MADDataTypeNumber);
}

- (void)testDataTypeForAffentyType {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_INTEGER], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_FLOAT], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_BLOB], MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_NULL], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE3_TEXT], MADDataTypeString);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForAffentyType:999], MADDataTypeString);
}

- (void)testDataTypeForNativeTypeNumericIntegerFamily {
	MADDataType integerTypes[] = {
		MADDataTypeBit, MADDataTypeInteger, MADDataTypeShort, MADDataTypeLong,
		MADDataTypeLongLong, MADDataTypeInt24, MADDataTypeEnum
	};
	for (NSUInteger i = 0; i < sizeof(integerTypes) / sizeof(integerTypes[0]); i++) {
		XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:integerTypes[i]], MADDataTypeInteger);
	}
}

- (void)testDataTypeForNativeTypeNumericStringFamily {
	MADDataType stringTypes[] = {
		MADDataTypeSet, MADDataTypeTime, MADDataTypeTimeStamp, MADDataTypeYear,
		MADDataTypeDate, MADDataTypeDateTime, MADDataTypeString, MADDataTypeVarChar,
		MADDataTypeGeometry
	};
	for (NSUInteger i = 0; i < sizeof(stringTypes) / sizeof(stringTypes[0]); i++) {
		XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:stringTypes[i]], MADDataTypeString);
	}
}

- (void)testDataTypeForNativeTypeNumericBlobFloatAndDecimal {
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeImage], MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeBlob], MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeFloat], MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeDouble], MADDataTypeDouble);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeDecimal], MADDataTypeDecimal);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeNumber], MADDataTypeDecimal);
	XCTAssertEqual([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeUnknown], MADDataTypeString);
}

- (void)testSqlite3NativeType {
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeInteger], @"INTEGER");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeLong], @"INTEGER");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeShort], @"INTEGER");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeBit], @"INTEGER");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeEnum], @"INTEGER");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeString], @"TEXT");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeVarChar], @"TEXT");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDate], @"TEXT");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeGeometry], @"TEXT");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeImage], @"NONE");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeBlob], @"NONE");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeFloat], @"REAL");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDouble], @"REAL");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDecimal], @"NUMERIC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeNumber], @"NUMERIC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeUnknown], @"TEXT");
}

- (void)testSortDescriptionForColumnType {
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeString ascending:YES], @"COLLATE LSASC ASC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeString ascending:NO], @"COLLATE LSASC DESC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeVarChar ascending:YES], @"COLLATE LSASC ASC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeInteger ascending:YES], @"ASC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeInteger ascending:NO], @"DESC");
	XCTAssertEqualObjects([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeDouble ascending:YES], @"ASC");
}

#pragma mark - Safe identifiers

- (void)testSafeQueryFieldAndIdentifier {
	XCTAssertEqualObjects([MADDatabaseSqlite3 newSafeQueryField:@"field" andTable:@"table"], @"\"table\".\"field\"");
	XCTAssertEqualObjects([MADDatabaseSqlite3 newSafeIdentifier:@"identifier"], @"\"identifier\"");

	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	XCTAssertEqualObjects([database newSafeIdentifier:@"identifier"], @"\"identifier\"");
	XCTAssertEqualObjects([database queryKey:@"field" table:@"table"], @"\"table\".\"field\"");
}

- (void)testDriverAndIconNames {
	XCTAssertEqualObjects([MADDatabaseSqlite3 driverName], @"Sqlite 3");
	XCTAssertEqualObjects([MADDatabaseSqlite3 imageIconName], @"MADImageSqlite3");
}

#pragma mark - C helpers

- (void)testSqlite3StepResultOK {
	XCTAssertTrue(Sqlite3StepResultOK(SQLITE_OK));
	XCTAssertTrue(Sqlite3StepResultOK(SQLITE_ROW));
	XCTAssertTrue(Sqlite3StepResultOK(SQLITE_DONE));
	XCTAssertFalse(Sqlite3StepResultOK(SQLITE_ERROR));
	XCTAssertFalse(Sqlite3StepResultOK(SQLITE_BUSY));
	XCTAssertFalse(Sqlite3StepResultOK(-1));
}

- (NSComparisonResult)collationResultBetween:(NSString *)lhs and:(NSString *)rhs {
	const char *l = lhs.UTF8String;
	const char *r = rhs.UTF8String;
	int result = compare_string_utf8_localized_asc_collation(NULL,
															 (int)[lhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], l,
															 (int)[rhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], r);
	return (NSComparisonResult)result;
}

- (void)testCompareStringUtf8LocalizedAscCollation {
	XCTAssertEqual([self collationResultBetween:@"a" and:@"b"], NSOrderedAscending);
	XCTAssertEqual([self collationResultBetween:@"b" and:@"a"], NSOrderedDescending);
	XCTAssertEqual([self collationResultBetween:@"a" and:@"a"], NSOrderedSame);
	// The defined order both platforms share now (MAD_CLI.md's `mad export`
	// section, MADStringOrderedCompareUTF8): case-fold, then UTF-8 code-point
	// order.  These hold identically on Apple and GNUstep -- that is the point.
	XCTAssertEqual([self collationResultBetween:@"A" and:@"b"], NSOrderedAscending);
	XCTAssertEqual([self collationResultBetween:@"a" and:@"B"], NSOrderedAscending);
	XCTAssertEqual([self collationResultBetween:@"A" and:@"a"], NSOrderedSame);
	// Punctuation is not skipped: the fold sends every letter into the lowercase
	// range (0x61-0x7A), which follows every ASCII punctuation byte, so the
	// punctuation-led key sorts before the word-led one -- the same place
	// SQLite's NOCASE puts it, and the place ICU's localized order does too.
	XCTAssertEqual([self collationResultBetween:@"[1997] Black Light Syndrome" and:@"Core"], NSOrderedAscending);
	// The fold is Unicode-aware (the simple one-to-one fold, MADStringOrderingTable).
	XCTAssertEqual([self collationResultBetween:@"K" and:@"k"], NSOrderedSame);
	XCTAssertEqual([self collationResultBetween:@"Ä" and:@"ä"], NSOrderedSame);
}

- (void)testTheCollationAgreesWithTheDefinedOrderComparator {
	// The cache's ORDER BY (this collation) and the in-memory sorts and the
	// formatter's group-boundary walk all compare through
	// -[NSString mad_orderedCompare:]; the collation must agree with it on
	// every pair, or group boundaries land in the wrong place.
	NSArray *keys = @[@"", @"a", @"A", @"B", @"b", @"Core", @"[1997] Black Light Syndrome",
					  @"Ä", @"ä", @"Zebra", @"ac/dc", @"AC/DC", @"Straße", @"strabe"];
	for (NSString *lhs in keys) {
		for (NSString *rhs in keys) {
			XCTAssertEqual([self collationResultBetween:lhs and:rhs], [lhs mad_orderedCompare:rhs],
						   @"the collation and -mad_orderedCompare: agree on '%@' vs '%@'", lhs, rhs);
		}
	}
}

- (void)testMadSqlite3Err {
	const char *errName = NULL;
	const char *errMsg = NULL;

	mad_sqlite3Err(SQLITE_OK, &errName, &errMsg);
	XCTAssertEqualObjects(@(errName), @"SQLITE_OK");
	XCTAssertEqualObjects(@(errMsg), @"not an error");

	mad_sqlite3Err(SQLITE_BUSY, &errName, &errMsg);
	XCTAssertEqualObjects(@(errName), @"SQLITE_BUSY");
	XCTAssertEqualObjects(@(errMsg), @"database is locked");

	mad_sqlite3Err(SQLITE_IOERR, &errName, &errMsg);
	XCTAssertEqualObjects(@(errName), @"SQLITE_IOERR");
	XCTAssertEqualObjects(@(errMsg), @"disk I/O error");
}

#pragma mark - MADDatabaseConnectionSqlite3

- (void)testConnectionInitWithUrl {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];

	XCTAssertEqualObjects(connection.databaseUrl, url);
	XCTAssertEqual(connection.databaseType, MADDatabaseTypeSqlite3);
	XCTAssertEqualObjects(connection.identifier, @"Sqlite 3");
	XCTAssertFalse(connection.requiresCredentials);
}

- (void)testConnectionCopy {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
	MADDatabaseConnectionSqlite3 *copy = [connection copy];

	XCTAssertNotEqual(connection, copy);
	XCTAssertEqualObjects(copy.databaseUrl, connection.databaseUrl);
	XCTAssertEqual(copy.databaseType, connection.databaseType);
	XCTAssertEqualObjects(copy.identifier, connection.identifier);
}

- (void)testConnectionString {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];

	NSString *expected = [[NSString alloc] initWithFormat:@"(%@)[%@]", @"Sqlite 3", url];
	XCTAssertEqualObjects(connection.connectionString, expected);
}

- (void)testConnectionCodingRoundTripCarriesTheUrl {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADDatabaseConnectionSqlite3 *decoded =
		[NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnectionSqlite3 class]
										  fromData:data
											 error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqualObjects(decoded.databaseUrl, url);
	XCTAssertEqual(decoded.databaseType, MADDatabaseTypeSqlite3);
	NSString *expected = [[NSString alloc] initWithFormat:@"(%@)[%@]", @"Sqlite 3", url];
	XCTAssertEqualObjects(decoded.connectionString, expected);
}

#pragma mark - MADQueryCache SQL builders

- (void)testBeginTransaction {
	MADQueryCacheBeginTransaction *query = [[MADQueryCacheBeginTransaction alloc] initWithObject:nil];
	XCTAssertEqualObjects([query getSql:nil], @"BEGIN TRANSACTION;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheBeginTransaction);
}

- (void)testEndTransaction {
	MADQueryCacheEndTransaction *query = [[MADQueryCacheEndTransaction alloc] initWithObject:nil];
	XCTAssertEqualObjects([query getSql:nil], @"END TRANSACTION;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheEndTransaction);
}

- (void)testSyncOff {
	MADQueryCacheSyncOff *query = [[MADQueryCacheSyncOff alloc] initWithObject:nil];
	XCTAssertEqualObjects([query getSql:nil], @"PRAGMA synchronous=OFF;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheSyncModeOff);
}

- (void)testSyncDefault {
	MADQueryCacheSyncDefault *query = [[MADQueryCacheSyncDefault alloc] initWithObject:nil];
	XCTAssertEqualObjects([query getSql:nil], @"PRAGMA synchronous=NORMAL;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheSyncModeDefault);
}

- (void)testJournalModeOverride {
	MADQueryCacheJournalModeOverride *query = [[MADQueryCacheJournalModeOverride alloc] initWithObject:nil];
	XCTAssertEqualObjects([query getSql:nil], @"PRAGMA journal_mode=WAL;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheJournalModeOverride);
}

- (void)testVacuum {
	MADQueryCacheVacuum *query = [[MADQueryCacheVacuum alloc] initWithObject:@{}];
	XCTAssertEqualObjects([query getSql:nil], @"VACUUM");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheVacuum);
}

- (void)testDropTable {
	MADQueryCacheDropTable *query = [[MADQueryCacheDropTable alloc] initWithObject:@"mytable"];
	XCTAssertEqualObjects([query getSql:nil], @"DROP TABLE IF EXISTS main.mytable");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheDropTable);
}

- (void)testDeleteAllFromTableByTableName {
	MADQueryCacheDeleteAllFromTable *query = [[MADQueryCacheDeleteAllFromTable alloc] initWithTableName:@"mytable"];
	XCTAssertEqualObjects([query getSql:nil], @"DELETE FROM mytable");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheDeleteAllFromTable);
}

- (void)testDeleteAllFromTableByObject {
	NSDictionary *object = @{@(MADQueryCacheDeleteAllFromTableTableName): @"mytable"};
	MADQueryCacheDeleteAllFromTable *query = [[MADQueryCacheDeleteAllFromTable alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"DELETE FROM mytable");
}

- (MADQueryCacheAddColumn *)addColumnQueryWithAffinity:(NSString *)affinity
										  createTable:(BOOL)createTable
										  isPrimaryKey:(BOOL)isPrimaryKey
									 uniqueColumnHack:(BOOL)uniqueColumnHack {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.primaryKey = isPrimaryKey;
	return [[MADQueryCacheAddColumn alloc] initWithTableName:@"t"
												  columnName:@"c"
													  column:column
												 createTable:createTable
											uniqueColumnHack:uniqueColumnHack
											  columnAffinity:affinity];
}

- (void)testAddColumnCreateTable {
	MADQueryCacheAddColumn *query = [self addColumnQueryWithAffinity:@"INTEGER" createTable:YES isPrimaryKey:NO uniqueColumnHack:NO];
	XCTAssertEqualObjects([query getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER );");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheAddColumn);
}

- (void)testAddColumnAlterTable {
	MADQueryCacheAddColumn *query = [self addColumnQueryWithAffinity:@"TEXT" createTable:NO isPrimaryKey:NO uniqueColumnHack:NO];
	XCTAssertEqualObjects([query getSql:nil], @"ALTER TABLE main.t ADD COLUMN c TEXT;");
}

- (void)testAddColumnUniqueAndPrimaryKey {
	MADQueryCacheAddColumn *unique = [self addColumnQueryWithAffinity:@"INTEGER" createTable:YES isPrimaryKey:NO uniqueColumnHack:YES];
	XCTAssertEqualObjects([unique getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER UNIQUE);");

	MADQueryCacheAddColumn *primary = [self addColumnQueryWithAffinity:@"INTEGER" createTable:YES isPrimaryKey:YES uniqueColumnHack:NO];
	XCTAssertEqualObjects([primary getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER PRIMARY KEY);");
}

- (void)testAddRow {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	MADDataColumn *age = [[MADDataColumn alloc] initWithIdentifier:@"age"];
	age.type = MADDataTypeInteger;

	MADQueryCacheAddRowTestDelegate *delegate = [[MADQueryCacheAddRowTestDelegate alloc] init];
	delegate.tableName = @"tbl";
	delegate.columnKeys = @[@"name", @"age"];
	delegate.columns = @{@"name": name, @"age": age};
	delegate.rowData = @[@"Alice", @30];

	MADQueryCacheAddRow *query = [[MADQueryCacheAddRow alloc] initWithObject:delegate];

	XCTAssertEqualObjects([query getSql:nil], @"INSERT INTO main.tbl (\"name\", \"age\") VALUES (?1, ?2)");
	XCTAssertFalse(query.returnsResults);
	XCTAssertTrue(query.partOfTransactionSet);
	XCTAssertEqual([query type], MADQueryTypeCacheAddRow);
	XCTAssertEqual(query.binaryBindings.count, (NSUInteger)2);

	MADDatabaseDataBinding *first = query.binaryBindings[0];
	XCTAssertEqual(first.datatype, MADDataTypeString);
	XCTAssertEqualObjects(first.value, @"Alice");

	MADDatabaseDataBinding *second = query.binaryBindings[1];
	XCTAssertEqual(second.datatype, MADDataTypeInteger);
	XCTAssertEqualObjects(second.value, @30);
}

- (void)testIndexCreate {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	NSDictionary *columns = @{@"name": name};

	MADQueryCacheIndexCreateParameters *parameters = [[MADQueryCacheIndexCreateParameters alloc] init];
	parameters.groupName = @"idx_foo";
	parameters.tableName = @"tbl";
	parameters.sortDescriptors = sortDescriptors;
	parameters.columns = columns;

	MADQueryCacheIndexCreate *query = [[MADQueryCacheIndexCreate alloc] initWithObject:parameters];
	XCTAssertEqualObjects([query getSql:nil], @"CREATE INDEX IF NOT EXISTS main.idx_foo ON tbl (name COLLATE LSASC ASC)");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheIndexCreateParameters);
}

- (void)testIndexDrop {
	NSDictionary *object = @{@(MADQueryCacheIndexDropIndexName): @"idx_foo"};
	MADQueryCacheIndexDrop *query = [[MADQueryCacheIndexDrop alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"DROP INDEX IF EXISTS main.idx_foo");
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheIndexDropParameters);
}

- (void)testSelectLimitOffsetBasic {
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a", @"b"]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:NO
					columns:nil];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT \"a\", \"b\", rowid FROM tbl");
	XCTAssertTrue(query.returnsResults);
	XCTAssertEqual([query type], MADQueryTypeCacheSelectLimitOffset);
}

- (void)testSelectLimitOffsetNoColumnKeysAndDropRowId {
	MADQueryCacheSelectLimitOffset *empty = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:NO
					columns:nil];
	XCTAssertEqualObjects([empty getSql:nil], @"SELECT  rowid FROM tbl");

	MADQueryCacheSelectLimitOffset *dropped = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a"]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:YES
					columns:nil];
	XCTAssertEqualObjects([dropped getSql:nil], @"SELECT \"a\" FROM tbl");
}

- (void)testSelectLimitOffsetLimitAndOrderBy {
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a"]
				  tableName:@"tbl"
			sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]]
					  limit:10
					 offset:5
				  dropRowID:NO
					columns:nil];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT \"a\", rowid FROM tbl ORDER BY name DESC LIMIT 10 OFFSET 5 ");
}

- (void)testSelectRowId {
	NSDictionary *object = @{
		@(MADQuerySelectFieldKeys): @[@"a", @"b"],
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectRowId): @5,
	};
	MADQueryCacheSelectRowId *query = [[MADQueryCacheSelectRowId alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT a, b FROM tbl WHERE rowid = 5");
	XCTAssertEqual([query type], MADQueryTypeCacheSelectRowId);
}

- (void)testSelectRowIdWildcard {
	NSDictionary *object = @{
		@(MADQuerySelectFieldKeys): @[],
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectRowId): @7,
	};
	MADQueryCacheSelectRowId *query = [[MADQueryCacheSelectRowId alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT * FROM tbl WHERE rowid = 7");
}

- (void)testSelectRowIds {
	MADQueryCacheSelectRowIds *query = [[MADQueryCacheSelectRowIds alloc]
		initWithRowIDs:@[@1, @2]
			  tableName:@"tbl"
		sortDescriptors:@[]
				columns:@{}];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT *, ROWID FROM tbl  WHERE rowid = 1 OR rowid = 2");
	XCTAssertEqual([query type], MADQueryTypeCacheSelectRowIds);
}

- (void)testSelectRowIdsEmpty {
	MADQueryCacheSelectRowIds *query = [[MADQueryCacheSelectRowIds alloc]
		initWithRowIDs:@[]
			  tableName:@"tbl"
		sortDescriptors:@[]
				columns:@{}];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT *, ROWID FROM tbl  WHERE rowid = -1 ");
}

- (void)testSelectItemsForGroup {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	name.nativeType = MADDataTypeString;

	NSDictionary *object = @{
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectFieldKeys): @[@"name"],
		@(MADQuerySelectFieldDescriptors): @{@"name": name},
		@(MADQuerySelectSortDescriptors): @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]],
		@(MADQuerySelectPredicates): @[],
	};
	MADQuerySelectItemsForGroup *query = [[MADQuerySelectItemsForGroup alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT \"name\", \"ROWID\" FROM tbl ORDER BY name COLLATE LSASC ASC");
	XCTAssertEqual([query type], MADQueryTypeCacheSelectItemsForGroupKeys);
}

- (void)testSelectItemsForGroupWithPredicate {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;
	name.nativeType = MADDataTypeString;

	NSDictionary *object = @{
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectFieldKeys): @[@"name"],
		@(MADQuerySelectFieldDescriptors): @{@"name": name},
		@(MADQuerySelectSortDescriptors): @[],
		@(MADQuerySelectPredicates): @[@{MADQueryKeyPredicateColumn: @"name", MADQueryKeyPredicateValue: @"Alice"}],
	};
	MADQuerySelectItemsForGroup *query = [[MADQuerySelectItemsForGroup alloc] initWithObject:object];
	XCTAssertEqualObjects([query getSql:nil], @"SELECT \"name\", \"ROWID\" FROM tbl WHERE name = ?");
	XCTAssertEqual(query.binaryBindings.count, (NSUInteger)1);
}

#pragma mark - MADQuery (Sqlite3) category

- (void)testOrderByClauseWithSortDescriptors {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;

	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{@"name": name};

	NSString *sql = [query orderByClauseWithSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	XCTAssertEqualObjects(sql, @" ORDER BY name COLLATE LSASC ASC");
}

- (void)testOrderByClauseWithNoSortDescriptors {
	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{};
	XCTAssertEqualObjects([query orderByClauseWithSortDescriptors:@[]], @"");
}

- (void)testWhereClauseWithRowIds {
	MADQuery *query = [[MADQuery alloc] init];
	NSArray *twoRowIds = @[@1, @2];
	NSArray *noRowIds = @[];
	XCTAssertEqualObjects([query whereClauseWithRowIds:twoRowIds], @" WHERE rowid = 1 OR rowid = 2");
	XCTAssertEqualObjects([query whereClauseWithRowIds:noRowIds], @" WHERE rowid = -1 ");
}

- (void)testWhereClauseWithParameters {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;

	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{@"name": name};
	query.binaryBindings = [[NSMutableArray alloc] init];

	NSArray *whereClause = @[@{MADQueryKeyPredicateColumn: @"name", MADQueryKeyPredicateValue: @"Alice"}];
	NSString *sql = [query whereClauseWithParameters:whereClause];

	XCTAssertEqualObjects(sql, @" WHERE name = ?");
	XCTAssertEqual(query.binaryBindings.count, (NSUInteger)1);

	MADDatabaseDataBinding *binding = query.binaryBindings.firstObject;
	XCTAssertEqual(binding.datatype, MADDataTypeString);
	XCTAssertEqualObjects(binding.value, @"Alice");
}

@end
