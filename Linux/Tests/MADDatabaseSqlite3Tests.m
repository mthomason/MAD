//
//  MADDatabaseSqlite3Tests.m
//  Linux/Tests
//
//  Ported from MADSqlite3Tests/MADDatabaseSqlite3Tests.m: stateless (no live
//  database) coverage for the MADSqlite3 framework -- MADDatabaseSqlite3's
//  type/affinity mapping, safe identifiers, sort descriptions and native
//  types, the C helpers it exposes, MADDatabaseConnectionSqlite3, and every
//  MADQueryCache* SQL builder plus the MADQuery (Sqlite3) category.
//

#import "MADTestSupport.h"

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

#import <MADSqlite3/MADQueryCacheAddColumn.h>
#import <MADSqlite3/MADQueryCacheAddRow.h>
#import <MADSqlite3/MADQueryCacheIndexCreate.h>
#import <MADSqlite3/MADQueryCacheIndexDrop.h>
#import <MADSqlite3/MADQueryCacheSelectLimitOffset.h>
#import <MADSqlite3/MADQueryCacheVacuum.h>
#import <MADSqlite3/MADQuerySelectItemsForGroup.h>
#import <MADSqlite3/MADQueryCacheAddColumnParameters.h>
#import <MADSqlite3/MADQueryCacheDeleteAllFromTableParameters.h>
#import <MADSqlite3/MADQueryCacheIndexCreateParameters.h>
#import <MADSqlite3/MADQueryCacheIndexDropParameters.h>
#import <MADSqlite3/MADQueryParameters.h>
#import <MADSqlite3/sqlite3.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
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

#pragma mark - Type / affinity mapping

static void testDataTypeForNativeTypeMapsIntegerAffinities(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"INT"] == MADDataTypeInteger, "INT maps to Integer");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"INTEGER"] == MADDataTypeInteger, "INTEGER maps to Integer");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"BIGINT"] == MADDataTypeInteger, "BIGINT maps to Integer");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"TINYINT"] == MADDataTypeInteger, "TINYINT maps to Integer");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"SMALLINT"] == MADDataTypeInteger, "SMALLINT maps to Integer");
}

static void testDataTypeForNativeTypeMapsTextAffinities(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"CHAR"] == MADDataTypeString, "CHAR maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"TEXT"] == MADDataTypeString, "TEXT maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"CLOB"] == MADDataTypeString, "CLOB maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"VARCHAR(255)"] == MADDataTypeString, "VARCHAR maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"NCHAR"] == MADDataTypeString, "NCHAR maps to String");
}

static void testDataTypeForNativeTypeMapsBlobAndEmpty(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"BLOB"] == MADDataTypeBlob, "BLOB maps to Blob");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@""] == MADDataTypeBlob, "an empty native type maps to Blob");
	// nil maps to MADDataTypeInteger (not Blob): [nil rangeOfString:] returns a zeroed
	// NSRange whose location (0) != NSNotFound, so isInteger is treated as YES.
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:nil] == MADDataTypeInteger, "nil maps to Integer");
}

static void testDataTypeForNativeTypeMapsRealAndNumericAffinities(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"REAL"] == MADDataTypeDouble, "REAL maps to Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"FLOAT"] == MADDataTypeDouble, "FLOAT maps to Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"DOUBLE"] == MADDataTypeDouble, "DOUBLE maps to Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"DOUBLE PRECISION"] == MADDataTypeDouble, "DOUBLE PRECISION maps to Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"NUMERIC"] == MADDataTypeNumber, "NUMERIC maps to Number");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"DECIMAL(10,5)"] == MADDataTypeNumber, "DECIMAL maps to Number");
}

static void testDataTypeForNativeTypeDefaultsToNumber(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"BOOLEAN"] == MADDataTypeNumber, "BOOLEAN defaults to Number");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeType:@"SOMETHING"] == MADDataTypeNumber, "an unknown type defaults to Number");
}

static void testDataTypeForAffentyType(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_INTEGER] == MADDataTypeInteger, "SQLITE_INTEGER maps to Integer");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_FLOAT] == MADDataTypeDouble, "SQLITE_FLOAT maps to Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_BLOB] == MADDataTypeBlob, "SQLITE_BLOB maps to Blob");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE_NULL] == MADDataTypeString, "SQLITE_NULL maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:SQLITE3_TEXT] == MADDataTypeString, "SQLITE3_TEXT maps to String");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForAffentyType:999] == MADDataTypeString, "an unknown affinity maps to String");
}

