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
