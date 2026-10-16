//
//  MTLinkedListTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MTLinkedListTests.m: insertion, element
//  access, the next/previous cursor, reversal and fast enumeration.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MTLinkedList.h>

static void testInitialization(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	MAD_PASS(list != nil, "list initializes");
	MAD_PASS(list.count == 0, "initial count is 0");
	MAD_PASS(list.head == nil, "head is nil for an empty list");
}

static void testInsertWithValidObjects(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list insert:@1];
	[list insert:@2];
	[list insert:@3];
	MAD_PASS(list.count == 3, "count reflects inserted objects");
	MAD_PASS_EQUAL(list.head, @3, "insert places objects at the head");
}

static void testInsertWithNil(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list insert:nil];
	MAD_PASS(list.count == 0, "inserting nil does not affect count");
}

static void testAddWithValidObjects(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	MAD_PASS(list.count == 2, "count reflects added objects");
	MAD_PASS_EQUAL(list.head, @1, "add maintains insertion order at the head");
}

static void testAddWithNil(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:nil];
	MAD_PASS(list.count == 0, "adding nil does not affect count");
}

static void testHeadForEmptyList(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	MAD_PASS(list.head == nil, "head is nil for an empty list");
}

static void testGetTopAndBottom(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	MAD_PASS_EQUAL([list getTop], @1, "getTop returns the first object");
	MAD_PASS_EQUAL([list getBottom], @3, "getBottom returns the last object");
}

static void testObjectAtIndex(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	MAD_PASS_EQUAL([list objectAtIndex:0], @1, "index 0 returns the first object");
	MAD_PASS_EQUAL([list objectAtIndex:2], @3, "index 2 returns the last object");
	MAD_PASS([list objectAtIndex:3] == nil, "an out-of-bounds index returns nil");
	MAD_PASS([list objectAtIndex:-1] == nil, "a negative index returns nil");
}

static void testGetNextAndIsNext(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	MAD_PASS([list isNext], "isNext is true initially");
	MAD_PASS_EQUAL([list getNext], @2, "getNext returns the second object");
	[list getNext];
	MAD_PASS(![list isNext], "isNext is false at the end");
	MAD_PASS([list getNext] == nil, "getNext at the end is nil");
}

static void testGetPreviousAndIsPrevious(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	[list getNext];
	[list getNext];
	MAD_PASS([list isPrevious], "isPrevious is true");
	MAD_PASS_EQUAL([list getPrevious], @2, "getPrevious returns the second object");
	MAD_PASS_EQUAL([list getPrevious], @1, "getPrevious returns the first object");
	MAD_PASS(![list isPrevious], "isPrevious is false at the start");
	MAD_PASS([list getPrevious] == nil, "getPrevious at the start is nil");
}

static void testReverseEmptyList(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list reverse];
	MAD_PASS(list.count == 0, "reversing an empty list keeps the count");
	MAD_PASS([list head] == nil, "head remains nil");
}

static void testReverseSingleItemList(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list reverse];
	MAD_PASS_EQUAL([list toArray], (@[@1]), "reversing a single item has no effect");
}

static void testReverseMultipleItems(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	[list reverse];
	MAD_PASS_EQUAL([list toArray], (@[@3, @2, @1]), "the reversed list matches the expected order");
	MAD_PASS_EQUAL([list getTop], @3, "getTop returns the new head after reversal");
	MAD_PASS_EQUAL([list getBottom], @1, "getBottom returns the new tail after reversal");
}

static void testToArrayEmptyList(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	MAD_PASS_EQUAL([list toArray], @[], "an empty list returns an empty array");
}

static void testToArrayWithItems(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];
	[list add:@3];
	MAD_PASS_EQUAL([list toArray], (@[@1, @2, @3]), "toArray preserves insertion order");
}

static void testFastEnumerationEmptyList(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	NSUInteger count = 0;
	for (__unused id obj in list) { count++; }
	MAD_PASS(count == 0, "nothing enumerates in an empty list");
}

static void testFastEnumerationOrderAndCompleteness(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	const NSUInteger itemCount = 320;
	NSMutableArray *expected = [NSMutableArray array];
	for (NSUInteger i = 1; i <= itemCount; i++) {
		[expected addObject:@(i)];
		[list add:@(i)];
	}

	NSMutableArray *enumerated = [NSMutableArray array];
	for (id obj in list) {
		[enumerated addObject:obj];
	}
	MAD_PASS_EQUAL(enumerated, expected, "enumeration captures all items in order");
}

static void testFastEnumerationMutation(void) {
	MTLinkedList *list = [[MTLinkedList alloc] init];
	[list add:@1];
	[list add:@2];

	BOOL threw = NO;
	@try {
		NSMutableArray *collected = [NSMutableArray array];
		for (id obj in list) {
			[collected addObject:obj];
			[list add:@99];
		}
	} @catch (NSException *e) {
		threw = YES;
	}
	MAD_PASS(threw, "mutating during enumeration throws");
}

MAD_TEST_MAIN("MTLinkedListTests",
	MAD_TEST(testInitialization),
	MAD_TEST(testInsertWithValidObjects),
	MAD_TEST(testInsertWithNil),
	MAD_TEST(testAddWithValidObjects),
	MAD_TEST(testAddWithNil),
	MAD_TEST(testHeadForEmptyList),
	MAD_TEST(testGetTopAndBottom),
	MAD_TEST(testObjectAtIndex),
	MAD_TEST(testGetNextAndIsNext),
	MAD_TEST(testGetPreviousAndIsPrevious),
	MAD_TEST(testReverseEmptyList),
	MAD_TEST(testReverseSingleItemList),
	MAD_TEST(testReverseMultipleItems),
	MAD_TEST(testToArrayEmptyList),
	MAD_TEST(testToArrayWithItems),
	MAD_TEST(testFastEnumerationEmptyList),
	MAD_TEST(testFastEnumerationOrderAndCompleteness),
	MAD_TEST(testFastEnumerationMutation));
