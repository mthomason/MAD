//
//  MTStackTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MTStackTests.m: the stack's push/pop
//  behaviour, its logging conformance and its fast enumeration.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MTStack.h>

static void testStackInitialization(void) {
	MTStack *emptyStack = [[MTStack alloc] init];
	MAD_PASS(emptyStack != nil, "stack initializes");
	MAD_PASS([emptyStack isEmpty], "stack is empty after default initialization");

	MTStack *nilStack = [[MTStack alloc] initWithObject:nil];
	MAD_PASS(nilStack != nil, "stack initialized with nil object exists");
	MAD_PASS(![nilStack isEmpty], "stack initialized with nil object is not empty");
	MAD_PASS([nilStack pop] == nil, "popped nil object is nil");

	NSString *initialObject = @"FirstObject";
	MTStack *stackWithObject = [[MTStack alloc] initWithObject:initialObject];
	MAD_PASS(stackWithObject != nil, "stack with initial object initializes");
	MAD_PASS(![stackWithObject isEmpty], "stack with an object is not empty");
	MAD_PASS_EQUAL([stackWithObject pop], initialObject, "popped object matches the initial object");
	MAD_PASS([stackWithObject isEmpty], "stack is empty after popping the initial object");
}

static void testPushAndPop(void) {
	MTStack *stack = [[MTStack alloc] init];
	NSArray *testObjects = @[@"A", @"B", @"C", @"D", @"E"];
	for (id object in testObjects) {
		[stack push:object];
	}
	MAD_PASS(![stack isEmpty], "stack is not empty after pushes");

	for (NSUInteger i = testObjects.count - 1; i < testObjects.count; i--) {
		MAD_PASS_EQUAL([stack pop], testObjects[i], "popped object matches LIFO order");
	}
	MAD_PASS([stack isEmpty], "stack is empty after all pops");

	[stack push:@1];
	[stack push:@2];
	MAD_PASS_EQUAL([stack pop], @2, "intermediate pop");
	[stack push:@3];
	MAD_PASS_EQUAL([stack pop], @3, "subsequent pop");
	MAD_PASS_EQUAL([stack pop], @1, "final pop");
	MAD_PASS([stack isEmpty], "stack is empty after interleaved operations");
}

static void testEmptyStackBehavior(void) {
	MTStack *stack = [[MTStack alloc] init];
	MAD_PASS([stack isEmpty], "stack is empty initially");
	MAD_PASS([stack pop] == nil, "popping from an empty stack is nil");
	for (int i = 0; i < 5; i++) {
		MAD_PASS([stack pop] == nil, "repeated pops on an empty stack are nil");
	}
	MAD_PASS([stack isEmpty], "stack remains empty after repeated pops");
}

static void testLoggingConformance(void) {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@"TestObject"];
	MAD_PASS([stack conformsToProtocol:@protocol(MTProtocolLog)], "stack conforms to MTProtocolLog");
	MAD_PASS([stack toStringDebug] != nil, "debug description is not nil");
}

static void testFastEnumerationWithEmptyStack(void) {
	MTStack *stack = [[MTStack alloc] init];
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	MAD_PASS(enumeratedItems.count == 0, "no items enumerate in an empty stack");
}

static void testFastEnumerationWithSingleItem(void) {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@"LoneItem"];
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	MAD_PASS(enumeratedItems.count == 1, "one item enumerates");
	MAD_PASS_EQUAL(enumeratedItems.firstObject, @"LoneItem", "enumerated item matches the pushed item");
}

static void testFastEnumerationOrderAndCompleteness(void) {
	MTStack *stack = [[MTStack alloc] init];
	NSUInteger itemCount = 1000;
	for (NSUInteger i = 0; i < itemCount; i++) {
		[stack push:@(i)];
	}
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	MAD_PASS(enumeratedItems.count == itemCount, "all items enumerate");
	for (NSUInteger i = 0; i < itemCount; i++) {
		MAD_PASS_EQUAL(enumeratedItems[i], @(itemCount - 1 - i), "enumeration is in LIFO order");
	}
}

static void testFastEnumerationWithMutationDetection(void) {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@1];
	[stack push:@2];

	BOOL threw = NO;
	@try {
		NSMutableArray *collectedItems = [NSMutableArray array];
		for (id item in stack) {
			[collectedItems addObject:item];
			[stack push:@99];
		}
	} @catch (NSException *e) {
		threw = YES;
	}
	MAD_PASS(threw, "mutating the stack during enumeration throws");
}

MAD_TEST_MAIN("MTStackTests",
	MAD_TEST(testStackInitialization),
	MAD_TEST(testPushAndPop),
	MAD_TEST(testEmptyStackBehavior),
	MAD_TEST(testLoggingConformance),
	MAD_TEST(testFastEnumerationWithEmptyStack),
	MAD_TEST(testFastEnumerationWithSingleItem),
	MAD_TEST(testFastEnumerationOrderAndCompleteness),
	MAD_TEST(testFastEnumerationWithMutationDetection));