static void testDataTypeForNativeTypeNumericIntegerFamily(void) {
	MADDataType integerTypes[] = {
		MADDataTypeBit, MADDataTypeInteger, MADDataTypeShort, MADDataTypeLong,
		MADDataTypeLongLong, MADDataTypeInt24, MADDataTypeEnum
	};
	for (NSUInteger i = 0; i < sizeof(integerTypes) / sizeof(integerTypes[0]); i++) {
		MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:integerTypes[i]] == MADDataTypeInteger,
				 "the integer family limits to Integer");
	}
}

static void testDataTypeForNativeTypeNumericStringFamily(void) {
	MADDataType stringTypes[] = {
		MADDataTypeSet, MADDataTypeTime, MADDataTypeTimeStamp, MADDataTypeYear,
		MADDataTypeDate, MADDataTypeDateTime, MADDataTypeString, MADDataTypeVarChar,
		MADDataTypeGeometry
	};
	for (NSUInteger i = 0; i < sizeof(stringTypes) / sizeof(stringTypes[0]); i++) {
		MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:stringTypes[i]] == MADDataTypeString,
				 "the string family limits to String");
	}
}

static void testDataTypeForNativeTypeNumericBlobFloatAndDecimal(void) {
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeImage] == MADDataTypeBlob, "Image limits to Blob");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeBlob] == MADDataTypeBlob, "Blob stays Blob");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeFloat] == MADDataTypeFloat, "Float stays Float");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeDouble] == MADDataTypeDouble, "Double stays Double");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeDecimal] == MADDataTypeDecimal, "Decimal stays Decimal");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeNumber] == MADDataTypeDecimal, "Number limits to Decimal");
	MAD_PASS([MADDatabaseSqlite3 dataTypeForNativeTypeNumeric:MADDataTypeUnknown] == MADDataTypeString, "Unknown limits to String");
}

static void testSqlite3NativeType(void) {
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeInteger], @"INTEGER", "Integer stores as INTEGER");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeLong], @"INTEGER", "Long stores as INTEGER");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeShort], @"INTEGER", "Short stores as INTEGER");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeBit], @"INTEGER", "Bit stores as INTEGER");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeEnum], @"INTEGER", "Enum stores as INTEGER");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeString], @"TEXT", "String stores as TEXT");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeVarChar], @"TEXT", "VarChar stores as TEXT");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDate], @"TEXT", "Date stores as TEXT");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeGeometry], @"TEXT", "Geometry stores as TEXT");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeImage], @"NONE", "Image stores as NONE");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeBlob], @"NONE", "Blob stores as NONE");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeFloat], @"REAL", "Float stores as REAL");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDouble], @"REAL", "Double stores as REAL");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeDecimal], @"NUMERIC", "Decimal stores as NUMERIC");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeNumber], @"NUMERIC", "Number stores as NUMERIC");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sqlite3NativeType:MADDataTypeUnknown], @"TEXT", "Unknown stores as TEXT");
}

static void testSortDescriptionForColumnType(void) {
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeString ascending:YES], @"COLLATE LSASC ASC", "text ascending collates locally");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeString ascending:NO], @"COLLATE LSASC DESC", "text descending collates locally");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeVarChar ascending:YES], @"COLLATE LSASC ASC", "var char ascending collates locally");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeInteger ascending:YES], @"ASC", "an integer ascends plainly");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeInteger ascending:NO], @"DESC", "an integer descends plainly");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 sortDescriptionForColumnType:MADDataTypeDouble ascending:YES], @"ASC", "a double ascends plainly");
}

#pragma mark - Safe identifiers

static void testSafeQueryFieldAndIdentifier(void) {
	MAD_PASS_EQUAL([MADDatabaseSqlite3 newSafeQueryField:@"field" andTable:@"table"], @"\"table\".\"field\"", "the class safe query field is quoted table-dot-field");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 newSafeIdentifier:@"identifier"], @"\"identifier\"", "the class safe identifier is quoted");

	MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
	MAD_PASS_EQUAL([database newSafeIdentifier:@"identifier"], @"\"identifier\"", "the instance safe identifier is quoted");
	MAD_PASS_EQUAL([database queryKey:@"field" table:@"table"], @"\"table\".\"field\"", "the instance query key is quoted table-dot-field");
}

