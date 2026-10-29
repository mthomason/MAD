//
//  MADViewHelpersTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADViewHelpers: the autoresizing mask the title labels use, and the
//  safe-area reader.  A detached view has zero safe-area insets, which is the state
//  the reader is pinned against here.
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIView.h>

#import <MADCocoaExtensions/MADViewHelpers.h>

@interface MADViewHelpersTests : XCTestCase
@end

@implementation MADViewHelpersTests

- (void)testFlexibleAutoresizingMask {
	enum UIViewAutoresizing mask = MADViewAutoresizingFlexable();

	XCTAssertEqual(mask, (enum UIViewAutoresizing)(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight));
}

- (void)testSafeAreaInsetsAreCopiedFromTheView {
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	UIEdgeInsets insets = UIEdgeInsetsMake(99, 99, 99, 99);

	MADViewSafeAreaInserts(view, &insets);

	// A detached view reports zero insets; the function writes them through.
	XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, view.safeAreaInsets));
	XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero));
}

@end
#endif
