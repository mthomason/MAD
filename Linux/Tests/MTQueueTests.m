//
//  MTQueueTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MTQueueTests.m: FIFO order, counting,
//  nil handling and the fast enumeration of the queue.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MTQueue.h>

static void testInitialization(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	MAD_PASS(queue != nil, "queue initializes");
	MAD_PASS([queue count] == 0, "a new queue has a count of 0");
}

static void testEnqueue(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	MAD_PASS([queue count] == 1, "count increases after enqueue");
	[queue enqueue:@2];
	MAD_PASS([queue count] == 2, "count reflects the number of enqueued items");
}

static void testDequeue(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	[queue enqueue:@2];

	MAD_PASS_EQUAL([queue dequeue], @1, "the first dequeue matches the first enqueue");
	MAD_PASS([queue count] == 1, "count decreases after dequeue");
	MAD_PASS_EQUAL([queue dequeue], @2, "the second dequeue matches the second enqueue");
	MAD_PASS([queue count] == 0, "the queue is empty after dequeuing everything");
}

static void testBasicEnqueueDequeue(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	[queue enqueue:@2];
	[queue enqueue:@3];

	MAD_PASS_EQUAL([queue dequeue], @1, "1 is dequeued first");
	MAD_PASS_EQUAL([queue dequeue], @2, "2 is dequeued second");
	MAD_PASS_EQUAL([queue dequeue], @3, "3 is dequeued third");
	MAD_PASS([queue dequeue] == nil, "an empty queue dequeues nil");
}

static void testDequeueEmptyQueue(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	MAD_PASS([queue dequeue] == nil, "dequeue on an empty queue is nil");
}

static void testOrderOfElements(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	[queue enqueue:@2];
	[queue enqueue:@3];

	MAD_PASS_EQUAL([queue dequeue], @1, "the queue follows FIFO order");
	MAD_PASS_EQUAL([queue dequeue], @2, "the second element is the second enqueued");
	MAD_PASS_EQUAL([queue dequeue], @3, "the third element is the third enqueued");
}

static void testCountOperation(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	MAD_PASS([queue count] == 0, "count starts at 0");
	[queue enqueue:@1];
	[queue enqueue:@2];
	MAD_PASS([queue count] == 2, "count is 2 after two enqueues");
	[queue dequeue];
	MAD_PASS([queue count] == 1, "count is 1 after one dequeue");
}

static void testCountAfterMultipleOperations(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	[queue enqueue:@2];
	[queue dequeue];
	[queue enqueue:@3];
	MAD_PASS([queue count] == 2, "count reflects enqueues and dequeues");
}

static void testLargeNumberOfItems(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	NSUInteger largeNumber = 100000;
	for (NSUInteger i = 0; i < largeNumber; i++) {
		[queue enqueue:@(i)];
	}
	MAD_PASS([queue count] == largeNumber, "count matches the number of enqueued items");
	for (NSUInteger i = 0; i < largeNumber; i++) {
		MAD_PASS_EQUAL([queue dequeue], @(i), "the dequeued item matches the enqueued item");
	}
	MAD_PASS([queue count] == 0, "count is 0 after dequeuing everything");
}

static void testEnqueueDequeueWithNil(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:nil];
	[queue enqueue:@1];
	MAD_PASS([queue dequeue] == nil, "the queued nil is dequeued");
	MAD_PASS_EQUAL([queue dequeue], @1, "1 is dequeued after the nil");
	MAD_PASS([queue dequeue] == nil, "an empty queue dequeues nil");
}

static void testFastEnumeration(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	[queue enqueue:@1];
	[queue enqueue:@2];
	[queue enqueue:@3];

	NSMutableArray *collectedElements = [NSMutableArray array];
	for (id obj in queue) {
		[collectedElements addObject:obj];
	}
	MAD_PASS_EQUAL(collectedElements, (@[@1, @2, @3]), "enumeration visits every element in order");
}

static void testFastEnumerationEmpty(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	NSMutableArray *collectedElements = [NSMutableArray array];
	for (id obj in queue) {
		[collectedElements addObject:obj];
	}
	MAD_PASS_EQUAL(collectedElements, @[], "nothing enumerates in an empty queue");
}

static void testFastEnumerationWithLargeNumberOfItems(void) {
	MTQueue *queue = [[MTQueue alloc] init];
	NSUInteger largeNumber = 1000;
	for (NSUInteger i = 0; i < largeNumber; i++) {
		[queue enqueue:@(i)];
	}
	MAD_PASS([queue count] == largeNumber, "count matches the number of enqueued items");

	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in queue) {
		[enumeratedItems addObject:item];
	}
	MAD_PASS([enumeratedItems count] == largeNumber, "all items enumerate");
	for (NSUInteger i = 0; i < largeNumber; i++) {
		MAD_PASS_EQUAL(enumeratedItems[i], @(i), "the enumerated item matches the enqueued item");
	}
}

MAD_TEST_MAIN("MTQueueTests",
	MAD_TEST(testInitialization),
	MAD_TEST(testEnqueue),
	MAD_TEST(testDequeue),
	MAD_TEST(testBasicEnqueueDequeue),
	MAD_TEST(testDequeueEmptyQueue),
	MAD_TEST(testOrderOfElements),
	MAD_TEST(testCountOperation),
	MAD_TEST(testCountAfterMultipleOperations),
	MAD_TEST(testLargeNumberOfItems),
	MAD_TEST(testEnqueueDequeueWithNil),
	MAD_TEST(testFastEnumeration),
	MAD_TEST(testFastEnumerationEmpty),
	MAD_TEST(testFastEnumerationWithLargeNumberOfItems));
