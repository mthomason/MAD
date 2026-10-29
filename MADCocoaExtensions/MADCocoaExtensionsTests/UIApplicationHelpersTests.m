//
//  UIApplicationHelpersTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for UIApplication (Helpers).  This is a logic-test bundle, so there is no
//  application scene: the window lookup has nothing to find, and the pins record that
//  the helpers stay nil-safe instead of trapping without an app.
//
//  -requestBackgroundTask is not exercised: it begins a real background task, which
//  needs a running application.
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#import <UIKit/UIWindow.h>

#import <MADCocoaExtensions/UIApplication+Helpers.h>

@interface UIApplicationHelpersTests : XCTestCase
@end

@implementation UIApplicationHelpersTests

- (void)testVersionMatchesTheMainBundle {
	NSString *version = [UIApplication version];
	NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

	XCTAssertEqualObjects(version, bundleVersion);
}

- (void)testSafeKeyWindowWithoutASceneIsNil {
	XCTAssertNil([UIApplication sharedApplication].safeKeyWindow);
}

- (void)testTopViewControllerWithoutAWindowIsNil {
	XCTAssertNil([UIApplication topViewController]);
}

@end
#endif
