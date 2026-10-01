//
//  MADStringUtilitiesTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
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

@end
