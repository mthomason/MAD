//
//  MADFontsTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADFonts: the font family list the style inspector
//  offers.  An instance snapshots UIFont's family names sorted case-insensitively, so the
//  list is non-empty, complete, and not in descending order.
//

#include <TargetConditionals.h>
#import <XCTest/XCTest.h>
#if TARGET_OS_OSX
#import <AppKit/NSFontManager.h>
#else
#import <UIKit/UIFont.h>
#endif

#import "MADFonts.h"

@interface MADFontsTests : XCTestCase
@end

@implementation MADFontsTests

- (void)testFamilyNamesSnapshotTheSystemFamilies {
	MADFonts *fonts = [[MADFonts alloc] init];
#if TARGET_OS_OSX
	NSArray<NSString *> *systemFamilies = [[NSFontManager sharedFontManager] availableFontFamilies];
#else
	NSArray<NSString *> *systemFamilies = [UIFont familyNames];
#endif

	XCTAssertNotNil(fonts.familyNames);
	XCTAssertGreaterThan(fonts.familyNames.count, (NSUInteger)0);
	XCTAssertEqual(fonts.familyNames.count, systemFamilies.count);
	for (NSString *familyName in fonts.familyNames) {
		XCTAssertTrue([systemFamilies containsObject:familyName], @"unexpected family %@", familyName);
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
