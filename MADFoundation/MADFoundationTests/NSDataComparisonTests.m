//
//  NSDataComparisonTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the NSData (Comparison) category: lexicographic byte ordering
//  used for sorting BLOB columns.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/NSData+Comparison.h>

@interface NSDataComparisonTests : XCTestCase
@end

@implementation NSDataComparisonTests

- (void)testCompareNil {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([data compareData:nil], NSOrderedDescending);
}

- (void)testCompareSelfIsSame {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([data compareData:data], NSOrderedSame);
}

- (void)testCompareEqualDataIsSame {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([a compareData:b], NSOrderedSame);
}

- (void)testCompareLexicographic {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abd" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([a compareData:b], NSOrderedAscending);
	XCTAssertEqual([b compareData:a], NSOrderedDescending);
}

- (void)testLongerCommonPrefixIsGreater {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abcd" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([a compareData:b], NSOrderedAscending);
	XCTAssertEqual([b compareData:a], NSOrderedDescending);
}

- (void)testEmptyVsNonEmpty {
	NSData *empty = [NSData data];
	NSData *nonEmpty = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqual([empty compareData:nonEmpty], NSOrderedAscending);
	XCTAssertEqual([nonEmpty compareData:empty], NSOrderedDescending);
}

@end