static void testDriverAndIconNames(void) {
	MAD_PASS_EQUAL([MADDatabaseSqlite3 driverName], @"Sqlite 3", "the driver name");
	MAD_PASS_EQUAL([MADDatabaseSqlite3 imageIconName], @"MADImageSqlite3", "the icon name");
}

#pragma mark - C helpers

static void testSqlite3StepResultOK(void) {
	MAD_PASS(Sqlite3StepResultOK(SQLITE_OK), "SQLITE_OK is a step result");
	MAD_PASS(Sqlite3StepResultOK(SQLITE_ROW), "SQLITE_ROW is a step result");
	MAD_PASS(Sqlite3StepResultOK(SQLITE_DONE), "SQLITE_DONE is a step result");
	MAD_PASS(!Sqlite3StepResultOK(SQLITE_ERROR), "SQLITE_ERROR is not a step result");
	MAD_PASS(!Sqlite3StepResultOK(SQLITE_BUSY), "SQLITE_BUSY is not a step result");
	MAD_PASS(!Sqlite3StepResultOK(-1), "-1 is not a step result");
}

static NSComparisonResult collationResultBetween(NSString *lhs, NSString *rhs) {
	const char *l = lhs.UTF8String;
	const char *r = rhs.UTF8String;
	int result = compare_string_utf8_localized_asc_collation(NULL,
															 (int)[lhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], l,
															 (int)[rhs lengthOfBytesUsingEncoding:NSUTF8StringEncoding], r);
	return (NSComparisonResult)result;
}

static void testCompareStringUtf8LocalizedAscCollation(void) {
	MAD_PASS(collationResultBetween(@"a", @"b") == NSOrderedAscending, "a sorts before b");
	MAD_PASS(collationResultBetween(@"b", @"a") == NSOrderedDescending, "b sorts after a");
	MAD_PASS(collationResultBetween(@"a", @"a") == NSOrderedSame, "a equals a");
	MAD_PASS(collationResultBetween(@"A", @"b") == NSOrderedAscending, "A sorts before b case-insensitively");
	// The comparison is meant to be localized and case-insensitive; GNUstep's
	// -localizedCaseInsensitiveCompare: is not (measured 2026-10-06: "a" vs
	// "B" answers Descending, code-point order), so the collation this
	// registers orders differently on Linux.  Recorded in Linux/README.md.
#if __APPLE__
	MAD_PASS(collationResultBetween(@"a", @"B") == NSOrderedAscending, "a sorts before B case-insensitively");
#else
	MAD_PASS(collationResultBetween(@"a", @"B") == NSOrderedDescending, "GNUstep's comparison is case-sensitive here");
#endif
}

static void testMadSqlite3Err(void) {
	const char *errName = NULL;
	const char *errMsg = NULL;

	mad_sqlite3Err(SQLITE_OK, &errName, &errMsg);
	MAD_PASS_EQUAL(@(errName), @"SQLITE_OK", "SQLITE_OK names itself");
	MAD_PASS_EQUAL(@(errMsg), @"not an error", "SQLITE_OK carries its message");

	mad_sqlite3Err(SQLITE_BUSY, &errName, &errMsg);
	MAD_PASS_EQUAL(@(errName), @"SQLITE_BUSY", "SQLITE_BUSY names itself");
	MAD_PASS_EQUAL(@(errMsg), @"database is locked", "SQLITE_BUSY carries its message");

	mad_sqlite3Err(SQLITE_IOERR, &errName, &errMsg);
	MAD_PASS_EQUAL(@(errName), @"SQLITE_IOERR", "SQLITE_IOERR names itself");
	MAD_PASS_EQUAL(@(errMsg), @"disk I/O error", "SQLITE_IOERR carries its message");
}

#pragma mark - MADDatabaseConnectionSqlite3

static void testConnectionInitWithUrl(void) {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];

	MAD_PASS_EQUAL(connection.databaseUrl, url, "the URL is stored");
	MAD_PASS(connection.databaseType == MADDatabaseTypeSqlite3, "the database type is sqlite3");
	MAD_PASS_EQUAL(connection.identifier, @"Sqlite 3", "the identifier is the driver name");
	MAD_PASS(!connection.requiresCredentials, "sqlite3 needs no credentials");
}

