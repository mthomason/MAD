//
//  MADFontsTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADFonts: the font family list the style inspector
//  offers.  An instance snapshots UIFont's family names sorted case-insensitively, so the
//  list is non-empty, complete, and not in descending order.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIFont.h>

#import "MADFonts.h"

@interface MADFontsTests : XCTestCase
@end

@implementation MADFontsTests

- (void)testFamilyNamesSnapshotTheSystemFamilies {
	MADFonts *fonts = [[MADFonts alloc] init];

	XCTAssertNotNil(fonts.familyNames);
	XCTAssertGreaterThan(fonts.familyNames.count, (NSUInteger)0);
	XCTAssertEqual(fonts.familyNames.count, [UIFont familyNames].count);
	for (NSString *familyName in fonts.familyNames) {
		XCTAssertTrue([[UIFont familyNames] containsObject:familyName], @"unexpected family %@", familyName);
	}
}

- (void)testFamilyNamesAreSortedCaseInsensitively {
	MADFonts *fonts = [[MADFonts alloc] init];
	NSArray<NSString *> *names = fonts.familyNames;

	for (NSUInteger index = 1; index < names.count; index++) {
		XCTAssertNotEqual([names[index - 1] caseInsensitiveCompare:names[index]],
						  NSOrderedDescending,
						  @"%@ should not sort after %@", names[index - 1], names[index]);
	}
}

@end
