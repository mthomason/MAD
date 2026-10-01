//
//  MADTextStyleTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADTextStyle: init, property accessors, NSCoding round-trip.
//  Documents the defect where the initializer scrambles the italic/underline/
//  strikethrough arguments.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/MADTextStyle.h>

@interface MADTextStyleTests : XCTestCase
@end

@implementation MADTextStyleTests

- (void)testInitScramblesFlags {
	// Defect: initWithBold:italic:underline:strikethrough: passes its arguments
	// as (bold, strikethrough, italic, underline), so the last three flags land in
	// the wrong properties.
	MADTextStyle *style = [[MADTextStyle alloc] initWithBold:YES italic:YES underline:NO strikethrough:NO];
	XCTAssertTrue(style.bold);
	XCTAssertFalse(style.italic);      // expected YES
	XCTAssertTrue(style.underline);    // expected NO
	XCTAssertFalse(style.strikethrough);
}

- (void)testSettersAreCorrect {
	// The individual setters map correctly; only the initializer is broken.
	MADTextStyle *style = [[MADTextStyle alloc] init];
	style.bold = YES;
	style.italic = YES;
	style.underline = NO;
	style.strikethrough = YES;
	XCTAssertTrue(style.bold);
	XCTAssertTrue(style.italic);
	XCTAssertFalse(style.underline);
	XCTAssertTrue(style.strikethrough);
}

- (void)testCodingRoundTrip {
	MADTextStyle *style = [[MADTextStyle alloc] init];
	style.bold = YES;
	style.italic = YES;
	style.underline = YES;
	style.strikethrough = YES;

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:style requiringSecureCoding:NO error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(data);

	MADTextStyle *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(decoded);
	XCTAssertTrue(decoded.bold);
	XCTAssertTrue(decoded.italic);
	XCTAssertTrue(decoded.underline);
	XCTAssertTrue(decoded.strikethrough);
}

@end
