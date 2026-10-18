//
//  MADDatabaseDataBindingTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 2 coverage for MADDatabaseDataBinding: the value type that binds a
//  typed value to a query-result field index.  Exercises the private
//  DataTypeLimited() mapping, the nil / NSNull / unknown-type coercions, the
//  1-based column number, and NSCopying / NSSecureCoding.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseDataBinding.h>

@interface MADDatabaseDataBindingTests : XCTestCase
@end

@implementation MADDatabaseDataBindingTests

#pragma mark - Default init

- (void)testInitDefaults {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] init];
	XCTAssertNil(binding.value);
	XCTAssertEqual(binding.datatype, MADDataTypeNull);
	XCTAssertEqual(binding.fieldIndex, (NSUInteger)0);
	XCTAssertEqual(binding.columnNumber, (NSUInteger)1);
}

#pragma mark - Designated initializer coercions

- (void)testInitWithStringValue {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:3 value:@"hello"];
	XCTAssertEqualObjects(binding.value, @"hello");
	XCTAssertEqual(binding.datatype, MADDataTypeString);
	XCTAssertEqual(binding.fieldIndex, (NSUInteger)3);
	XCTAssertEqual(binding.columnNumber, (NSUInteger)4);
}

- (void)testInitWithIntegerValue {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@5];
	XCTAssertEqualObjects(binding.value, @5);
	XCTAssertEqual(binding.datatype, MADDataTypeInteger);
}

- (void)testInitWithNilValueStoresNSNull {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:nil];
	XCTAssertEqualObjects(binding.value, [NSNull null]);
	XCTAssertEqual(binding.datatype, MADDataTypeNull);
}

- (void)testInitWithNullValueStoresNSNull {
	// A nil value and an explicit [NSNull null] now normalise to the same stored form.
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:[NSNull null]];
	XCTAssertEqual(binding.datatype, MADDataTypeNull);
	XCTAssertEqualObjects(binding.value, [NSNull null]);
}

- (void)testInitWithUnknownDatatypeCoercesToString {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeUnknown fieldIndex:0 value:@42];
	XCTAssertEqualObjects(binding.value, @"42");
	XCTAssertEqual(binding.datatype, MADDataTypeString);
}

#pragma mark - DataTypeLimited mappings

- (void)testDataTypeLimitedIntegerFamily {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBit), @(MADDataTypeShort), @(MADDataTypeLong),
		@(MADDataTypeLongLong), @(MADDataTypeInt24), @(MADDataTypeEnum),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@1];
		XCTAssertEqual(binding.datatype, MADDataTypeInteger, @"%@ should limit to Integer", NSStringFromMADDataType(type));
	}
}

- (void)testDataTypeLimitedStringFamily {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeSet), @(MADDataTypeTime), @(MADDataTypeTimeStamp),
		@(MADDataTypeYear), @(MADDataTypeDate), @(MADDataTypeDateTime),
		@(MADDataTypeString), @(MADDataTypeVarChar), @(MADDataTypeGeometry),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@"x"];
		XCTAssertEqual(binding.datatype, MADDataTypeString, @"%@ should limit to String", NSStringFromMADDataType(type));
	}
}

- (void)testDataTypeLimitedFloatAndDoubleFamily {
	MADDatabaseDataBinding *flt = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeFloat fieldIndex:0 value:@1.5f];
	XCTAssertEqual(flt.datatype, MADDataTypeFloat);

	MADDatabaseDataBinding *dec = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeDecimal fieldIndex:0 value:@1.5];
	XCTAssertEqual(dec.datatype, MADDataTypeDouble);

	MADDatabaseDataBinding *num = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeNumber fieldIndex:0 value:@1];
	XCTAssertEqual(num.datatype, MADDataTypeDouble);
}

- (void)testDataTypeLimitedBlob {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBlob fieldIndex:0 value:data];
	XCTAssertEqual(binding.datatype, MADDataTypeBlob);
	XCTAssertEqualObjects(binding.value, data);
}

#pragma mark - Canonical classes

// The contract (BUGS.md, the MADReportFormatter untyped-compare entry): the
// binding stores one canonical class per declared type, converting what the
// type can represent and storing NULL for what it cannot -- never silently as
// another class.

