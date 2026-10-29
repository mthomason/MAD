//
//  MADActivityIndicatorLabelTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADActivityIndicatorLabel: the status label shown at
//  the bottom of MADActivityIndicator.  Its initialiser pins the placeholder text
//  ("Formatting report."), the light 11-point face, centring, and the autoresizing that
//  keeps it stretched across the panel while staying at the bottom.
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <XCTest/XCTest.h>
#import <UIKit/UILabel.h>

#import "MADActivityIndicatorLabel.h"

@interface MADActivityIndicatorLabelTests : XCTestCase
@end

@implementation MADActivityIndicatorLabelTests

- (void)testInitSetsFormattingPlaceholderStyling {
	MADActivityIndicatorLabel *label = [[MADActivityIndicatorLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];

	XCTAssertTrue([label isKindOfClass:[UILabel class]]);
	XCTAssertEqualObjects(label.text, @"Formatting report.");
	XCTAssertEqual(label.textAlignment, NSTextAlignmentCenter);
	XCTAssertEqualObjects(label.textColor, [UIColor lightTextColor]);
	XCTAssertNotNil(label.font);
	XCTAssertEqual(label.font.pointSize, 11.0);
	XCTAssertEqual(label.autoresizingMask,
				   (UIViewAutoresizing)(UIViewAutoresizingFlexibleBottomMargin |
										UIViewAutoresizingFlexibleWidth));
}

@end
#endif
