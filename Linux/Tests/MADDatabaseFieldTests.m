//
//  MADDatabaseFieldTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseFieldTests.m: the value type that
//  represents a column in a database table -- initialization defaults, the
//  numeric-type classifier, the sort-selector mapping, NSCopying and the
//  coding round trip (on the permissive path off Apple, as the probe
//  records).
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseField.h>

#pragma mark - Initialization

static void testInitWithNameDefaults(void) {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	MAD_PASS_EQUAL(field.name, @"amount", "the name is stored");
	MAD_PASS(field.calculatedWidth == (NSUInteger)0, "the calculated width starts at zero");
	MAD_PASS(field.fieldType == MADDataTypeUnknown, "the type starts unknown");
	MAD_PASS(field.width == (int64_t)0, "the width starts at zero");
	MAD_PASS(field.decimals == (int16_t)0, "the decimals start at zero");
	MAD_PASS(field.fieldTypeNative == (int16_t)0, "the native type starts at zero");
	MAD_PASS(!field.primaryKey, "the field is not a primary key");
}

#pragma mark - Numeric classification

static void testIsNumericTrueTypes(void) {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBit), @(MADDataTypeFloat), @(MADDataTypeInteger),
		@(MADDataTypeNumber), @(MADDataTypeDecimal), @(MADDataTypeDouble),
		@(MADDataTypeEnum), @(MADDataTypeInt24), @(MADDataTypeLong),
		@(MADDataTypeLongLong), @(MADDataTypeShort),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MAD_PASS([MADDatabaseField isNumeric:type], "the class classifier says numeric");

		MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"n"];
		field.fieldType = type;
		MAD_PASS([field isNumeric], "the instance classifier says numeric");
	}
}

static void testIsNumericFalseTypes(void) {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBlob), @(MADDataTypeDate), @(MADDataTypeDateTime),
		@(MADDataTypeGeometry), @(MADDataTypeImage), @(MADDataTypeSet),
		@(MADDataTypeString), @(MADDataTypeTime), @(MADDataTypeTimeStamp),
		@(MADDataTypeYear), @(MADDataTypeUnknown), @(MADDataTypeVarChar),
		@(MADDataTypeNull),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MAD_PASS(![MADDatabaseField isNumeric:type], "the class classifier says not numeric");
	}
}

#pragma mark - Sort selector mapping

static void testSelectorForSorting(void) {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"n"];

	field.fieldType = MADDataTypeString;
	MAD_PASS_EQUAL(NSStringFromSelector([field selectorForSorting]), @"localizedCaseInsensitiveCompare:",
				   "strings sort case-insensitively");

	field.fieldType = MADDataTypeBlob;
	MAD_PASS_EQUAL(NSStringFromSelector([field selectorForSorting]), @"compareData:", "blobs compare as data");

	field.fieldType = MADDataTypeInteger;
	MAD_PASS_EQUAL(NSStringFromSelector([field selectorForSorting]), @"compare:", "integers compare");

	// MADDataTypeDecimal falls through the switch's default branch.
	field.fieldType = MADDataTypeDecimal;
	MAD_PASS_EQUAL(NSStringFromSelector([field selectorForSorting]), @"compare:", "the default branch compares");
}

#pragma mark - NSCopying

static void testCopy(void) {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	field.calculatedWidth = 12;
	field.fieldType = MADDataTypeDecimal;
	field.width = 8;
	field.decimals = 2;
	field.fieldTypeNative = 3;
	field.primaryKey = YES;

	MADDatabaseField *copy = [field copy];
	MAD_PASS(copy != field, "the copy is a different object");
	MAD_PASS_EQUAL(copy.name, @"amount", "the name survives the copy");
	MAD_PASS(copy.calculatedWidth == (NSUInteger)12, "the calculated width survives");
	MAD_PASS(copy.fieldType == MADDataTypeDecimal, "the type survives");
	MAD_PASS(copy.width == (int64_t)8, "the width survives");
	MAD_PASS(copy.decimals == (int16_t)2, "the decimals survive");
	MAD_PASS(copy.fieldTypeNative == (int16_t)3, "the native type survives");
	MAD_PASS(copy.primaryKey, "the primary-key flag survives");
}

#pragma mark - NSSecureCoding

static void testSupportsSecureCoding(void) {
	MAD_PASS([MADDatabaseField supportsSecureCoding], "the class claims secure coding");
}

static void testNSCodingRoundTrip(void) {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	field.calculatedWidth = 12;
	field.fieldType = MADDataTypeDecimal;
	field.width = 8;
	field.decimals = 2;
	field.fieldTypeNative = 3;
	field.primaryKey = YES;

#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:field requiringSecureCoding:YES error:NULL];
	MADDatabaseField *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseField class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:field requiringSecureCoding:NO error:NULL];
	MADDatabaseField *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the field round trips");
	MAD_PASS_EQUAL(decoded.name, @"amount", "the name survives");
	MAD_PASS(decoded.calculatedWidth == (NSUInteger)12, "the calculated width survives");
	MAD_PASS(decoded.fieldType == MADDataTypeDecimal, "the type survives");
	MAD_PASS(decoded.width == (int64_t)8, "the width survives");
	MAD_PASS(decoded.decimals == (int16_t)2, "the decimals survive");
	MAD_PASS(decoded.fieldTypeNative == (int16_t)3, "the native type survives");
	MAD_PASS(decoded.primaryKey, "the primary-key flag survives");
}

#pragma mark - Description

static void testDescriptionContainsName(void) {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	MAD_PASS([[field description] containsString:@"amount"], "the description carries the name");
}

MAD_TEST_MAIN("MADDatabaseFieldTests",
	MAD_TEST(testInitWithNameDefaults),
	MAD_TEST(testIsNumericTrueTypes),
	MAD_TEST(testIsNumericFalseTypes),
	MAD_TEST(testSelectorForSorting),
	MAD_TEST(testCopy),
	MAD_TEST(testSupportsSecureCoding),
	MAD_TEST(testNSCodingRoundTrip),
	MAD_TEST(testDescriptionContainsName));
