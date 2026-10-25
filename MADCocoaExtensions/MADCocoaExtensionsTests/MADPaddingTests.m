//
//  MADPaddingTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADPadding: init, property accessors, NSCoding round-trip, and
//  NSCopying independence.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MADPadding.h>

@interface MADPaddingTests : XCTestCase
@end

@implementation MADPaddingTests

- (void)testInitDefaults {
	MADPadding *padding = [[MADPadding alloc] init];
	XCTAssertEqual(padding.left, (Float64)0);
	XCTAssertEqual(padding.right, (Float64)0);
	XCTAssertEqual(padding.top, (Float64)0);
	XCTAssertEqual(padding.bottom, (Float64)0);
}

- (void)testInitWithEdges {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1.5 right:2.5 top:3.5 bottom:4.5];
	XCTAssertEqual(padding.left, (Float64)1.5);
	XCTAssertEqual(padding.right, (Float64)2.5);
	XCTAssertEqual(padding.top, (Float64)3.5);
	XCTAssertEqual(padding.bottom, (Float64)4.5);
}

- (void)testSetters {
	MADPadding *padding = [[MADPadding alloc] init];
	padding.left = 9;
	padding.right = 8;
	padding.top = 7;
	padding.bottom = 6;
	XCTAssertEqual(padding.left, (Float64)9);
	XCTAssertEqual(padding.right, (Float64)8);
	XCTAssertEqual(padding.top, (Float64)7);
	XCTAssertEqual(padding.bottom, (Float64)6);
}

- (void)testCopyIsIndependent {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1 right:2 top:3 bottom:4];
	MADPadding *copy = [padding copy];
	XCTAssertNotNil(copy);
	XCTAssertEqual(copy.left, padding.left);

	copy.left = 99;
	XCTAssertEqual(copy.left, (Float64)99);
	XCTAssertEqual(padding.left, (Float64)1);
}

- (void)testCodingRoundTrip {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1.25 right:2.5 top:3.75 bottom:4.5];
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:padding requiringSecureCoding:NO error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADPadding *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.left, (Float64)1.25);
	XCTAssertEqual(decoded.right, (Float64)2.5);
	XCTAssertEqual(decoded.top, (Float64)3.75);
	XCTAssertEqual(decoded.bottom, (Float64)4.5);
}

@end
