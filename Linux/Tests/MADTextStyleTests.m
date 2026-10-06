//
//  MADTextStyleTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADTextStyleTests.m: init, property
//  accessors and the NSCoding round trip.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MADTextStyle.h>

static void testInitFlagsLandInTheRightProperties(void) {
	MADTextStyle *style = [[MADTextStyle alloc] initWithBold:YES italic:YES underline:NO strikethrough:NO];
	MAD_PASS(style.bold, "bold is set");
	MAD_PASS(style.italic, "italic is set");
	MAD_PASS(!style.underline, "underline is not set");
	MAD_PASS(!style.strikethrough, "strikethrough is not set");
}

static void testSettersAreCorrect(void) {
	MADTextStyle *style = [[MADTextStyle alloc] init];
	style.bold = YES;
	style.italic = YES;
	style.underline = NO;
	style.strikethrough = YES;
	MAD_PASS(style.bold, "bold round trips");
	MAD_PASS(style.italic, "italic round trips");
	MAD_PASS(!style.underline, "underline round trips");
	MAD_PASS(style.strikethrough, "strikethrough round trips");
}

static void testCodingRoundTrip(void) {
	MADTextStyle *style = [[MADTextStyle alloc] init];
	style.bold = YES;
	style.italic = YES;
	style.underline = YES;
	style.strikethrough = YES;

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:style requiringSecureCoding:NO error:&error];
	MAD_PASS(error == nil, "no error from archiving");
	MAD_PASS(data != nil, "the archive has bytes");

	MADTextStyle *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	MAD_PASS(error == nil, "no error from unarchiving");
	MAD_PASS(decoded != nil, "the style round trips");
	MAD_PASS(decoded.bold, "bold survives the round trip");
	MAD_PASS(decoded.italic, "italic survives the round trip");
	MAD_PASS(decoded.underline, "underline survives the round trip");
	MAD_PASS(decoded.strikethrough, "strikethrough survives the round trip");
}

MAD_TEST_MAIN("MADTextStyleTests",
	MAD_TEST(testInitFlagsLandInTheRightProperties),
	MAD_TEST(testSettersAreCorrect),
	MAD_TEST(testCodingRoundTrip));
