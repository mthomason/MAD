//
//  MADLabelTitleTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADLabelTitle: the two-tone navigation title.  The attributed-string
//  builder is a pure class method (undeclared in the header; reached through a
//  test-only bridge) and carries most of the behaviour; the view half wraps a UILabel
//  and is exercised through -setText:.
//

#import <XCTest/XCTest.h>

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIFont.h>
#import <UIKit/UILabel.h>

#import <MADCocoaExtensions/MADLabelTitle.h>

// -logoAttributedStringForTitle: is implemented on the class but declared in no
// header; this test-only category is the deliberate bridge.
@interface MADLabelTitle (TestTitle)
+ (NSAttributedString *)logoAttributedStringForTitle:(NSString *)title;
@end

@interface MADLabelTitleTests : XCTestCase
@end

@implementation MADLabelTitleTests

#pragma mark - Attributed title

- (void)testNilTitleGivesAnEmptyAttributedString {
	NSAttributedString *attributed = [MADLabelTitle logoAttributedStringForTitle:nil];

	XCTAssertEqual(attributed.length, (NSUInteger)0);
}

- (void)testEmptyTitleGivesAnEmptyAttributedString {
	NSAttributedString *attributed = [MADLabelTitle logoAttributedStringForTitle:@""];

	XCTAssertEqual(attributed.length, (NSUInteger)0);
}

- (void)testSingleWordCarriesTheCommonAttributes {
	NSAttributedString *attributed = [MADLabelTitle logoAttributedStringForTitle:@"Report"];

	XCTAssertEqual(attributed.length, (NSUInteger)6);
	XCTAssertEqualObjects([attributed attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
						  [UIColor labelColor]);
	XCTAssertEqualObjects([attributed attribute:NSKernAttributeName atIndex:0 effectiveRange:NULL], [NSNull null]);

	NSParagraphStyle *paragraph = [attributed attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
	XCTAssertNotNil(paragraph);
	XCTAssertEqual(paragraph.alignment, NSTextAlignmentNatural);
	XCTAssertNotNil([attributed attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL]);
}

- (void)testTwoWordsUseDifferentFontsForTheFirstAndSecondWord {
	NSAttributedString *attributed = [MADLabelTitle logoAttributedStringForTitle:@"MAD Designer"];
	XCTAssertEqual(attributed.length, (NSUInteger)12);

	UIFont *first = [attributed attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	UIFont *second = [attributed attribute:NSFontAttributeName atIndex:4 effectiveRange:NULL];

	XCTAssertNotNil(first);
	XCTAssertNotNil(second);
	// The first word is set light, the second bold, so the fonts differ.
	XCTAssertFalse([first isEqual:second]);
}

#pragma mark - View

- (void)testInitWithFrameWrapsALabel {
	MADLabelTitle *title = [[MADLabelTitle alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];

	XCTAssertEqual(title.subviews.count, (NSUInteger)1);
	XCTAssertTrue([title.subviews.firstObject isKindOfClass:[UILabel class]]);
}

- (void)testSetTextRoundTripsThroughTheLabel {
	MADLabelTitle *title = [[MADLabelTitle alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];

	[title setText:@"MAD Designer"];

	XCTAssertEqualObjects(title.text, @"MAD Designer");
	// The attributed string lands on the wrapped label.
	UILabel *label = title.subviews.firstObject;
	XCTAssertEqualObjects(label.attributedText.string, @"MAD Designer");
}

- (void)testIntrinsicContentSizeIsExpanded {
	MADLabelTitle *title = [[MADLabelTitle alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];

	XCTAssertTrue(CGSizeEqualToSize(title.intrinsicContentSize, UILayoutFittingExpandedSize));
}

@end
