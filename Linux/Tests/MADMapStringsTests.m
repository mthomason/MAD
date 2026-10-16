//
//  MADMapStringsTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MADMapStringsTests.m: the std::map
//  wrappers behind MADMapStrings -- set/overwrite/remove, the three key
//  types, the factory method and the boundary keys.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MADMapStrings.h>

static void testMapStrings(void) {
	MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
	MAD_PASS(map != nil, "the unsigned-integer map initializes");

	[map setObject:@"Three" toKey:3];
	[map setObject:@"Two Hundred" toKey:200];
	MAD_PASS([map count] == 2, "count reflects the added entries");

	[map setObject:[[[NSString alloc] initWithFormat:@"%@", @"Three hundred thirty three"] autorelease] toKey:333];
	[map setObject:[[[NSString alloc] initWithFormat:@"%@", @"Thirty"] autorelease] toKey:30];

	[map setObject:@"Thirty" toKey:30];
	[map setObject:@"Forty-Seven" toKey:47];
	[map setObject:[[[NSString alloc] initWithFormat:@"%@", @"Three hundred thirty three again"] autorelease] toKey:333];
	[map setObject:@"Eighty-Four" toKey:84];
	[map setObject:@"Four" toKey:4];

	[map setObject:nil toKey:48];
	[map setObject:nil toKey:200];
	[map setObject:nil toKey:3];
	[map setObject:nil toKey:47];
	MAD_PASS([map count] == 4, "count reflects the remaining entries");

	MAD_PASS_EQUAL([map objectAtIndex:333], @"Three hundred thirty three again", "key 333 holds the overwritten value");
	MAD_PASS_EQUAL([map objectAtIndex:30], @"Thirty", "key 30 holds the plain value");
	MAD_PASS([map objectAtIndex:200] == nil, "key 200 was removed");
	MAD_PASS([map objectAtIndex:48] == nil, "key 48 never existed");
	MAD_PASS([map objectAtIndex:UINT_MAX] == nil, "an out-of-bounds key is nil");

	[map setObject:@"BoundaryTest" toKey:UINT_MAX];
	MAD_PASS_EQUAL([map objectAtIndex:UINT_MAX], @"BoundaryTest", "the maximum unsigned key round trips");
}

static void testFactoryMethodCreatesCorrectSubclass(void) {
	MADMapStrings *shortMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeShort];
	MAD_PASS([shortMap isKindOfClass:[MADMapStringsShort class]], "the short type builds a short map");

	MADMapStrings *intMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeInteger];
	MAD_PASS([intMap isKindOfClass:[MADMapStringsInteger class]], "the integer type builds an integer map");

	MADMapStrings *uintMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeUnsignedInteger];
	MAD_PASS([uintMap isKindOfClass:[MADMapStringsUnsignedInteger class]], "the unsigned type builds an unsigned map");
}

static void testIntegerMap(void) {
	MADMapStringsInteger *map = [[MADMapStringsInteger alloc] init];
	[map setObject:@"Value1" toKey:1];
	[map setObject:@"Value2" toKey:2];
	MAD_PASS([map count] == 2, "two integer entries");
	MAD_PASS_EQUAL([map objectAtIndex:1], @"Value1", "key 1 round trips");
	MAD_PASS_EQUAL([map objectAtIndex:2], @"Value2", "key 2 round trips");

	[map setObject:nil toKey:1];
	MAD_PASS([map count] == 1, "setting nil removes the entry");
	MAD_PASS([map objectAtIndex:1] == nil, "the removed key is gone");
	MAD_PASS([map objectAtIndex:999] == nil, "a missing key is nil");
}

static void testShortMap(void) {
	MADMapStringsShort *map = [[MADMapStringsShort alloc] init];
	short key1 = 1;
	short key2 = 2;
	[map setObject:@"Value1" toKey:key1];
	[map setObject:@"Value2" toKey:key2];
	MAD_PASS([map count] == 2, "two short entries");
	MAD_PASS_EQUAL([map objectAtIndex:key1], @"Value1", "key 1 round trips");
	MAD_PASS_EQUAL([map objectAtIndex:key2], @"Value2", "key 2 round trips");

	[map setObject:nil toKey:key1];
	MAD_PASS([map count] == 1, "setting nil removes the entry");
}

static void testUnsignedIntegerMap(void) {
	MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
	NSUInteger key1 = 1;
	NSUInteger key2 = 2;
	[map setObject:@"Value1" toKey:key1];
	[map setObject:@"Value2" toKey:key2];
	MAD_PASS([map count] == 2, "two unsigned entries");
	MAD_PASS_EQUAL([map objectAtIndex:key1], @"Value1", "key 1 round trips");
	MAD_PASS_EQUAL([map objectAtIndex:key2], @"Value2", "key 2 round trips");

	[map setObject:nil toKey:key1];
	MAD_PASS([map count] == 1, "setting nil removes the entry");
}

static void testStringWithEmbeddedNull(void) {
	MADMapStringsInteger *map = [[MADMapStringsInteger alloc] init];
	const char bytes[] = "Hello\0World";
	NSString *testString = [[NSString alloc] initWithBytes:bytes length:11 encoding:NSUTF8StringEncoding];
	[map setObject:testString toKey:1];
	MAD_PASS_EQUAL([map objectAtIndex:1], testString, "a string with an embedded null round trips");
}

static void testEmptyString(void) {
	MADMapStringsShort *map = [[MADMapStringsShort alloc] init];
	[map setObject:@"" toKey:1];
	MAD_PASS_EQUAL([map objectAtIndex:1], @"", "an empty string round trips");
}

static void testLargeKey(void) {
	MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
	NSUInteger largeKey = NSUIntegerMax;
	[map setObject:@"Large" toKey:largeKey];
	MAD_PASS_EQUAL([map objectAtIndex:largeKey], @"Large", "the largest key round trips");
}

MAD_TEST_MAIN("MADMapStringsTests",
	MAD_TEST(testMapStrings),
	MAD_TEST(testFactoryMethodCreatesCorrectSubclass),
	MAD_TEST(testIntegerMap),
	MAD_TEST(testShortMap),
	MAD_TEST(testUnsignedIntegerMap),
	MAD_TEST(testStringWithEmbeddedNull),
	MAD_TEST(testEmptyString),
	MAD_TEST(testLargeKey));
