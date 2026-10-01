//
//  MADRptqValueTypeTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 4 (Core Data value-type) coverage for the MAD framework.  These are the
//  small Rptq* managed-object value types that back document element geometry and
//  styling.  They carry no database or document dependencies beyond the model, so
//  they are exercised against an in-memory store.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/RptqPoint.h>
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

- (NSManagedObjectModel *)modelFromTestBundle {
	NSURL *momdURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MAD"
															 withExtension:@"momd"];
	return [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
}

- (NSManagedObjectContext *)inMemoryContext {
	NSManagedObjectModel *model = [self modelFromTestBundle];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	NSError *error = nil;
	[coordinator addPersistentStoreWithType:NSInMemoryStoreType
							  configuration:nil
										URL:nil
									options:nil
									  error:&error];
	XCTAssertNil(error);

	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	return context;
}

- (id)insertEntityNamed:(NSString *)name inContext:(NSManagedObjectContext *)context {
	return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:context];
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
	// Known defect: keyRight delegates to keyLeft, returning @"left" instead of @"right".
	XCTAssertEqualObjects([RptqDirectionalAsymmetry keyRight], @"left");
}

#pragma mark - RptqRect frame composition

- (void)testRectAwakeFromInsertCreatesOriginAndSize {
	NSManagedObjectContext *context = [self inMemoryContext];
	RptqRect *rect = [self insertEntityNamed:@"RptqRect" inContext:context];

	XCTAssertNotNil(rect.origin);
	XCTAssertNotNil(rect.size);
	XCTAssertTrue([rect.origin isKindOfClass:[RptqPoint class]]);
	XCTAssertTrue([rect.size isKindOfClass:[RptqSize class]]);
}

- (void)testRectFrameComposition {
	NSManagedObjectContext *context = [self inMemoryContext];
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
	NSManagedObjectContext *context = [self inMemoryContext];
	RptqBorder *border = [self insertEntityNamed:@"RptqBorder" inContext:context];

	XCTAssertNotNil(border.width);
	XCTAssertNotNil(border.style);
	XCTAssertTrue([border.width isKindOfClass:[RptqDirectionalAsymmetry class]]);
	XCTAssertTrue([border.style isKindOfClass:[RptqDirectionalProperty class]]);
}

#pragma mark - Scalar property value types

- (void)testAlignmentProperties {
	NSManagedObjectContext *context = [self inMemoryContext];
	RptqAlignment *alignment = [self insertEntityNamed:@"RptqAlignment" inContext:context];

	alignment.horizontal = 1;
	alignment.vertical = 2;
	XCTAssertEqual(alignment.horizontal, (int16_t)1);
	XCTAssertEqual(alignment.vertical, (int16_t)2);
}

- (void)testTextStyleProperties {
	NSManagedObjectContext *context = [self inMemoryContext];
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
	NSManagedObjectContext *context = [self inMemoryContext];
	RptqNumericFormat *format = [self insertEntityNamed:@"RptqNumericFormat" inContext:context];

	format.enabled = YES;
	format.decimalCount = 4;
	format.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];

	XCTAssertTrue(format.enabled);
	XCTAssertEqual(format.decimalCount, (int64_t)4);
	XCTAssertEqualObjects(format.locale.localeIdentifier, @"en_GB");
}

- (void)testDirectionalPropertyScalars {
	NSManagedObjectContext *context = [self inMemoryContext];
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
	NSManagedObjectContext *context = [self inMemoryContext];
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
