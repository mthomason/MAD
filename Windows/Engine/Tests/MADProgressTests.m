//
//  MADProgressTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADProgressTests.m: coverage for MADProgress,
//  the immutable message/progress pair posted as part of progress
//  notifications.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADProgress.h>

static void testInitWithMessageAndProgress(void) {
	MADProgress *progress = [[MADProgress alloc] initWithMessage:@"Loading" andProgress:0.5f];
	MAD_PASS_EQUAL(progress.message, @"Loading", "message");
	MAD_PASS(progress.progress == 0.5f, "progress");
}

static void testMessageIsCopied(void) {
	NSMutableString *mutable = [@"Loading" mutableCopy];
	MADProgress *progress = [[MADProgress alloc] initWithMessage:mutable andProgress:0.0f];
	[mutable appendString:@" more"];
	MAD_PASS_EQUAL(progress.message, @"Loading", "message survives the source's mutation");
}

static void testCopy(void) {
	MADProgress *progress = [[MADProgress alloc] initWithMessage:@"Loading" andProgress:0.25f];
	MADProgress *copy = [progress copy];
	MAD_PASS(copy != nil, "copy is not nil");
	MAD_PASS(copy != progress, "copy is a distinct object");
	MAD_PASS_EQUAL(copy.message, @"Loading", "copy's message");
	MAD_PASS(copy.progress == 0.25f, "copy's progress");
}

MAD_TEST_MAIN("MADProgressTests",
	MAD_TEST(testInitWithMessageAndProgress),
	MAD_TEST(testMessageIsCopied),
	MAD_TEST(testCopy));
