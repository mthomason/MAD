//
//  MADActivityIndicatorTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADActivityIndicator: the formatting panel's
//  initialiser wires a large UIActivityIndicatorView and a MADActivityIndicatorLabel
//  (the label spans the bottom 44 points), and moving the panel into and out of a
//  superview starts and stops the spinner.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <QuartzCore/CALayer.h>

#import "MADActivityIndicator.h"
#import "MADActivityIndicatorLabel.h"

// The spinner is held in a private class-extension property (weak, so the view
// hierarchy is what keeps it alive); this test-only category is the deliberate bridge.
@interface MADActivityIndicator (TestActivityIndicator)
- (UIActivityIndicatorView *)activityIndicator;
@end

@interface MADActivityIndicatorTests : XCTestCase
@end

@implementation MADActivityIndicatorTests

- (void)testInitWiresSpinnerAndStatus {
	CGRect frame = CGRectMake(0, 0, 230, 200);
	MADActivityIndicator *indicator = [[MADActivityIndicator alloc] initWithFrame:frame];

	XCTAssertEqual(indicator.subviews.count, (NSUInteger)2);
	XCTAssertEqual(indicator.layer.cornerRadius, 5.0);
	// The panel centres itself in whatever it is added to.
	XCTAssertEqual(indicator.autoresizingMask,
				   (UIViewAutoresizing)(UIViewAutoresizingFlexibleLeftMargin |
										UIViewAutoresizingFlexibleRightMargin |
										UIViewAutoresizingFlexibleTopMargin |
										UIViewAutoresizingFlexibleBottomMargin));

	UIActivityIndicatorView *spinner = [indicator activityIndicator];
	XCTAssertNotNil(spinner);
	XCTAssertTrue([indicator.subviews containsObject:spinner]);
	XCTAssertEqual(spinner.center.x, 115.0);
	XCTAssertEqual(spinner.center.y, 100.0);
	XCTAssertEqual(spinner.autoresizingMask,
				   (UIViewAutoresizing)(UIViewAutoresizingFlexibleLeftMargin |
										UIViewAutoresizingFlexibleRightMargin |
										UIViewAutoresizingFlexibleTopMargin));

	XCTAssertNotNil(indicator.status);
	XCTAssertTrue([indicator.status isKindOfClass:[MADActivityIndicatorLabel class]]);
	XCTAssertTrue([indicator.subviews containsObject:indicator.status]);
	CGRect expectedStatusFrame = CGRectMake(0, frame.size.height - 44.0, frame.size.width, 44.0);
	XCTAssertTrue(CGRectEqualToRect(indicator.status.frame, expectedStatusFrame));
}

- (void)testSpinnerRunsWhileThePanelHasASuperview {
	MADActivityIndicator *indicator = [[MADActivityIndicator alloc] initWithFrame:CGRectMake(0, 0, 230, 200)];
	UIView *superview = [[UIView alloc] initWithFrame:CGRectZero];
	UIActivityIndicatorView *spinner = [indicator activityIndicator];

	// Nothing is animating until the panel is placed somewhere.
	XCTAssertFalse(spinner.isAnimating);

	[indicator willMoveToSuperview:superview];
	XCTAssertTrue(spinner.isAnimating);

	[indicator willMoveToSuperview:nil];
	XCTAssertFalse(spinner.isAnimating);
}

@end
