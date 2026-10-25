//
//  MTPaperTests.m
//  MAD
//
//  Created by Michael Thomason on 10/4/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>

#import <MAD/MTPaper.h>

// The conversions MTPaper.m uses.  fCGPointsForInches and
// CGFloatPointsForMillimeters are static inline in MADCocoaExtensions and not
// visible here, so the expectations repeat the two one-line formulas to agree
// with the implementation to the last bit.
static inline CGFloat TestPointsForInches(CGFloat inches) { return inches * 72.00000f; }

static inline CGFloat TestPointsForMillimeters(CGFloat millimeters) { return millimeters * 0.0393701f * 72.0; }

@interface MTPaperTests : XCTestCase

@end

@implementation MTPaperTests

- (void)testEveryKnownTypeBuildsItsPaperAndSize {
	typedef struct {
		MTPaperType paperType;
		CGSize size;
	} PaperCase;

	PaperCase cases[] = {
		{ MTPaperTypeLetter, CGSizeMake(TestPointsForInches(8.5000f), TestPointsForInches(11.0000f)) },
		{ MTPaperTypeGovernmentLetter, CGSizeMake(TestPointsForInches(8.5000f), TestPointsForInches(10.5000f)) },
		// Government legal prints at legal size, and always has.
		{ MTPaperTypeGovernmentLegal, CGSizeMake(TestPointsForInches(8.5000f), TestPointsForInches(14.0000f)) },
		{ MTPaperTypeLegal, CGSizeMake(TestPointsForInches(8.5000f), TestPointsForInches(14.0000f)) },
		{ MTPaperTypeA0, CGSizeMake(TestPointsForMillimeters(841.0000f), TestPointsForMillimeters(1189.0000f)) },
		{ MTPaperTypeA1, CGSizeMake(TestPointsForMillimeters(594.0000f), TestPointsForMillimeters(841.0000f)) },
		{ MTPaperTypeA2, CGSizeMake(TestPointsForMillimeters(420.0000f), TestPointsForMillimeters(594.0000f)) },
		{ MTPaperTypeA3, CGSizeMake(TestPointsForMillimeters(297.0000f), TestPointsForMillimeters(420.0000f)) },
		{ MTPaperTypeA4, CGSizeMake(TestPointsForMillimeters(210.0000f), TestPointsForMillimeters(297.0000f)) },
		{ MTPaperTypeA5, CGSizeMake(TestPointsForMillimeters(148.0000f), TestPointsForMillimeters(210.0000f)) },
		{ MTPaperTypeA6, CGSizeMake(TestPointsForMillimeters(105.0000f), TestPointsForMillimeters(148.0000f)) },
		{ MTPaperTypeA7, CGSizeMake(TestPointsForMillimeters(74.0000f), TestPointsForMillimeters(105.0000f)) },
		{ MTPaperTypeA8, CGSizeMake(TestPointsForMillimeters(52.0000f), TestPointsForMillimeters(74.0000f)) },
		{ MTPaperTypeA9, CGSizeMake(TestPointsForMillimeters(37.0000f), TestPointsForMillimeters(52.0000f)) },
		{ MTPaperTypeA10, CGSizeMake(TestPointsForMillimeters(26.0000f), TestPointsForMillimeters(37.0000f)) },
		{ MTPaperTypeB0, CGSizeMake(TestPointsForMillimeters(1000.0000f), TestPointsForMillimeters(1414.0000f)) },
		{ MTPaperTypeB1, CGSizeMake(TestPointsForMillimeters(707.0000f), TestPointsForMillimeters(1000.0000f)) },
		{ MTPaperTypeB2, CGSizeMake(TestPointsForMillimeters(500.0000f), TestPointsForMillimeters(707.0000f)) },
		{ MTPaperTypeB3, CGSizeMake(TestPointsForMillimeters(353.0000f), TestPointsForMillimeters(500.0000f)) },
		{ MTPaperTypeB4, CGSizeMake(TestPointsForMillimeters(250.0000f), TestPointsForMillimeters(353.0000f)) },
		{ MTPaperTypeB5, CGSizeMake(TestPointsForMillimeters(176.0000f), TestPointsForMillimeters(250.0000f)) },
		{ MTPaperTypeB6, CGSizeMake(TestPointsForMillimeters(125.0000f), TestPointsForMillimeters(176.0000f)) },
		{ MTPaperTypeB7, CGSizeMake(TestPointsForMillimeters(88.0000f), TestPointsForMillimeters(125.0000f)) },
		{ MTPaperTypeB8, CGSizeMake(TestPointsForMillimeters(62.0000f), TestPointsForMillimeters(88.0000f)) },
		{ MTPaperTypeB9, CGSizeMake(TestPointsForMillimeters(44.0000f), TestPointsForMillimeters(62.0000f)) },
		{ MTPaperTypeB10, CGSizeMake(TestPointsForMillimeters(31.0000f), TestPointsForMillimeters(44.0000f)) },
		{ MTPaperTypeC0, CGSizeMake(TestPointsForMillimeters(917.0000f), TestPointsForMillimeters(1297.0000f)) },
		{ MTPaperTypeC1, CGSizeMake(TestPointsForMillimeters(648.0000f), TestPointsForMillimeters(917.0000f)) },
		{ MTPaperTypeC2, CGSizeMake(TestPointsForMillimeters(458.0000f), TestPointsForMillimeters(648.0000f)) },
		{ MTPaperTypeC3, CGSizeMake(TestPointsForMillimeters(324.0000f), TestPointsForMillimeters(458.0000f)) },
		{ MTPaperTypeC4, CGSizeMake(TestPointsForMillimeters(229.0000f), TestPointsForMillimeters(324.0000f)) },
		{ MTPaperTypeC5, CGSizeMake(TestPointsForMillimeters(162.0000f), TestPointsForMillimeters(229.0000f)) },
		{ MTPaperTypeC6, CGSizeMake(TestPointsForMillimeters(114.0000f), TestPointsForMillimeters(162.0000f)) },
		{ MTPaperTypeC7, CGSizeMake(TestPointsForMillimeters(81.0000f), TestPointsForMillimeters(114.0000f)) },
		{ MTPaperTypeC8, CGSizeMake(TestPointsForMillimeters(57.0000f), TestPointsForMillimeters(81.0000f)) },
		{ MTPaperTypeC9, CGSizeMake(TestPointsForMillimeters(40.0000f), TestPointsForMillimeters(57.0000f)) },
		{ MTPaperTypeC10, CGSizeMake(TestPointsForMillimeters(28.0000f), TestPointsForMillimeters(40.0000f)) },
	};

	for (NSUInteger i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
		PaperCase paperCase = cases[i];
		MTPaper *paper = [[MTPaper alloc] initWithType: paperCase.paperType];
		CGSize sizeForType = [MTPaper sizeForType: paperCase.paperType];

		XCTAssertEqual(paper.paperType, paperCase.paperType,
					   @"paper type %d does not round-trip", paperCase.paperType);
		XCTAssertTrue(CGSizeEqualToSize(paper.paperSize, paperCase.size),
					  @"paper type %d answers the wrong size", paperCase.paperType);
		XCTAssertTrue(CGSizeEqualToSize(sizeForType, paperCase.size),
					  @"sizeForType: disagrees for paper type %d", paperCase.paperType);
		XCTAssertEqual(paper.bounds.origin.x, 0.0, @"bounds origin is not zero");
		XCTAssertEqual(paper.bounds.origin.y, 0.0, @"bounds origin is not zero");
		XCTAssertTrue(CGSizeEqualToSize(paper.bounds.size, paperCase.size),
					  @"bounds does not match the size for paper type %d", paperCase.paperType);
	}
}

- (void)testUnknownTypeFallsBackToLetter {
	MTPaper *paper = [[MTPaper alloc] initWithType: 9999];
	CGSize letter = [MTPaper sizeForType: MTPaperTypeLetter];

	XCTAssertEqual(paper.paperType, MTPaperTypeLetter);
	XCTAssertTrue(CGSizeEqualToSize(paper.paperSize, letter));
	XCTAssertTrue(CGSizeEqualToSize([MTPaper sizeForType: 9999], letter));
}

- (void)testInitDefaultsToLetter {
	MTPaper *paper = [[MTPaper alloc] init];
	CGSize letter = [MTPaper sizeForType: MTPaperTypeLetter];
	CGSize expected = CGSizeMake(TestPointsForInches(8.5000f), TestPointsForInches(11.0000f));

	XCTAssertEqual(paper.paperType, MTPaperTypeLetter);
	XCTAssertTrue(CGSizeEqualToSize(paper.paperSize, letter));
	XCTAssertTrue(CGSizeEqualToSize(letter, expected));
}

@end
