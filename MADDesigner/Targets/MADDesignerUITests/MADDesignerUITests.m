//
//  MADDesignerUITests.m
//  MADDesignerUITests
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

// The XCUITest runner in this environment sees an empty accessibility tree for the
// app (every query, down to app.debugDescription, reports no elements), so no UI
// assertion can pass here.  The simulator exercise -- open a sample, walk the three
// tabs -- is driven instead with the app's launch arguments (see AppDelegate.m:
// -UITestOpenSample and -UITestSelectTab) and verified by screenshot.  See BUGS.md,
// "Test infrastructure".

#import <XCTest/XCTest.h>

@interface MADDesignerUITests : XCTestCase

@end

@implementation MADDesignerUITests

- (void)setUp {
	[super setUp];
	self.continueAfterFailure = NO;
}

- (void)testExample {
	// Intentionally empty; see the file comment.
}

@end
