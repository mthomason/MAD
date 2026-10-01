//
//  MADProgressTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADProgress: the immutable message/progress pair posted as part
//  of progress notifications.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADProgress.h>

@interface MADProgressTests : XCTestCase
@end

@implementation MADProgressTests

- (void)testInitWithMessageAndProgress {
	MADProgress *progress = [[MADProgress alloc] initWithMessage:@"Loading" andProgress:0.5f];
	XCTAssertEqualObjects(progress.message, @"Loading");
	XCTAssertEqual(progress.progress, 0.5f);
}

- (void)testMessageIsCopied {
	NSMutableString *mutable = [@"Loading" mutableCopy];
	MADProgress *progress = [[MADProgress alloc] initWithMessage:mutable andProgress:0.0f];
	[mutable appendString:@" more"];
	XCTAssertEqualObjects(progress.message, @"Loading");
}

- (void)testCopy {
	MADProgress *progress = [[MADProgress alloc] initWithMessage:@"Loading" andProgress:0.25f];
	MADProgress *copy = [progress copy];
	XCTAssertNotNil(copy);
	XCTAssertTrue(copy != progress);
	XCTAssertEqualObjects(copy.message, @"Loading");
	XCTAssertEqual(copy.progress, 0.25f);
}

@end
