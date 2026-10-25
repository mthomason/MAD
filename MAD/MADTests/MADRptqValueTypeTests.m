//
//  MADRptqValueTypeTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 4 (Core Data value-type) coverage for the MAD framework.  These are the
//  small Rptq* managed-object value types that back document element geometry and
//  styling.  They carry no database or document dependencies beyond the model, so
//  they are exercised against an in-memory store.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/RptqPoint.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDirectionalProperty.h>

#import <MAD/RptqRect+Extras.h>
#import "RptqPoint+Extras.h"
#import "RptqSize+Extras.h"
#import "RptqBorder+Extras.h"
#import "RptqDirectionalAsymmetry+Extras.h"
#import "RptqDirectionalProperty+Extras.h"

@interface MADRptqValueTypeTests : XCTestCase
@end

@implementation MADRptqValueTypeTests

#pragma mark - Helpers

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (id)insertEntityNamed:(NSString *)name inContext:(RptqStoreContext *)context {
	return [context insertObjectForEntity:name identifier:0];
}

#pragma mark - Key-path constants

- (void)testPointKeyConstants {
	XCTAssertEqualObjects([RptqPoint keyX], @"x");
	XCTAssertEqualObjects([RptqPoint keyY], @"y");
}

- (void)testSizeKeyConstants {
	XCTAssertEqualObjects([RptqSize keyWidth], @"width");
	XCTAssertEqualObjects([RptqSize keyHeight], @"height");
}

- (void)testRectKeyConstants {
	XCTAssertEqualObjects([RptqRect keyOrigin], @"origin");
	XCTAssertEqualObjects([RptqRect keySize], @"size");
}

- (void)testBorderKeyConstants {
	XCTAssertEqualObjects([RptqBorder keyWidth], @"width");
	XCTAssertEqualObjects([RptqBorder keyStyle], @"style");
}

- (void)testDirectionalPropertyKeyConstants {
	XCTAssertEqualObjects([RptqDirectionalProperty keyTop], @"top");
	XCTAssertEqualObjects([RptqDirectionalProperty keyBottom], @"bottom");
	XCTAssertEqualObjects([RptqDirectionalProperty keyLeft], @"left");
	XCTAssertEqualObjects([RptqDirectionalProperty keyRight], @"right");
}

- (void)testDirectionalAsymmetryKeyConstants {
	XCTAssertEqualObjects([RptqDirectionalAsymmetry keyTop], @"top");
	XCTAssertEqualObjects([RptqDirectionalAsymmetry keyBottom], @"bottom");
	XCTAssertEqualObjects([RptqDirectionalAsymmetry keyLeft], @"left");
	XCTAssertEqualObjects([RptqDirectionalAsymmetry keyRight], @"right");
}

#pragma mark - RptqRect frame composition

- (void)testRectAwakeFromInsertCreatesOriginAndSize {
	RptqStoreContext *context = [self inMemoryContext];
	RptqRect *rect = [self insertEntityNamed:@"RptqRect" inContext:context];

	XCTAssertNotNil(rect.origin);
	XCTAssertNotNil(rect.size);
	XCTAssertTrue([rect.origin isKindOfClass:[RptqPoint class]]);
	XCTAssertTrue([rect.size isKindOfClass:[RptqSize class]]);
}

- (void)testRectFrameComposition {
	RptqStoreContext *context = [self inMemoryContext];
	RptqRect *rect = [self insertEntityNamed:@"RptqRect" inContext:context];

	rect.origin.x = 1.5f;
	rect.origin.y = 2.5f;
	rect.size.width = 3.5f;
	rect.size.height = 4.5f;

	CGRect frame = [rect frame];
	XCTAssertEqual(frame.origin.x, 1.5f);
	XCTAssertEqual(frame.origin.y, 2.5f);
	XCTAssertEqual(frame.size.width, 3.5f);
	XCTAssertEqual(frame.size.height, 4.5f);
}

#pragma mark - RptqBorder composition

- (void)testBorderAwakeFromInsertCreatesWidthAndStyle {
	RptqStoreContext *context = [self inMemoryContext];
	RptqBorder *border = [self insertEntityNamed:@"RptqBorder" inContext:context];

	XCTAssertNotNil(border.width);
	XCTAssertNotNil(border.style);
	XCTAssertTrue([border.width isKindOfClass:[RptqDirectionalAsymmetry class]]);
	XCTAssertTrue([border.style isKindOfClass:[RptqDirectionalProperty class]]);
}

#pragma mark - Scalar property value types

- (void)testAlignmentProperties {
	RptqStoreContext *context = [self inMemoryContext];
	RptqAlignment *alignment = [self insertEntityNamed:@"RptqAlignment" inContext:context];

	alignment.horizontal = 1;
	alignment.vertical = 2;
	XCTAssertEqual(alignment.horizontal, (int16_t)1);
	XCTAssertEqual(alignment.vertical, (int16_t)2);
}

- (void)testTextStyleProperties {
	RptqStoreContext *context = [self inMemoryContext];
	RptqTextStyle *style = [self insertEntityNamed:@"RptqTextStyle" inContext:context];

	style.bold = YES;
	style.italic = YES;
	style.underline = NO;
	style.strikethrough = YES;

	XCTAssertTrue(style.bold);
	XCTAssertTrue(style.italic);
	XCTAssertFalse(style.underline);
	XCTAssertTrue(style.strikethrough);
}

- (void)testNumericFormatProperties {
	RptqStoreContext *context = [self inMemoryContext];
	RptqNumericFormat *format = [self insertEntityNamed:@"RptqNumericFormat" inContext:context];

	format.enabled = YES;
	format.decimalCount = 4;
	format.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];

	XCTAssertTrue(format.enabled);
	XCTAssertEqual(format.decimalCount, (int64_t)4);
	XCTAssertEqualObjects(format.locale.localeIdentifier, @"en_GB");
}

- (void)testDirectionalPropertyScalars {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDirectionalProperty *property = [self insertEntityNamed:@"RptqDirectionalProperty" inContext:context];

	property.top = 1;
	property.bottom = 2;
	property.left = 3;
	property.right = 4;

	XCTAssertEqual(property.top, (int16_t)1);
	XCTAssertEqual(property.bottom, (int16_t)2);
	XCTAssertEqual(property.left, (int16_t)3);
	XCTAssertEqual(property.right, (int16_t)4);
}

- (void)testDirectionalAsymmetryScalars {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDirectionalAsymmetry *asymmetry = [self insertEntityNamed:@"RptqDirectionalAsymmetry" inContext:context];

	asymmetry.top = 1.5f;
	asymmetry.bottom = 2.5f;
	asymmetry.left = 3.5f;
	asymmetry.right = 4.5f;

	XCTAssertEqual(asymmetry.top, 1.5f);
	XCTAssertEqual(asymmetry.bottom, 2.5f);
	XCTAssertEqual(asymmetry.left, 3.5f);
	XCTAssertEqual(asymmetry.right, 4.5f);
}

@end