- (void)testCanonicalDateFamilyStoresTheEpochNumber {
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1234567890.5];
	for (NSNumber *boxed in @[@(MADDataTypeDate), @(MADDataTypeDateTime), @(MADDataTypeTime), @(MADDataTypeTimeStamp)]) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:date];
		XCTAssertEqual(binding.datatype, MADDataTypeString, @"%@ limits to String", NSStringFromMADDataType(type));
		XCTAssertTrue([binding.value isKindOfClass:[NSNumber class]], @"%@ stores the epoch number", NSStringFromMADDataType(type));
		XCTAssertEqualWithAccuracy(((NSNumber *)binding.value).doubleValue, 1234567890.5, 0.001);
	}
}

- (void)testCanonicalBlobConvertsTextToUtf8Data {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBlob fieldIndex:0 value:@"abc"];
	XCTAssertTrue([binding.value isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(binding.value, [@"abc" dataUsingEncoding:NSUTF8StringEncoding]);
}

- (void)testCanonicalStringConvertsNumbersToText {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:@42];
	XCTAssertEqualObjects(binding.value, @"42");
	XCTAssertEqual(binding.datatype, MADDataTypeString);
}

- (void)testCanonicalIntegerConvertsTextByParsing {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:@"42"];
	XCTAssertEqualObjects(binding.value, @42);
	XCTAssertEqual(binding.datatype, MADDataTypeInteger);
}

- (void)testCanonicalUnrepresentableValuesStoreNull {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeInteger fieldIndex:0 value:[NSData data]];
	XCTAssertEqual(binding.value, [NSNull null]);

	MADDatabaseDataBinding *stringBinding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:0 value:[NSDate date]];
	XCTAssertEqual(stringBinding.value, [NSNull null]);
}

- (void)testCanonicalImageFamilyIsBlob {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeImage fieldIndex:0 value:data];
	XCTAssertEqual(binding.datatype, MADDataTypeBlob);
	XCTAssertEqualObjects(binding.value, data);

	MADDatabaseDataBinding *textBinding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeImage fieldIndex:0 value:@"abc"];
	XCTAssertTrue([textBinding.value isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(textBinding.value, data);
}

- (void)testCanonicalRemainingFamilies {
	// Bit is numeric; Set, Year and Geometry are text.
	MADDatabaseDataBinding *bit = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeBit fieldIndex:0 value:@1];
	XCTAssertEqual(bit.datatype, MADDataTypeInteger);
	XCTAssertEqualObjects(bit.value, @1);

	for (NSNumber *boxed in @[@(MADDataTypeSet), @(MADDataTypeYear), @(MADDataTypeGeometry)]) {
		MADDataType type = (MADDataType)boxed.intValue;
		MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:type fieldIndex:0 value:@42];
		XCTAssertEqual(binding.datatype, MADDataTypeString, @"%@ limits to String", NSStringFromMADDataType(type));
		XCTAssertEqualObjects(binding.value, @"42", @"%@ stores the number's text", NSStringFromMADDataType(type));
	}
}

- (void)testCanonicalNullColumnWithAValueStringifies {
	// A Null-declared column holding a real value is itself a violation of the
	// table; the value takes the Unknown fallback and stringifies, as it did
	// before the contract.
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeNull fieldIndex:0 value:@42];
	XCTAssertEqual(binding.datatype, MADDataTypeString);
	XCTAssertEqualObjects(binding.value, @"42");
}

#pragma mark - NSCopying

- (void)testCopy {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:2 value:@"hello"];
	MADDatabaseDataBinding *copy = [binding copy];

	XCTAssertNotEqual(copy, binding);
	XCTAssertEqualObjects(copy.value, @"hello");
	XCTAssertEqual(copy.datatype, MADDataTypeString);
	XCTAssertEqual(copy.fieldIndex, (NSUInteger)2);
	XCTAssertEqual(copy.columnNumber, (NSUInteger)3);
}

#pragma mark - NSSecureCoding

- (void)testSupportsSecureCoding {
	XCTAssertTrue([MADDatabaseDataBinding supportsSecureCoding]);
}

- (void)testNSCodingRoundTrip {
	MADDatabaseDataBinding *binding = [[MADDatabaseDataBinding alloc] initWithDataType:MADDataTypeString fieldIndex:2 value:@"hello"];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:binding requiringSecureCoding:YES error:NULL];
	MADDatabaseDataBinding *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseDataBinding class] fromData:data error:NULL];

	XCTAssertNotNil(decoded);
	XCTAssertEqualObjects(decoded.value, @"hello");
	XCTAssertEqual(decoded.datatype, MADDataTypeString);
	XCTAssertEqual(decoded.fieldIndex, (NSUInteger)2);
}

@end
