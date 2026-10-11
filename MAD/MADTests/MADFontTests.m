//
//  MADFontTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADFont: the two class-level defaults the designer's
//  style inspector starts from -- "Helvetica Neue" at 9 points.
//

#import <XCTest/XCTest.h>

#import "MADFont.h"

@interface MADFontTests : XCTestCase
@end

@implementation MADFontTests

- (void)testDefaultFamilyIsHelveticaNeue {
	XCTAssertEqualObjects([MADFont defaultFamily], @"Helvetica Neue");
}

- (void)testDefaultSizeIsNinePoints {
	XCTAssertEqual([MADFont defaultSize], 9.0f);
}

@end
