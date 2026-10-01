//
//  MTMathTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the MTMath helpers and the inline random/size functions.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MTMath.h>

@interface MTMathTests : XCTestCase
@end

@implementation MTMathTests

- (void)testRandomNumberBetweenSingleValue {
	XCTAssertEqual(madRandomNumberBetween(5, 5), (NSUInteger)5);
	XCTAssertEqual(madRandomNumberBetween(0, 0), (NSUInteger)0);
}

- (void)testRandomNumberBetweenBounds {
	for (int i = 0; i < 1000; i++) {
		NSUInteger n = madRandomNumberBetween(0, 10);
		XCTAssertGreaterThanOrEqual(n, (NSUInteger)0);
		XCTAssertLessThanOrEqual(n, (NSUInteger)10);
	}
}

- (void)testRandomNumberInRange {
	// A single-element range can only yield its location.
	XCTAssertEqual(madRandomNumberInRange(NSMakeRange(5, 1)), (NSUInteger)5);

	for (int i = 0; i < 1000; i++) {
		NSUInteger n = madRandomNumberInRange(NSMakeRange(3, 4));
		XCTAssertGreaterThanOrEqual(n, (NSUInteger)3);
		XCTAssertLessThanOrEqual(n, (NSUInteger)6);
	}
}

- (void)testSystemFileSizeToMB {
	XCTAssertEqual(madSystemFileSizeToMB(5000000), 5.0);
	// Floating-point division keeps the fractional megabyte.
	XCTAssertEqual(madSystemFileSizeToMB(1500000), 1.5);
	XCTAssertEqual(madSystemFileSizeToMB(0), 0.0);
}

- (void)testNewSystemFileSizeToMB {
	XCTAssertEqualObjects([MTMath newSystemFileSizeToMB:5000000], @5.0);
	XCTAssertEqualObjects([MTMath newSystemFileSizeToMB:1500000], @1.5);
}

@end
