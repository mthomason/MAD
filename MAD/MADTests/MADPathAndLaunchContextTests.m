//
//  MADPathAndLaunchContextTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 1 coverage for two store-free helpers:
//
//    * MADPathUtilities +stringWithPath:relativeTo: -- the relative-path computation
//      used when presenting document locations.
//    * MADAppLaunchContext -- the two launch paths the app supports (an NSUserActivity
//      carrying a document URL, and a lister:// URL), and the validation each performs.
//

#import <XCTest/XCTest.h>

#import "MADPathUtilities.h"
#import "MADAppLaunchContext.h"

@interface MADPathAndLaunchContextTests : XCTestCase
@end

@implementation MADPathAndLaunchContextTests

#pragma mark - MADPathUtilities

- (void)testRelativePathIsEmptyForIdenticalPaths {
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"/Users/mad/report.mad" relativeTo:@"/Users/mad/report.mad"], @"");
}

- (void)testRelativePathDescendsFromAnchor {
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"/Users/mad/Documents/report.mad" relativeTo:@"/Users/mad"], @"Documents/report.mad");
}

- (void)testRelativePathIsSibling {
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"/Users/mad/b" relativeTo:@"/Users/mad/c"], @"../b");
}

- (void)testRelativePathClimbsToCommonAncestor {
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"/a/b/c" relativeTo:@"/a/x/y/z"], @"../../../b/c");
}

- (void)testRelativePathClimbsOneLevel {
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"/a/b" relativeTo:@"/a/b/c"], @"..");
}

- (void)testRelativePathWithNoCommonComponents {
	// A relative base against an absolute anchor shares nothing, so every anchor
	// component has to be undone.
	XCTAssertEqualObjects([MADPathUtilities stringWithPath:@"a/b" relativeTo:@"/a/b"], @"../../../a/b");
}

#pragma mark - MADAppLaunchContext (NSUserActivity)

- (void)testLaunchContextFromUserActivityDocumentURL {
	NSURL *documentURL = [NSURL fileURLWithPath:@"/tmp/Report.mad"];
	NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.example.tests"];
	activity.userInfo = @{ NSUserActivityDocumentURLKey: documentURL };

	MADAppLaunchContext *context = [[MADAppLaunchContext alloc] initWithUserActivity:activity];

	XCTAssertEqualObjects(context.fileURL, documentURL);
}

- (void)testLaunchContextFromUserActivityPath {
	NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.example.tests"];
	// The private fallback key used when the activity carries a path, not a URL.
	activity.userInfo = @{ @"MADUserInfoKeyFileURL": @"/tmp/Report.mad" };

	MADAppLaunchContext *context = [[MADAppLaunchContext alloc] initWithUserActivity:activity];

	XCTAssertTrue(context.fileURL.isFileURL);
	XCTAssertEqualObjects(context.fileURL.path, @"/tmp/Report.mad");
}

#pragma mark - MADAppLaunchContext (lister:// URL)

- (void)testLaunchContextFromListerURL {
	NSURL *listerURL = [NSURL URLWithString:@"lister:///tmp/Report.mad"];
	MADAppLaunchContext *context = [[MADAppLaunchContext alloc] initWithFileURL:listerURL];

	XCTAssertTrue(context.fileURL.isFileURL);
	XCTAssertEqualObjects(context.fileURL.path, @"/tmp/Report.mad");
}

- (void)testLaunchContextRejectsNonListerURL {
	NSURL *httpURL = [NSURL URLWithString:@"http://example.com/Report.mad"];
	// NSParameterAssert fires for a scheme that is not lister://.
	XCTAssertThrowsSpecificNamed([[MADAppLaunchContext alloc] initWithFileURL:httpURL],
								 NSException, NSInternalInconsistencyException);
}

@end
