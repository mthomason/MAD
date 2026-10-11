//
//  MTBarcodeViewTests.m
//  MADBarcodesTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MTBarcodeView is deliberately thin: its only two constructors are
//  -initWithFrame: (which asserts "Don't you dare!" -- the view is meant to come from
//  a storyboard, where the barcode is injected) and -initWithCoder: (nib loading,
//  which a logic-test bundle has no nib for).  UIView's -init forwards to
//  -initWithFrame:, so the assertion blocks every programmatic path.
//
//  What is pinned is that contract, plus the barcode property's declared storage
//  read from the runtime (there is no instance to ask).
//
//  MTBarcodeView.m is the one file in the framework compiled -fno-objc-arc.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "MTBarcodeView.h"
#import "MTBarcode.h"
#import "MTBarcodeCode39Iso16388.h"

@interface MTBarcodeViewTests : XCTestCase
@end

@implementation MTBarcodeViewTests

- (void)testProgrammaticConstructionIsRefused {
	XCTAssertThrows(([[MTBarcodeView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]));
}

- (void)testBarcodePropertyIsAnInstanceOfMTBarcode {
	objc_property_t property = class_getProperty([MTBarcodeView class], "barcode");

	XCTAssertTrue(property != NULL, @"the view must expose a barcode property");
	const char *attributes = property_getAttributes(property);
	XCTAssertTrue(strstr(attributes, "T@\"MTBarcode\"") != NULL, @"declared as MTBarcode *");
	// '&' is the retain/strong encoding; MTBarcodeView.m is MRC and releases it in dealloc.
	XCTAssertTrue(strstr(attributes, "&") != NULL, @"declared retain");
}

@end
