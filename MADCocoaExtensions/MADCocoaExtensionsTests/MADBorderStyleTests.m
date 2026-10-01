//
//  MADBorderStyleTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADBorderStyle: the MADBorderType enum, init, accessors,
//  NSSecureCoding round-trip, and NSCopying independence.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MADBorderStyle.h>

@interface MADBorderStyleTests : XCTestCase
@end

@implementation MADBorderStyleTests

- (void)testBorderTypeValues {
	XCTAssertEqual(MADBorderStyleNone, (MADBorderType)1);
	XCTAssertEqual(MADBorderStyleDash, (MADBorderType)2);
	XCTAssertEqual(MADBorderStyleDot, (MADBorderType)3);
	XCTAssertEqual(MADBorderStyleLine, (MADBorderType)4);
}

- (void)testInitDefaults {
	MADBorderStyle *style = [[MADBorderStyle alloc] init];
	XCTAssertEqual(style.left, (float)0);
	XCTAssertEqual(style.right, (float)0);
	XCTAssertEqual(style.top, (float)0);
	XCTAssertEqual(style.bottom, (float)0);
	XCTAssertEqual(style.leftStyle, MADBorderStyleNone);
	XCTAssertEqual(style.rightStyle, MADBorderStyleNone);
	XCTAssertEqual(style.topStyle, MADBorderStyleNone);
	XCTAssertEqual(style.bottomStyle, MADBorderStyleNone);
}

- (void)testInitWithEdgesAndStyles {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1 right:2 top:3 bottom:4
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleDash
														topStyle:MADBorderStyleDot bottomStyle:MADBorderStyleNone];
	XCTAssertEqual(style.left, (float)1);
	XCTAssertEqual(style.right, (float)2);
	XCTAssertEqual(style.top, (float)3);
	XCTAssertEqual(style.bottom, (float)4);
	XCTAssertEqual(style.leftStyle, MADBorderStyleLine);
	XCTAssertEqual(style.rightStyle, MADBorderStyleDash);
	XCTAssertEqual(style.topStyle, MADBorderStyleDot);
	XCTAssertEqual(style.bottomStyle, MADBorderStyleNone);
}

- (void)testSetters {
	MADBorderStyle *style = [[MADBorderStyle alloc] init];
	style.leftStyle = MADBorderStyleDot;
	style.top = 5;
	XCTAssertEqual(style.leftStyle, MADBorderStyleDot);
	XCTAssertEqual(style.top, (float)5);
}

- (void)testCopyIsIndependent {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1 right:2 top:3 bottom:4
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleLine
														topStyle:MADBorderStyleLine bottomStyle:MADBorderStyleLine];
	MADBorderStyle *copy = [style copy];
	XCTAssertNotNil(copy);
	copy.left = 99;
	XCTAssertEqual(copy.left, (float)99);
	XCTAssertEqual(style.left, (float)1);
}

- (void)testSecureCodingRoundTrip {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1.5 right:2.5 top:3.5 bottom:4.5
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleDash
														topStyle:MADBorderStyleDot bottomStyle:MADBorderStyleNone];
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:style requiringSecureCoding:YES error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADBorderStyle *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADBorderStyle class] fromData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.left, (float)1.5);
	XCTAssertEqual(decoded.right, (float)2.5);
	XCTAssertEqual(decoded.top, (float)3.5);
	XCTAssertEqual(decoded.bottom, (float)4.5);
	XCTAssertEqual(decoded.leftStyle, MADBorderStyleLine);
	XCTAssertEqual(decoded.rightStyle, MADBorderStyleDash);
	XCTAssertEqual(decoded.topStyle, MADBorderStyleDot);
	XCTAssertEqual(decoded.bottomStyle, MADBorderStyleNone);
}

@end
