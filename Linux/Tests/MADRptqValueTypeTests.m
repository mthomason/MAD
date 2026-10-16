//
//  MADRptqValueTypeTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADRptqValueTypeTests.m: the small Rptq* value
//  types that back document element geometry and styling -- key-path constants,
//  the RptqRect/RptqBorder composition awakeFromInsert builds, and the scalar
//  properties.  The store the Xcode suite borrows from Core Data is a real
//  SQLite file under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <CoreGraphics/CGGeometry.h>

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
#import <MAD/RptqPoint+Extras.h>
#import <MAD/RptqSize+Extras.h>
#import <MAD/RptqBorder+Extras.h>
#import <MAD/RptqDirectionalAsymmetry+Extras.h>
#import <MAD/RptqDirectionalProperty+Extras.h>

#pragma mark - Helpers

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	// Testing.h's pass() carries a printf format, so the error object cannot be
	// printed with %@; the check is the same one the Xcode helper made.
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

static id insertEntityNamed(NSString *name, RptqStoreContext *context) {
	return [context insertObjectForEntity:name identifier:0];
}

#pragma mark - Key-path constants

static void testPointKeyConstants(void) {
	MAD_PASS_EQUAL([RptqPoint keyX], @"x", "the x key");
	MAD_PASS_EQUAL([RptqPoint keyY], @"y", "the y key");
}

static void testSizeKeyConstants(void) {
	MAD_PASS_EQUAL([RptqSize keyWidth], @"width", "the width key");
	MAD_PASS_EQUAL([RptqSize keyHeight], @"height", "the height key");
}

static void testRectKeyConstants(void) {
	MAD_PASS_EQUAL([RptqRect keyOrigin], @"origin", "the origin key");
	MAD_PASS_EQUAL([RptqRect keySize], @"size", "the size key");
}

static void testBorderKeyConstants(void) {
	MAD_PASS_EQUAL([RptqBorder keyWidth], @"width", "the border width key");
	MAD_PASS_EQUAL([RptqBorder keyStyle], @"style", "the border style key");
}

static void testDirectionalPropertyKeyConstants(void) {
	MAD_PASS_EQUAL([RptqDirectionalProperty keyTop], @"top", "the top key");
	MAD_PASS_EQUAL([RptqDirectionalProperty keyBottom], @"bottom", "the bottom key");
	MAD_PASS_EQUAL([RptqDirectionalProperty keyLeft], @"left", "the left key");
	MAD_PASS_EQUAL([RptqDirectionalProperty keyRight], @"right", "the right key");
}

static void testDirectionalAsymmetryKeyConstants(void) {
	MAD_PASS_EQUAL([RptqDirectionalAsymmetry keyTop], @"top", "the asymmetry top key");
	MAD_PASS_EQUAL([RptqDirectionalAsymmetry keyBottom], @"bottom", "the asymmetry bottom key");
	MAD_PASS_EQUAL([RptqDirectionalAsymmetry keyLeft], @"left", "the asymmetry left key");
	MAD_PASS_EQUAL([RptqDirectionalAsymmetry keyRight], @"right", "the asymmetry right key");
}

#pragma mark - RptqRect frame composition

static void testRectAwakeFromInsertCreatesOriginAndSize(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqRect *rect = insertEntityNamed(@"RptqRect", context);

	MAD_PASS(rect.origin != nil, "the insert creates an origin");
	MAD_PASS(rect.size != nil, "the insert creates a size");
	MAD_PASS([rect.origin isKindOfClass:[RptqPoint class]], "the origin is an RptqPoint");
	MAD_PASS([rect.size isKindOfClass:[RptqSize class]], "the size is an RptqSize");
}

static void testRectFrameComposition(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqRect *rect = insertEntityNamed(@"RptqRect", context);

	rect.origin.x = 1.5f;
	rect.origin.y = 2.5f;
	rect.size.width = 3.5f;
	rect.size.height = 4.5f;

	CGRect frame = [rect frame];
	MAD_PASS(frame.origin.x == 1.5f, "the frame origin x");
	MAD_PASS(frame.origin.y == 2.5f, "the frame origin y");
	MAD_PASS(frame.size.width == 3.5f, "the frame width");
	MAD_PASS(frame.size.height == 4.5f, "the frame height");
}

