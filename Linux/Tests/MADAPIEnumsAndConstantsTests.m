//
//  MADAPIEnumsAndConstantsTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADAPIEnumsAndConstantsTests.m: the framework's
//  public enums (MADDatabaseType, MADQueryType) and its exported string
//  constants, all compile-time definitions with no runtime dependencies.
//

#import "MADTestSupport.h"
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADQuery.h>

#pragma mark - MADDatabaseType

static void testDatabaseTypeRawValues(void) {
	MAD_PASS((int)MADDatabaseTypeNotSet == (int)-1, "NotSet is -1");
	MAD_PASS((int)MADDatabaseTypeUnknown == (int)0, "Unknown is 0");
	MAD_PASS((int)MADDatabaseTypeDatabaseCom == (int)1, "DatabaseCom is 1");
	MAD_PASS((int)MADDatabaseTypeMySQL == (int)2, "MySQL is 2");
	MAD_PASS((int)MADDatabaseTypeMicrosoftSqlAzure == (int)3, "MicrosoftSqlAzure is 3");
	MAD_PASS((int)MADDatabaseTypeAmazonSimpleDb == (int)4, "AmazonSimpleDb is 4");
	MAD_PASS((int)MADDatabaseTypeTDS == (int)5, "TDS is 5");
	MAD_PASS((int)MADDatabaseTypeOracle == (int)6, "Oracle is 6");
	MAD_PASS((int)MADDatabaseTypeODBC == (int)7, "ODBC is 7");
	MAD_PASS((int)MADDatabaseTypeGooleAppEngine == (int)8, "GooleAppEngine is 8");
	MAD_PASS((int)MADDatabaseTypeNone == (int)9, "None is 9");
	MAD_PASS((int)MADDatabaseTypeSqlite3 == (int)10, "Sqlite3 is 10");
	MAD_PASS((int)MADDatabaseTypeSample1 == (int)11, "Sample1 is 11");
}

#pragma mark - MADQueryType string mapping

static void testNSStringFromMADQueryType(void) {
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeUnknown), @"MADQueryTypeUnknown", "Unknown");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeMaxFieldLength), @"MADQueryTypeMaxFieldLength", "MaxFieldLength");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCustomSql), @"MADQueryTypeCustomSql", "CustomSql");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeFull), @"MADQueryTypeFull", "Full");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeConnectionTest), @"MADQueryTypeConnectionTest", "ConnectionTest");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeSampleDataField), @"MADQueryTypeSampleDataField", "SampleDataField");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeSampleDataTable), @"MADQueryTypeSampleDataTable", "SampleDataTable");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheAddColumn), @"MADQueryTypeCacheAddColumn", "CacheAddColumn");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheVacuum), @"MADQueryTypeCacheVacuum", "CacheVacuum");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheSelectRowIds), @"MADQueryTypeCacheSelectRowIds", "CacheSelectRowIds");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheAggregateFunction), @"MADQueryTypeCacheAggregateFunction", "CacheAggregateFunction");
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheIndexCreateTemplate), @"MADQueryTypeCacheIndexCreateTemplate", "CacheIndexCreateTemplate");
}

static void testNSStringFromMADQueryTypeCacheIndexDropParameters(void) {
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeCacheIndexDropParameters), @"MADQueryTypeCacheIndexDropParameters", "CacheIndexDropParameters");
}

static void testNSStringFromMADQueryTypeSampleDataTableRange(void) {
	MAD_PASS_EQUAL(NSStringFromMADQueryType(MADQueryTypeSampleDataTableRange), @"MADQueryTypeSampleDataTableRange", "SampleDataTableRange");
}

static void testNSStringFromMADQueryTypeUnhandledValueFallsThrough(void) {
	MAD_PASS_EQUAL(NSStringFromMADQueryType((MADQueryType)2), @"MADQueryTypeUnknown", "an unhandled value resolves to Unknown");
}

#pragma mark - MADQuery constants

static void testMADQueryKeyConstants(void) {
	MAD_PASS_EQUAL(MADQueryKeyPredicateColumn, @"c", "the predicate column key");
	MAD_PASS_EQUAL(MADQueryKeyPredicateValue, @"v", "the predicate value key");
	MAD_PASS_EQUAL(MADIdentifierROWID, @"ROWID", "the row identifier");
}

MAD_TEST_MAIN("MADAPIEnumsAndConstantsTests",
	MAD_TEST(testDatabaseTypeRawValues),
	MAD_TEST(testNSStringFromMADQueryType),
	MAD_TEST(testNSStringFromMADQueryTypeCacheIndexDropParameters),
	MAD_TEST(testNSStringFromMADQueryTypeSampleDataTableRange),
	MAD_TEST(testNSStringFromMADQueryTypeUnhandledValueFallsThrough),
	MAD_TEST(testMADQueryKeyConstants));
