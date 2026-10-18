//
//  MADDatabaseDataBindingTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseDataBindingTests.m: the value type that
//  binds a typed value to a query-result field index -- the DataTypeLimited()
//  mapping, the nil/NSNull/unknown-type coercions, the 1-based column number,
//  NSCopying and the coding round trip.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#pragma mark - Default init

static void testInitDefaults(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] init];
	MAD_PASS(binding.value == nil, "the value starts nil");
	MAD_PASS(binding.datatype == MADDataTypeNull, "the type starts Null");
	MAD_PASS(binding.fieldIndex == (NSUInteger)0, "the field index starts at zero");
	MAD_PASS(binding.columnNumber == (NSUInteger)1, "the column number is one-based");
}

#pragma mark - Designated initializer coercions

static void testInitWithStringValue(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:3 value:@"hello"];
	MAD_PASS_EQUAL(binding.value, @"hello", "the string is stored");
	MAD_PASS(binding.datatype == MADDataTypeString, "the type is the string type");
	MAD_PASS(binding.fieldIndex == (NSUInteger)3, "the field index is stored");
	MAD_PASS(binding.columnNumber == (NSUInteger)4, "the column number is the index plus one");
}

static void testInitWithIntegerValue(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@5];
	MAD_PASS_EQUAL(binding.value, @5, "the number is stored");
	MAD_PASS(binding.datatype == MADDataTypeInteger, "the type is the integer type");
}

static void testInitWithNilValueStoresNSNull(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:nil];
	MAD_PASS_EQUAL(binding.value, [NSNull null], "a nil value normalises to NSNull");
	MAD_PASS(binding.datatype == MADDataTypeNull, "the type becomes Null");
}

static void testInitWithNullValueStoresNSNull(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:[NSNull null]];
	MAD_PASS(binding.datatype == MADDataTypeNull, "the type becomes Null");
	MAD_PASS_EQUAL(binding.value, [NSNull null], "an explicit NSNull normalises to the same stored form");
}

static void testInitWithUnknownDatatypeCoercesToString(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeUnknown fieldIndex:0 value:@42];
	MAD_PASS_EQUAL(binding.value, @"42", "an unknown type coerces the value to a string");
	MAD_PASS(binding.datatype == MADDataTypeString, "the type becomes String");
}

#pragma mark - DataTypeLimited mappings

static void testDataTypeLimitedIntegerFamily(void) {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBit), @(MADDataTypeShort), @(MADDataTypeLong),
		@(MADDataTypeLongLong), @(MADDataTypeInt24), @(MADDataTypeEnum),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@1];
		MAD_PASS(binding.datatype == MADDataTypeInteger, "the integer family limits to Integer");
	}
}

static void testDataTypeLimitedStringFamily(void) {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeSet), @(MADDataTypeTime), @(MADDataTypeTimeStamp),
		@(MADDataTypeYear), @(MADDataTypeDate), @(MADDataTypeDateTime),
		@(MADDataTypeString), @(MADDataTypeVarChar), @(MADDataTypeGeometry),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@"x"];
		MAD_PASS(binding.datatype == MADDataTypeString, "the string family limits to String");
	}
}

static void testDataTypeLimitedFloatAndDoubleFamily(void) {
	MADDatabaseDataBinding *flt = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeFloat fieldIndex:0 value:@1.5f];
	MAD_PASS(flt.datatype == MADDataTypeFloat, "Float stays Float");

	MADDatabaseDataBinding *dec = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeDecimal fieldIndex:0 value:@1.5];
	MAD_PASS(dec.datatype == MADDataTypeDouble, "Decimal limits to Double");

	MADDatabaseDataBinding *num = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeNumber fieldIndex:0 value:@1];
	MAD_PASS(num.datatype == MADDataTypeDouble, "Number limits to Double");
}

static void testDataTypeLimitedBlob(void) {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBlob fieldIndex:0 value:data];
	MAD_PASS(binding.datatype == MADDataTypeBlob, "Blob stays Blob");
	MAD_PASS_EQUAL(binding.value, data, "the data is stored");
}

#pragma mark - Canonical classes

// The contract (BUGS.md, the MADReportFormatter untyped-compare entry): the
// binding stores one canonical class per declared type, converting what the
// type can represent and storing NULL for what it cannot -- never silently as
// another class.

static void testCanonicalDateFamilyStoresTheEpochNumber(void) {
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeDate), @(MADDataTypeDateTime),
		@(MADDataTypeTime), @(MADDataTypeTimeStamp),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:date];
		MAD_PASS(binding.datatype == MADDataTypeString, "the date family limits to String");
		MAD_PASS([binding.value isKindOfClass:[NSNumber class]], "the date family stores the epoch number");
		MAD_PASS(((NSNumber *)binding.value).doubleValue > 1234567890.0 && ((NSNumber *)binding.value).doubleValue < 1234567891.0,
				 "the epoch is the date's");
	}
}

static void testCanonicalBlobConvertsTextToUtf8Data(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBlob fieldIndex:0 value:@"abc"];
	MAD_PASS([binding.value isKindOfClass:[NSData class]], "a blob column stores data");
	MAD_PASS_EQUAL(binding.value, [@"abc" dataUsingEncoding:NSUTF8StringEncoding], "the text is stored as its UTF-8 bytes");
}

