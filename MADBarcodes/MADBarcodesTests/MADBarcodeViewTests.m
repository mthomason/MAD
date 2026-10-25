//
//  MADBarcodeViewTests.m
//  MADBarcodesTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADBarcodeView is deliberately thin: its only two constructors are
//  -initWithFrame: (which asserts "Don't you dare!" -- the view is meant to come from
//  a storyboard, where the barcode is injected) and -initWithCoder: (nib loading,
//  which a logic-test bundle has no nib for).  UIView's -init forwards to
//  -initWithFrame:, so the assertion blocks every programmatic path.
//
//  What is pinned is that contract, plus the barcode property's declared storage
//  read from the runtime (there is no instance to ask).
//
//  MADBarcodeView.m is the one file in the framework compiled -fno-objc-arc.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "MADBarcodeView.h"
#import "MADBarcode.h"
#import "MADBarcodeCode39Iso16388.h"

@interface MADBarcodeViewTests : XCTestCase
@end

@implementation MADBarcodeViewTests

- (void)testProgrammaticConstructionIsRefused {
	XCTAssertThrows(([[MADBarcodeView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]));
}

- (void)testBarcodePropertyIsAnInstanceOfMADBarcode {
	objc_property_t property = class_getProperty([MADBarcodeView class], "barcode");

	XCTAssertTrue(property != NULL, @"the view must expose a barcode property");
	const char *attributes = property_getAttributes(property);
	XCTAssertTrue(strstr(attributes, "T@\"MADBarcode\"") != NULL, @"declared as MADBarcode *");
	// '&' is the retain/strong encoding; MADBarcodeView.m is MRC and releases it in dealloc.
	XCTAssertTrue(strstr(attributes, "&") != NULL, @"declared retain");
}

@end
