//
//  MADApplicationTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADApplicationTests.m: coverage for
//  MADApplication, the app-identity helpers the frameworks use to decide how
//  to reach the shared container and which product is running.
//
//  The Apple suite selects its group-identifier expectation with #if DEBUG in
//  the test translation unit.  The Linux test translation unit carries no
//  DEBUG define of its own, but the library target is compiled with -DDEBUG=1
//  whenever CMAKE_BUILD_TYPE is Debug (cmake/MADLinuxFramework.cmake), so the
//  framework answers the Debug ".local" identifier -- the value the Apple
//  test's #if DEBUG arm pins -- and that is what is asserted here.
//
//  The delegate expectations hold as the Apple suite describes them:
//  MADApplication's Linux branch has no application object and answers nil by
//  design (MADFoundation/Source/MADApplication.m), so the product checks that
//  read the delegate's identifier answer NO.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

#pragma mark - Identifiers

static void testGroupIdentifierMatchesBuildConfiguration(void) {
	// The Linux library target gets -DDEBUG=1 in Debug configurations, so
	// MADApplication.m's #if DEBUG arm is live and the Debug group identifier
	// is what comes back.
	MAD_PASS_EQUAL([MADApplication groupIdentifier], @"group.everydayapps.mad.local",
				   "the Debug build's group identifier");
}

static void testUbiquityIdentifierWithoutContainersKey(void) {
	// The test executable's bundle declares no NSUbiquitousContainers, so there
	// is no iCloud container to report.
	MAD_PASS([MADApplication ubiquityIdentifier] == nil, "no iCloud container to report");
}

#pragma mark - Product identity

static void testAppDelegateAccessOnTheMainThread(void) {
	// Tests run on the main thread; the headless engine has no shared
	// application, so the answer is nil (and never an exception).
	id delegate = nil;
	MAD_NO_THROW(delegate = [MADApplication AppDelegate], "AppDelegate does not throw on the main thread");
	if (delegate != nil) {
		MAD_PASS([delegate conformsToProtocol:@protocol(MADApplicationProtocol)],
				 "a delegate conforms to MADApplicationProtocol");
	}
}

static void testProductChecksAreFalseWithoutAnAppDelegate(void) {
	MAD_PASS(![MADApplication isMADDesigner], "not the designer without a delegate");
	MAD_PASS(![MADApplication isMADViewer], "not the viewer without a delegate");
}

MAD_TEST_MAIN("MADApplicationTests",
	MAD_TEST(testGroupIdentifierMatchesBuildConfiguration),
	MAD_TEST(testUbiquityIdentifierWithoutContainersKey),
	MAD_TEST(testAppDelegateAccessOnTheMainThread),
	MAD_TEST(testProductChecksAreFalseWithoutAnAppDelegate));
