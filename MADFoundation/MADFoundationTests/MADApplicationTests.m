//
//  MADApplicationTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADApplication: the app-identity helpers the frameworks use to
//  decide how to reach the shared container and which product is running.
//
//  These tests run in a logic-test bundle, which has no shared application and no
//  App Group entitlement.  That is exactly the state pinned here: +AppDelegate
//  answers nil (or, if some future host supplies one, an id that conforms), and the
//  product checks that read the delegate's identifier answer NO.  The group-URL
//  consumers are covered in MADURLFactoryTests, where the missing entitlement is
//  documented.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@interface MADApplicationTests : XCTestCase
@end

@implementation MADApplicationTests

#pragma mark - Identifiers

- (void)testGroupIdentifierMatchesBuildConfiguration {
#if DEBUG
	XCTAssertEqualObjects([MADApplication groupIdentifier], @"group.everydayapps.mad.local");
#else
	XCTAssertEqualObjects([MADApplication groupIdentifier], @"group.everydayapps.mad");
#endif
}

- (void)testUbiquityIdentifierWithoutContainersKey {
	// The test bundle's Info.plist declares no NSUbiquitousContainers, so there is
	// no iCloud container to report.
	XCTAssertNil([MADApplication ubiquityIdentifier]);
}

#pragma mark - Product identity

- (void)testAppDelegateAccessOnTheMainThread {
	// Tests run on the main thread; with no shared application the answer is nil.
	__block id delegate = nil;
	XCTAssertNoThrow(delegate = [MADApplication AppDelegate]);
	if (delegate != nil) {
		XCTAssertTrue([delegate conformsToProtocol:@protocol(MADApplicationProtocol)]);
	}
}

- (void)testProductChecksAreFalseWithoutAnAppDelegate {
	XCTAssertFalse([MADApplication isMADDesigner]);
	XCTAssertFalse([MADApplication isMADViewer]);
}

@end