#pragma mark - RptqBorder composition

static void testBorderAwakeFromInsertCreatesWidthAndStyle(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqBorder *border = insertEntityNamed(@"RptqBorder", context);

	MAD_PASS(border.width != nil, "the insert creates a width");
	MAD_PASS(border.style != nil, "the insert creates a style");
	MAD_PASS([border.width isKindOfClass:[RptqDirectionalAsymmetry class]], "the width is a directional asymmetry");
	MAD_PASS([border.style isKindOfClass:[RptqDirectionalProperty class]], "the style is a directional property");
}

#pragma mark - Scalar property value types

static void testAlignmentProperties(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqAlignment *alignment = insertEntityNamed(@"RptqAlignment", context);

	alignment.horizontal = 1;
	alignment.vertical = 2;
	MAD_PASS(alignment.horizontal == (int16_t)1, "the horizontal alignment round-trips");
	MAD_PASS(alignment.vertical == (int16_t)2, "the vertical alignment round-trips");
}

static void testTextStyleProperties(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqTextStyle *style = insertEntityNamed(@"RptqTextStyle", context);

	style.bold = YES;
	style.italic = YES;
	style.underline = NO;
	style.strikethrough = YES;

	MAD_PASS(style.bold, "bold round-trips");
	MAD_PASS(style.italic, "italic round-trips");
	MAD_PASS(!style.underline, "underline round-trips");
	MAD_PASS(style.strikethrough, "strikethrough round-trips");
}

static void testNumericFormatProperties(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqNumericFormat *format = insertEntityNamed(@"RptqNumericFormat", context);

	format.enabled = YES;
	format.decimalCount = 4;
	format.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];

	MAD_PASS(format.enabled, "the numeric format enables");
	MAD_PASS(format.decimalCount == (int64_t)4, "the decimal count round-trips");
	MAD_PASS_EQUAL(format.locale.localeIdentifier, @"en_GB", "the locale round-trips");
}

static void testDirectionalPropertyScalars(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDirectionalProperty *property = insertEntityNamed(@"RptqDirectionalProperty", context);

	property.top = 1;
	property.bottom = 2;
	property.left = 3;
	property.right = 4;

	MAD_PASS(property.top == (int16_t)1, "the top round-trips");
	MAD_PASS(property.bottom == (int16_t)2, "the bottom round-trips");
	MAD_PASS(property.left == (int16_t)3, "the left round-trips");
	MAD_PASS(property.right == (int16_t)4, "the right round-trips");
}

static void testDirectionalAsymmetryScalars(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDirectionalAsymmetry *asymmetry = insertEntityNamed(@"RptqDirectionalAsymmetry", context);

	asymmetry.top = 1.5f;
	asymmetry.bottom = 2.5f;
	asymmetry.left = 3.5f;
	asymmetry.right = 4.5f;

	MAD_PASS(asymmetry.top == 1.5f, "the asymmetry top round-trips");
	MAD_PASS(asymmetry.bottom == 2.5f, "the asymmetry bottom round-trips");
	MAD_PASS(asymmetry.left == 3.5f, "the asymmetry left round-trips");
	MAD_PASS(asymmetry.right == 4.5f, "the asymmetry right round-trips");
}

MAD_TEST_MAIN("MADRptqValueTypeTests",
	MAD_TEST(testPointKeyConstants),
	MAD_TEST(testSizeKeyConstants),
	MAD_TEST(testRectKeyConstants),
	MAD_TEST(testBorderKeyConstants),
	MAD_TEST(testDirectionalPropertyKeyConstants),
	MAD_TEST(testDirectionalAsymmetryKeyConstants),
	MAD_TEST(testRectAwakeFromInsertCreatesOriginAndSize),
	MAD_TEST(testRectFrameComposition),
	MAD_TEST(testBorderAwakeFromInsertCreatesWidthAndStyle),
	MAD_TEST(testAlignmentProperties),
	MAD_TEST(testTextStyleProperties),
	MAD_TEST(testNumericFormatProperties),
	MAD_TEST(testDirectionalPropertyScalars),
	MAD_TEST(testDirectionalAsymmetryScalars));