static void testCanonicalStringConvertsNumbersToText(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:@42];
	MAD_PASS_EQUAL(binding.value, @"42", "a string column stores the number's text");
	MAD_PASS(binding.datatype == MADDataTypeString, "the type stays String");
}

static void testCanonicalIntegerConvertsTextByParsing(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@"42"];
	MAD_PASS_EQUAL(binding.value, @42, "an integer column parses the number");
	MAD_PASS(binding.datatype == MADDataTypeInteger, "the type stays Integer");
}

static void testCanonicalUnrepresentableValuesStoreNull(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:[NSData data]];
	MAD_PASS(binding.value == [NSNull null], "data in an integer column stores NULL");

	MADDatabaseDataBinding *stringBinding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:[NSDate date]];
	MAD_PASS(stringBinding.value == [NSNull null], "a date in a plain string column stores NULL");
}

static void testCanonicalImageFamilyIsBlob(void) {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeImage fieldIndex:0 value:data];
	MAD_PASS(binding.datatype == MADDataTypeBlob, "an image column limits to Blob");
	MAD_PASS_EQUAL(binding.value, data, "the data is stored");

	MADDatabaseDataBinding *textBinding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeImage fieldIndex:0 value:@"abc"];
	MAD_PASS([textBinding.value isKindOfClass:[NSData class]], "text in an image column stores data");
	MAD_PASS_EQUAL(textBinding.value, data, "the UTF-8 bytes are stored");
}

static void testCanonicalRemainingFamilies(void) {
	// Bit is numeric; Set, Year and Geometry are text.
	MADDatabaseDataBinding *bit = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBit fieldIndex:0 value:@1];
	MAD_PASS(bit.datatype == MADDataTypeInteger, "a bit limits to Integer");
	MAD_PASS_EQUAL(bit.value, @1, "the bit is stored");

	NSArray<NSNumber *> *types = @[@(MADDataTypeSet), @(MADDataTypeYear), @(MADDataTypeGeometry)];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@42];
		MAD_PASS(binding.datatype == MADDataTypeString, "set/year/geometry limit to String");
		MAD_PASS_EQUAL(binding.value, @"42", "the number's text is stored");
	}
}

static void testCanonicalNullColumnWithAValueStringifies(void) {
	// A Null-declared column holding a real value is itself a violation of the
	// table; the value takes the Unknown fallback and stringifies, as it did
	// before the contract.
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeNull fieldIndex:0 value:@42];
	MAD_PASS(binding.datatype == MADDataTypeString, "a null column with a value stringifies to String");
	MAD_PASS_EQUAL(binding.value, @"42", "the value's text is stored");
}

#pragma mark - NSCopying

static void testCopy(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:2 value:@"hello"];
	MADDatabaseDataBinding *copy = [binding copy];

	MAD_PASS(copy != binding, "the copy is a different object");
	MAD_PASS_EQUAL(copy.value, @"hello", "the value survives the copy");
	MAD_PASS(copy.datatype == MADDataTypeString, "the type survives");
	MAD_PASS(copy.fieldIndex == (NSUInteger)2, "the field index survives");
	MAD_PASS(copy.columnNumber == (NSUInteger)3, "the column number survives");
}

#pragma mark - NSSecureCoding

static void testSupportsSecureCoding(void) {
	MAD_PASS([MADDatabaseDataBinding supportsSecureCoding], "the class claims secure coding");
}

static void testNSCodingRoundTrip(void) {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:2 value:@"hello"];
#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:binding requiringSecureCoding:YES error:NULL];
	MADDatabaseDataBinding *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseDataBinding class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:binding requiringSecureCoding:NO error:NULL];
	MADDatabaseDataBinding *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the binding round trips");
	MAD_PASS_EQUAL(decoded.value, @"hello", "the value survives the round trip");
	MAD_PASS(decoded.datatype == MADDataTypeString, "the type survives");
	MAD_PASS(decoded.fieldIndex == (NSUInteger)2, "the field index survives");
}

MAD_TEST_MAIN("MADDatabaseDataBindingTests",
	MAD_TEST(testInitDefaults),
	MAD_TEST(testInitWithStringValue),
	MAD_TEST(testInitWithIntegerValue),
	MAD_TEST(testInitWithNilValueStoresNSNull),
	MAD_TEST(testInitWithNullValueStoresNSNull),
	MAD_TEST(testInitWithUnknownDatatypeCoercesToString),
	MAD_TEST(testDataTypeLimitedIntegerFamily),
	MAD_TEST(testDataTypeLimitedStringFamily),
	MAD_TEST(testDataTypeLimitedFloatAndDoubleFamily),
	MAD_TEST(testDataTypeLimitedBlob),
	MAD_TEST(testCanonicalDateFamilyStoresTheEpochNumber),
	MAD_TEST(testCanonicalBlobConvertsTextToUtf8Data),
	MAD_TEST(testCanonicalStringConvertsNumbersToText),
	MAD_TEST(testCanonicalIntegerConvertsTextByParsing),
	MAD_TEST(testCanonicalUnrepresentableValuesStoreNull),
	MAD_TEST(testCanonicalImageFamilyIsBlob),
	MAD_TEST(testCanonicalRemainingFamilies),
	MAD_TEST(testCanonicalNullColumnWithAValueStringifies),
	MAD_TEST(testCopy),
	MAD_TEST(testSupportsSecureCoding),
	MAD_TEST(testNSCodingRoundTrip));
