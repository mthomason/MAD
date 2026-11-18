//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADPageOptionsTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADPageOptionsTests.m: MADPageOptions is a plain
//  property bag for the page geometry the formatter uses.  It has no initialiser
//  of its own, so an instance starts at zero size and zero insets and just
//  round-trips what is set.  The UIKit geometry comes from the Linux UIKit shim.
//

#import "MADTestSupport.h"

#import <UIKit/UIGeometry.h>

#import <MAD/MADPageOptions.h>

static void testDefaultsAreZeroGeometry(void) {
	MADPageOptions *options = [[MADPageOptions alloc] init];

	MAD_PASS(CGSizeEqualToSize(options.layoutSize, CGSizeZero), "the default layout size is zero");
	MAD_PASS(UIEdgeInsetsEqualToEdgeInsets(options.margins, UIEdgeInsetsZero), "the default margins are zero");

	[options release];
}

static void testGeometryRoundTrips(void) {
	MADPageOptions *options = [[MADPageOptions alloc] init];

	options.layoutSize = CGSizeMake(612.0, 792.0);
	options.margins = UIEdgeInsetsMake(36.0, 36.0, 54.0, 54.0);

	MAD_PASS(CGSizeEqualToSize(options.layoutSize, CGSizeMake(612.0, 792.0)), "the layout size round-trips");
	MAD_PASS(UIEdgeInsetsEqualToEdgeInsets(options.margins, UIEdgeInsetsMake(36.0, 36.0, 54.0, 54.0)), "the margins round-trip");

	[options release];
}

MAD_TEST_MAIN("MADPageOptionsTests",
	MAD_TEST(testDefaultsAreZeroGeometry),
	MAD_TEST(testGeometryRoundTrips));
