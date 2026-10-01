//
//  MADMarginTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADMargin: init, property accessors, NSCoding round-trip, and
//  NSCopying independence.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MADMargin.h>

@interface MADMarginTests : XCTestCase
@end

@implementation MADMarginTests

- (void)testInitDefaults {
	MADMargin *margin = [[MADMargin alloc] init];
	XCTAssertEqual(margin.left, (Float64)0);
	XCTAssertEqual(margin.right, (Float64)0);
	XCTAssertEqual(margin.top, (Float64)0);
	XCTAssertEqual(margin.bottom, (Float64)0);
}

- (void)testInitWithEdges {
	MADMargin *margin = [[MADMargin alloc] initWithLeft:1.5 right:2.5 top:3.5 bottom:4.5];
	XCTAssertEqual(margin.left, (Float64)1.5);
	XCTAssertEqual(margin.right, (Float64)2.5);
	XCTAssertEqual(margin.top, (Float64)3.5);
	XCTAssertEqual(margin.bottom, (Float64)4.5);
}

- (void)testSetters {
	MADMargin *margin = [[MADMargin alloc] init];
	margin.left = 9;
	margin.right = 8;
	margin.top = 7;
	margin.bottom = 6;
	XCTAssertEqual(margin.left, (Float64)9);
	XCTAssertEqual(margin.right, (Float64)8);
	XCTAssertEqual(margin.top, (Float64)7);
	XCTAssertEqual(margin.bottom, (Float64)6);
}

- (void)testCopyIsIndependent {
	MADMargin *margin = [[MADMargin alloc] initWithLeft:1 right:2 top:3 bottom:4];
	MADMargin *copy = [margin copy];
	XCTAssertNotNil(copy);
	XCTAssertEqual(copy.left, margin.left);

	copy.left = 99;
	XCTAssertEqual(copy.left, (Float64)99);
	XCTAssertEqual(margin.left, (Float64)1);
}

- (void)testCodingRoundTrip {
	MADMargin *margin = [[MADMargin alloc] initWithLeft:1.25 right:2.5 top:3.75 bottom:4.5];
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:margin requiringSecureCoding:NO error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADMargin *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.left, (Float64)1.25);
	XCTAssertEqual(decoded.right, (Float64)2.5);
	XCTAssertEqual(decoded.top, (Float64)3.75);
	XCTAssertEqual(decoded.bottom, (Float64)4.5);
}

@end
