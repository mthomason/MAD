//
//  MADStringUtilitiesTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADStringUtilities: the two tiny string-assembly helpers used
//  for key paths and display strings throughout the app.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADStringUtilities.h>

@interface MADStringUtilitiesTests : XCTestCase
@end

@implementation MADStringUtilitiesTests

- (void)testAppendPeriodToEmptyString {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingPeriod:@""], @".");
}

- (void)testAppendPeriodToPlainString {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingPeriod:@"foo"], @"foo.");
}

- (void)testAppendPeriodDoesNotDoubleUp {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingPeriod:@"foo."], @"foo.");
}

- (void)testAppendPeriodToNilReturnsPeriod {
	// nil.length == 0, so this follows the empty-string path.
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingPeriod:nil], @".");
}

- (void)testAppendKeyPath {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:@"bar" toString:@"foo"], @"foo.bar");
}

- (void)testAppendEmptyKeyPathReturnsStringUnchanged {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:@"" toString:@"foo"], @"foo");
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:nil toString:@"foo"], @"foo");
}

- (void)testAppendKeyPathToNilString {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:@"bar" toString:nil], @".bar");
}

- (void)testAppendPeriodToPeriod {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingPeriod:@"."], @".");
}

- (void)testAppendKeyPathDoesNotDoubleThePeriod {
	// The receiver already ends in a period; only the key path is appended.
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:@"bar" toString:@"foo."], @"foo.bar");
}

- (void)testAppendMultiComponentKeyPath {
	XCTAssertEqualObjects([MADStringUtilities stringByAppendingKeyPath:@"bar.baz" toString:@"foo"], @"foo.bar.baz");
}

@end
