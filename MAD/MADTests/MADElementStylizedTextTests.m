//
//  MADElementStylizedTextTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 2 coverage for MADElementStylizedText: the object that turns a font name,
//  size, RptqTextStyle and a horizontal alignment into the NSAttributedString
//  attribute dictionary used to draw a report element's text.
//
//  Pinned here: the five attributes the dictionary always carries, the font-traits
//  mapping for bold/italic, the underline/strikethrough mapping, the alignment
//  mapping (including the unknown value), and the nullable-font-name crash the
//  header's nullability promises cannot happen.  See BUGS.md.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIFont.h>
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>

#import <MAD/MADAlignment.h>

#import "MADElementStylizedText.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqTextStyle.h"

@interface MADElementStylizedTextTests : XCTestCase
@end

@implementation MADElementStylizedTextTests

#pragma mark - Fixture

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

- (MADElementStylizedText *)stylizedTextWithStyle:(RptqTextStyle *)style
										alignment:(MADHorizontalAlignment)alignment {
	return [[MADElementStylizedText alloc] initWithFontName:@"Helvetica"
												   fontSize:12.0
												  textStyle:style
										horizontalAlignment:alignment];
}

#pragma mark - Attribute dictionary

- (void)testAttributesWithNilTextStyle {
	MADElementStylizedText *stylized = [self stylizedTextWithStyle:nil alignment:MADHorizontalAlignmentLeft];
	NSDictionary *attributes = stylized.fontAttributes;

	XCTAssertEqual(attributes.count, (NSUInteger)5);
	XCTAssertNotNil(attributes[NSFontAttributeName]);
	XCTAssertEqualObjects(attributes[NSBaselineOffsetAttributeName], @0.0);
	XCTAssertEqualObjects(attributes[NSUnderlineStyleAttributeName], @(NSUnderlineStyleNone));
	XCTAssertEqualObjects(attributes[NSStrikethroughStyleAttributeName], @(NSUnderlineStyleNone));

	UIFont *font = attributes[NSFontAttributeName];
	XCTAssertEqual(font.pointSize, 12.0);
}

- (void)testBoldAndItalicTraits {
	RptqStoreContext *context = [self inMemoryContext];
	RptqTextStyle *style = [context insertObjectForEntity:@"RptqTextStyle" identifier:0];
	style.bold = YES;
	style.italic = YES;

	MADElementStylizedText *stylized = [self stylizedTextWithStyle:style alignment:MADHorizontalAlignmentLeft];
	UIFont *font = stylized.fontAttributes[NSFontAttributeName];
	UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;

	XCTAssertTrue((traits & UIFontDescriptorTraitBold) != 0);
	XCTAssertTrue((traits & UIFontDescriptorTraitItalic) != 0);
}

- (void)testUnderlineAndStrikethrough {
	RptqStoreContext *context = [self inMemoryContext];
	RptqTextStyle *style = [context insertObjectForEntity:@"RptqTextStyle" identifier:0];
	style.underline = YES;
	style.strikethrough = YES;

	MADElementStylizedText *stylized = [self stylizedTextWithStyle:style alignment:MADHorizontalAlignmentLeft];

	XCTAssertEqualObjects(stylized.fontAttributes[NSUnderlineStyleAttributeName], @(NSUnderlineStyleSingle));
	XCTAssertEqualObjects(stylized.fontAttributes[NSStrikethroughStyleAttributeName], @(NSUnderlineStyleSingle));
}

#pragma mark - Alignment mapping

- (void)testAlignmentMapping {
	NSDictionary<NSNumber *, NSNumber *> *expected = @{
		@(MADHorizontalAlignmentLeft): @(NSTextAlignmentLeft),
		@(MADHorizontalAlignmentRight): @(NSTextAlignmentRight),
		@(MADHorizontalAlignmentCenter): @(NSTextAlignmentCenter),
		@(MADHorizontalAlignmentJustified): @(NSTextAlignmentJustified),
		@(MADHorizontalAlignmentNatrual): @(NSTextAlignmentNatural),
		// Anything else -- including the unknown value -- falls back to left.
		@(MADHorizontalAlignmentUnknown): @(NSTextAlignmentLeft),
	};

	[expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *alignment, NSNumber *textAlignment, BOOL *stop) {
		MADElementStylizedText *stylized = [self stylizedTextWithStyle:nil
															alignment:(MADHorizontalAlignment)alignment.integerValue];
		NSParagraphStyle *paragraph = stylized.fontAttributes[NSParagraphStyleAttributeName];
		XCTAssertEqual(paragraph.alignment, (NSTextAlignment)textAlignment.integerValue);
		XCTAssertEqual(paragraph.lineBreakMode, NSLineBreakByTruncatingTail);
	}];
}

#pragma mark - Nullable font name

- (void)testNilFontNameThrows {
	// The initializer declares fontname nullable, but a nil family crashes when the
	// font descriptor dictionary is built.  Documented in BUGS.md.
	XCTAssertThrows(([[MADElementStylizedText alloc] initWithFontName:nil
															fontSize:12.0
														   textStyle:nil
												 horizontalAlignment:MADHorizontalAlignmentLeft]));
}

@end