static void testConnectionCopy(void) {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
	MADDatabaseConnectionSqlite3 *copy = [connection copy];

	MAD_PASS(connection != copy, "the copy is a different object");
	MAD_PASS_EQUAL(copy.databaseUrl, connection.databaseUrl, "the copy carries the URL");
	MAD_PASS(copy.databaseType == connection.databaseType, "the copy carries the type");
	MAD_PASS_EQUAL(copy.identifier, connection.identifier, "the copy carries the identifier");
}

static void testConnectionString(void) {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/example.sqlite"];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];

	NSString *expected = [[NSString alloc] initWithFormat:@"(%@)[%@]", @"Sqlite 3", url];
	MAD_PASS_EQUAL(connection.connectionString, expected, "the connection string names the driver and URL");
}

#pragma mark - MADQueryCache SQL builders

static void testBeginTransaction(void) {
	MADQueryCacheBeginTransaction *query = [[MADQueryCacheBeginTransaction alloc] initWithObject:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"BEGIN TRANSACTION;", "the begin-transaction SQL");
	MAD_PASS(!query.returnsResults, "the transaction begin returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheBeginTransaction, "the type is begin-transaction");
}

static void testEndTransaction(void) {
	MADQueryCacheEndTransaction *query = [[MADQueryCacheEndTransaction alloc] initWithObject:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"END TRANSACTION;", "the end-transaction SQL");
	MAD_PASS(!query.returnsResults, "the transaction end returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheEndTransaction, "the type is end-transaction");
}

static void testSyncOff(void) {
	MADQueryCacheSyncOff *query = [[MADQueryCacheSyncOff alloc] initWithObject:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"PRAGMA synchronous=OFF;", "the synchronous-off pragma");
	MAD_PASS(!query.returnsResults, "the pragma returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheSyncModeOff, "the type is sync-mode off");
}

static void testSyncDefault(void) {
	MADQueryCacheSyncDefault *query = [[MADQueryCacheSyncDefault alloc] initWithObject:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"PRAGMA synchronous=NORMAL;", "the synchronous-normal pragma");
	MAD_PASS(!query.returnsResults, "the pragma returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheSyncModeDefault, "the type is sync-mode default");
}

static void testJournalModeOverride(void) {
	MADQueryCacheJournalModeOverride *query = [[MADQueryCacheJournalModeOverride alloc] initWithObject:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"PRAGMA journal_mode=WAL;", "the WAL journal pragma");
	MAD_PASS(!query.returnsResults, "the pragma returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheJournalModeOverride, "the type is journal-mode override");
}

static void testVacuum(void) {
	MADQueryCacheVacuum *query = [[MADQueryCacheVacuum alloc] initWithObject:@{}];
	MAD_PASS_EQUAL([query getSql:nil], @"VACUUM", "the vacuum SQL");
	MAD_PASS(!query.returnsResults, "the vacuum returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheVacuum, "the type is vacuum");
}

static void testDropTable(void) {
	MADQueryCacheDropTable *query = [[MADQueryCacheDropTable alloc] initWithObject:@"mytable"];
	MAD_PASS_EQUAL([query getSql:nil], @"DROP TABLE IF EXISTS main.mytable", "the drop-table SQL");
	MAD_PASS(!query.returnsResults, "the drop returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheDropTable, "the type is drop-table");
}

static void testDeleteAllFromTableByTableName(void) {
	MADQueryCacheDeleteAllFromTable *query = [[MADQueryCacheDeleteAllFromTable alloc] initWithTableName:@"mytable"];
	MAD_PASS_EQUAL([query getSql:nil], @"DELETE FROM mytable", "the delete-all SQL by table name");
	MAD_PASS(!query.returnsResults, "the delete returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheDeleteAllFromTable, "the type is delete-all-from-table");
}

static void testDeleteAllFromTableByObject(void) {
	NSDictionary *object = @{@(MADQueryCacheDeleteAllFromTableTableName): @"mytable"};
	MADQueryCacheDeleteAllFromTable *query = [[MADQueryCacheDeleteAllFromTable alloc] initWithObject:object];
	MAD_PASS_EQUAL([query getSql:nil], @"DELETE FROM mytable", "the delete-all SQL by object");
}

static MADQueryCacheAddColumn *addColumnQueryWithAffinity(NSString *affinity,
														  BOOL createTable,
														  BOOL isPrimaryKey,
														  BOOL uniqueColumnHack) {
	MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:@"c"];
	column.primaryKey = isPrimaryKey;
	return [[MADQueryCacheAddColumn alloc] initWithTableName:@"t"
												  columnName:@"c"
													  column:column
												 createTable:createTable
											uniqueColumnHack:uniqueColumnHack
											  columnAffinity:affinity];
}

static void testAddColumnCreateTable(void) {
	MADQueryCacheAddColumn *query = addColumnQueryWithAffinity(@"INTEGER", YES, NO, NO);
	MAD_PASS_EQUAL([query getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER );", "the create-table SQL");
	MAD_PASS(!query.returnsResults, "the add-column returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheAddColumn, "the type is add-column");
}

static void testAddColumnAlterTable(void) {
	MADQueryCacheAddColumn *query = addColumnQueryWithAffinity(@"TEXT", NO, NO, NO);
	MAD_PASS_EQUAL([query getSql:nil], @"ALTER TABLE main.t ADD COLUMN c TEXT;", "the alter-table SQL");
}

static void testAddColumnUniqueAndPrimaryKey(void) {
	MADQueryCacheAddColumn *unique = addColumnQueryWithAffinity(@"INTEGER", YES, NO, YES);
	MAD_PASS_EQUAL([unique getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER UNIQUE);", "the unique column SQL");

	MADQueryCacheAddColumn *primary = addColumnQueryWithAffinity(@"INTEGER", YES, YES, NO);
	MAD_PASS_EQUAL([primary getSql:nil], @"CREATE TABLE IF NOT EXISTS main.t (c INTEGER PRIMARY KEY);", "the primary-key column SQL");
}

static void testAddRow(void) {
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

	MAD_PASS_EQUAL([query getSql:nil], @"INSERT INTO main.tbl (\"name\", \"age\") VALUES (?1, ?2)", "the insert SQL");
	MAD_PASS(!query.returnsResults, "the insert returns no rows");
	MAD_PASS(query.partOfTransactionSet, "the insert is part of the transaction set");
	MAD_PASS([query type] == MADQueryTypeCacheAddRow, "the type is add-row");
	MAD_PASS(query.binaryBindings.count == (NSUInteger)2, "the row has two bindings");

	MADDatabaseDataBinding *first = query.binaryBindings[0];
	MAD_PASS(first.datatype == MADDataTypeString, "the first binding is a string");
	MAD_PASS_EQUAL(first.value, @"Alice", "the first binding carries the name");

	MADDatabaseDataBinding *second = query.binaryBindings[1];
	MAD_PASS(second.datatype == MADDataTypeInteger, "the second binding is an integer");
	MAD_PASS_EQUAL(second.value, @30, "the second binding carries the age");
}

static void testIndexCreate(void) {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.nativeType = MADDataTypeString;

	NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	NSDictionary *columns = @{@"name": name};

	MADQueryCacheIndexCreateParameters *parameters = [[MADQueryCacheIndexCreateParameters alloc] init];
	parameters.groupName = @"idx_foo";
	parameters.tableName = @"tbl";
	parameters.sortDescriptors = sortDescriptors;
	parameters.columns = columns;

	MADQueryCacheIndexCreate *query = [[MADQueryCacheIndexCreate alloc] initWithObject:parameters];
	MAD_PASS_EQUAL([query getSql:nil], @"CREATE INDEX IF NOT EXISTS main.idx_foo ON tbl (name COLLATE LSASC ASC)", "the create-index SQL");
	MAD_PASS(!query.returnsResults, "the index create returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheIndexCreateParameters, "the type is index-create parameters");
}

static void testIndexDrop(void) {
	NSDictionary *object = @{@(MADQueryCacheIndexDropIndexName): @"idx_foo"};
	MADQueryCacheIndexDrop *query = [[MADQueryCacheIndexDrop alloc] initWithObject:object];
	MAD_PASS_EQUAL([query getSql:nil], @"DROP INDEX IF EXISTS main.idx_foo", "the drop-index SQL");
	MAD_PASS(!query.returnsResults, "the index drop returns no rows");
	MAD_PASS([query type] == MADQueryTypeCacheIndexDropParameters, "the type is index-drop parameters");
}

static void testSelectLimitOffsetBasic(void) {
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a", @"b"]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:NO
					columns:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT \"a\", \"b\", rowid FROM tbl", "the basic select SQL");
	MAD_PASS(query.returnsResults, "the select returns rows");
	MAD_PASS([query type] == MADQueryTypeCacheSelectLimitOffset, "the type is select-limit-offset");
}

static void testSelectLimitOffsetNoColumnKeysAndDropRowId(void) {
	MADQueryCacheSelectLimitOffset *empty = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:NO
					columns:nil];
	MAD_PASS_EQUAL([empty getSql:nil], @"SELECT  rowid FROM tbl", "no column keys still selects rowid");

	MADQueryCacheSelectLimitOffset *dropped = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a"]
				  tableName:@"tbl"
			sortDescriptors:@[]
					  limit:NSNotFound
					 offset:NSNotFound
				  dropRowID:YES
					columns:nil];
	MAD_PASS_EQUAL([dropped getSql:nil], @"SELECT \"a\" FROM tbl", "dropping the row id omits it");
}

static void testSelectLimitOffsetLimitAndOrderBy(void) {
	MADQueryCacheSelectLimitOffset *query = [[MADQueryCacheSelectLimitOffset alloc]
		initWithColumnKeys:@[@"a"]
				  tableName:@"tbl"
			sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]]
					  limit:10
					 offset:5
				  dropRowID:NO
					columns:nil];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT \"a\", rowid FROM tbl ORDER BY name DESC LIMIT 10 OFFSET 5 ", "the ordered and limited select SQL");
}

static void testSelectRowId(void) {
	NSDictionary *object = @{
		@(MADQuerySelectFieldKeys): @[@"a", @"b"],
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectRowId): @5,
	};
	MADQueryCacheSelectRowId *query = [[MADQueryCacheSelectRowId alloc] initWithObject:object];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT a, b FROM tbl WHERE rowid = 5", "the select-by-rowid SQL");
	MAD_PASS([query type] == MADQueryTypeCacheSelectRowId, "the type is select-rowid");
}

static void testSelectRowIdWildcard(void) {
	NSDictionary *object = @{
		@(MADQuerySelectFieldKeys): @[],
		@(MADQuerySelectTableName): @"tbl",
		@(MADQuerySelectRowId): @7,
	};
	MADQueryCacheSelectRowId *query = [[MADQueryCacheSelectRowId alloc] initWithObject:object];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT * FROM tbl WHERE rowid = 7", "an empty key list selects the wildcard");
}

static void testSelectRowIds(void) {
	MADQueryCacheSelectRowIds *query = [[MADQueryCacheSelectRowIds alloc]
		initWithRowIDs:@[@1, @2]
			  tableName:@"tbl"
		sortDescriptors:@[]
				columns:@{}];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT *, ROWID FROM tbl  WHERE rowid = 1 OR rowid = 2", "the select-by-rowids SQL");
	MAD_PASS([query type] == MADQueryTypeCacheSelectRowIds, "the type is select-rowids");
}

static void testSelectRowIdsEmpty(void) {
	MADQueryCacheSelectRowIds *query = [[MADQueryCacheSelectRowIds alloc]
		initWithRowIDs:@[]
			  tableName:@"tbl"
		sortDescriptors:@[]
				columns:@{}];
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT *, ROWID FROM tbl  WHERE rowid = -1 ", "an empty rowid list matches nothing");
}

static void testSelectItemsForGroup(void) {
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
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT \"name\", \"ROWID\" FROM tbl ORDER BY name COLLATE LSASC ASC", "the group-items SQL");
	MAD_PASS([query type] == MADQueryTypeCacheSelectItemsForGroupKeys, "the type is select-items-for-group");
}

static void testSelectItemsForGroupWithPredicate(void) {
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
	MAD_PASS_EQUAL([query getSql:nil], @"SELECT \"name\", \"ROWID\" FROM tbl WHERE name = ?", "the group-items SQL with a predicate");
	MAD_PASS(query.binaryBindings.count == (NSUInteger)1, "the predicate binds one value");
}

#pragma mark - MADQuery (Sqlite3) category

static void testOrderByClauseWithSortDescriptors(void) {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.nativeType = MADDataTypeString;

	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{@"name": name};

	NSString *sql = [query orderByClauseWithSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	MAD_PASS_EQUAL(sql, @" ORDER BY name COLLATE LSASC ASC", "the order-by clause collates the text column");
}

static void testOrderByClauseWithNoSortDescriptors(void) {
	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{};
	MAD_PASS_EQUAL([query orderByClauseWithSortDescriptors:@[]], @"", "no sort descriptors means no clause");
}

static void testWhereClauseWithRowIds(void) {
	MADQuery *query = [[MADQuery alloc] init];
	NSArray *twoRowIds = @[@1, @2];
	NSArray *noRowIds = @[];
	MAD_PASS_EQUAL([query whereClauseWithRowIds:twoRowIds], @" WHERE rowid = 1 OR rowid = 2", "the rowid where clause");
	MAD_PASS_EQUAL([query whereClauseWithRowIds:noRowIds], @" WHERE rowid = -1 ", "an empty rowid list matches nothing");
}

static void testWhereClauseWithParameters(void) {
	MADDataColumn *name = [[MADDataColumn alloc] initWithIdentifier:@"name"];
	name.type = MADDataTypeString;

	MADQuerySqlite3ColumnDouble *query = [[MADQuerySqlite3ColumnDouble alloc] init];
	query.columns = @{@"name": name};
	query.binaryBindings = [[NSMutableArray alloc] init];

	NSArray *whereClause = @[@{MADQueryKeyPredicateColumn: @"name", MADQueryKeyPredicateValue: @"Alice"}];
	NSString *sql = [query whereClauseWithParameters:whereClause];

	MAD_PASS_EQUAL(sql, @" WHERE name = ?", "the parameter where clause");
	MAD_PASS(query.binaryBindings.count == (NSUInteger)1, "the parameter where clause binds one value");

	MADDatabaseDataBinding *binding = query.binaryBindings.firstObject;
	MAD_PASS(binding.datatype == MADDataTypeString, "the binding is a string");
	MAD_PASS_EQUAL(binding.value, @"Alice", "the binding carries the value");
}

MAD_TEST_MAIN("MADDatabaseSqlite3Tests",
	MAD_TEST(testDataTypeForNativeTypeMapsIntegerAffinities),
	MAD_TEST(testDataTypeForNativeTypeMapsTextAffinities),
	MAD_TEST(testDataTypeForNativeTypeMapsBlobAndEmpty),
	MAD_TEST(testDataTypeForNativeTypeMapsRealAndNumericAffinities),
	MAD_TEST(testDataTypeForNativeTypeDefaultsToNumber),
	MAD_TEST(testDataTypeForAffentyType),
	MAD_TEST(testDataTypeForNativeTypeNumericIntegerFamily),
	MAD_TEST(testDataTypeForNativeTypeNumericStringFamily),
	MAD_TEST(testDataTypeForNativeTypeNumericBlobFloatAndDecimal),
	MAD_TEST(testSqlite3NativeType),
	MAD_TEST(testSortDescriptionForColumnType),
	MAD_TEST(testSafeQueryFieldAndIdentifier),
	MAD_TEST(testDriverAndIconNames),
	MAD_TEST(testSqlite3StepResultOK),
	MAD_TEST(testCompareStringUtf8LocalizedAscCollation),
	MAD_TEST(testMadSqlite3Err),
	MAD_TEST(testConnectionInitWithUrl),
	MAD_TEST(testConnectionCopy),
	MAD_TEST(testConnectionString),
	MAD_TEST(testBeginTransaction),
	MAD_TEST(testEndTransaction),
	MAD_TEST(testSyncOff),
	MAD_TEST(testSyncDefault),
	MAD_TEST(testJournalModeOverride),
	MAD_TEST(testVacuum),
	MAD_TEST(testDropTable),
	MAD_TEST(testDeleteAllFromTableByTableName),
	MAD_TEST(testDeleteAllFromTableByObject),
	MAD_TEST(testAddColumnCreateTable),
	MAD_TEST(testAddColumnAlterTable),
	MAD_TEST(testAddColumnUniqueAndPrimaryKey),
	MAD_TEST(testAddRow),
	MAD_TEST(testIndexCreate),
	MAD_TEST(testIndexDrop),
	MAD_TEST(testSelectLimitOffsetBasic),
	MAD_TEST(testSelectLimitOffsetNoColumnKeysAndDropRowId),
	MAD_TEST(testSelectLimitOffsetLimitAndOrderBy),
	MAD_TEST(testSelectRowId),
	MAD_TEST(testSelectRowIdWildcard),
	MAD_TEST(testSelectRowIds),
	MAD_TEST(testSelectRowIdsEmpty),
	MAD_TEST(testSelectItemsForGroup),
	MAD_TEST(testSelectItemsForGroupWithPredicate),
	MAD_TEST(testOrderByClauseWithSortDescriptors),
	MAD_TEST(testOrderByClauseWithNoSortDescriptors),
	MAD_TEST(testWhereClauseWithRowIds),
	MAD_TEST(testWhereClauseWithParameters));
