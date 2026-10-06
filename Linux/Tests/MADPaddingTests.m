//
//  MADPaddingTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADPaddingTests.m: init, property
//  accessors, the NSCoding round trip and NSCopying independence.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MADPadding.h>

static void testInitDefaults(void) {
	MADPadding *padding = [[MADPadding alloc] init];
	MAD_PASS(padding.left == (Float64)0, "left defaults to zero");
	MAD_PASS(padding.right == (Float64)0, "right defaults to zero");
	MAD_PASS(padding.top == (Float64)0, "top defaults to zero");
	MAD_PASS(padding.bottom == (Float64)0, "bottom defaults to zero");
}

static void testInitWithEdges(void) {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1.5 right:2.5 top:3.5 bottom:4.5];
	MAD_PASS(padding.left == (Float64)1.5, "left comes back");
	MAD_PASS(padding.right == (Float64)2.5, "right comes back");
	MAD_PASS(padding.top == (Float64)3.5, "top comes back");
	MAD_PASS(padding.bottom == (Float64)4.5, "bottom comes back");
}

static void testSetters(void) {
	MADPadding *padding = [[MADPadding alloc] init];
	padding.left = 9;
	padding.right = 8;
	padding.top = 7;
	padding.bottom = 6;
	MAD_PASS(padding.left == (Float64)9, "left round trips");
	MAD_PASS(padding.right == (Float64)8, "right round trips");
	MAD_PASS(padding.top == (Float64)7, "top round trips");
	MAD_PASS(padding.bottom == (Float64)6, "bottom round trips");
}

static void testCopyIsIndependent(void) {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1 right:2 top:3 bottom:4];
	MADPadding *copy = [padding copy];
	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS(copy.left == padding.left, "the copy carries the value");

	copy.left = 99;
	MAD_PASS(copy.left == (Float64)99, "the copy takes the new value");
	MAD_PASS(padding.left == (Float64)1, "the original is unchanged");
}

static void testCodingRoundTrip(void) {
	MADPadding *padding = [[MADPadding alloc] initWithLeft:1.25 right:2.5 top:3.75 bottom:4.5];
	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:padding requiringSecureCoding:NO error:&error];
	MAD_PASS(error == nil, "no error from archiving");
	MAD_PASS(data != nil, "the archive has bytes");

	MADPadding *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
	MAD_PASS(error == nil, "no error from unarchiving");
	MAD_PASS(decoded != nil, "the padding round trips");
	MAD_PASS(decoded.left == (Float64)1.25, "left survives the round trip");
	MAD_PASS(decoded.right == (Float64)2.5, "right survives the round trip");
	MAD_PASS(decoded.top == (Float64)3.75, "top survives the round trip");
	MAD_PASS(decoded.bottom == (Float64)4.5, "bottom survives the round trip");
}

MAD_TEST_MAIN("MADPaddingTests",
	MAD_TEST(testInitDefaults),
	MAD_TEST(testInitWithEdges),
	MAD_TEST(testSetters),
	MAD_TEST(testCopyIsIndependent),
	MAD_TEST(testCodingRoundTrip));
