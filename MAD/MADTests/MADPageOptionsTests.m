//
//  MADPageOptionsTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADPageOptions: a plain property bag for the page
//  geometry the formatter uses.  It has no initialiser of its own, so an instance starts
//  at zero size and zero insets and just round-trips what is set.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIGeometry.h>

#import "MADPageOptions.h"

@interface MADPageOptionsTests : XCTestCase
@end

@implementation MADPageOptionsTests

- (void)testDefaultsAreZeroGeometry {
	MADPageOptions *options = [[MADPageOptions alloc] init];

	XCTAssertTrue(CGSizeEqualToSize(options.layoutSize, CGSizeZero));
	XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(options.margins, UIEdgeInsetsZero));
}

- (void)testGeometryRoundTrips {
	MADPageOptions *options = [[MADPageOptions alloc] init];

	options.layoutSize = CGSizeMake(612.0, 792.0);
	options.margins = UIEdgeInsetsMake(36.0, 36.0, 54.0, 54.0);

	XCTAssertTrue(CGSizeEqualToSize(options.layoutSize, CGSizeMake(612.0, 792.0)));
	XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(options.margins, UIEdgeInsetsMake(36.0, 36.0, 54.0, 54.0)));
}

@end
