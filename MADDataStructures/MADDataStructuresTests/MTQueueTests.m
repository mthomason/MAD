//
//  MTQueueTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/3/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTQueue.h"

@interface MTQueueTests : XCTestCase
	@property (nonatomic, strong) MTQueue *queue;
@end

@implementation MTQueueTests

- (void)setUp {
	[super setUp];
	self.queue = [[MTQueue alloc] init];
}

- (void)tearDown {
	self.queue = nil;
	[super tearDown];
}

- (void)testInitialization {
	XCTAssertNotNil(self.queue, @"Queue should be initialized successfully.");
	XCTAssertEqual([self.queue count], 0, @"Newly initialized queue should have a count of 0.");
}

- (void)testEnqueue {
	[self.queue enqueue:@1];
	XCTAssertEqual([self.queue count], 1, @"Queue count should increase after enqueue.");
	[self.queue enqueue:@2];
	XCTAssertEqual([self.queue count], 2, @"Queue count should reflect the number of enqueued items.");
}

- (void)testDequeue {
	[self.queue enqueue:@1];
	[self.queue enqueue:@2];
	
	id firstDequeued = [self.queue dequeue];
	XCTAssertEqualObjects(firstDequeued, @1, @"The first dequeued object should match the first enqueued object.");
	XCTAssertEqual([self.queue count], 1, @"Queue count should decrease after dequeue.");
	
	id secondDequeued = [self.queue dequeue];
	XCTAssertEqualObjects(secondDequeued, @2, @"The second dequeued object should match the second enqueued object.");
	XCTAssertEqual([self.queue count], 0, @"Queue should be empty after dequeuing all items.");
}

- (void)testBasicEnqueueDequeue {
	MTQueue *queue = [[MTQueue alloc] init];
	
	[queue enqueue:@1];
	[queue enqueue:@2];
	[queue enqueue:@3];
	
	XCTAssertEqual([queue dequeue], @1, @"Expected 1 to be dequeued");
	XCTAssertEqual([queue dequeue], @2, @"Expected 2 to be dequeued");
	XCTAssertEqual([queue dequeue], @3, @"Expected 3 to be dequeued");
	XCTAssertNil([queue dequeue], @"Expected nil when queue is empty");
}

- (void)testDequeueEmptyQueue {
	id dequeued = [self.queue dequeue];
	XCTAssertNil(dequeued, @"Dequeue on an empty queue should return nil.");
}

- (void)testOrderOfElements {
	[self.queue enqueue:@1];
	[self.queue enqueue:@2];
	[self.queue enqueue:@3];
	
	XCTAssertEqualObjects([self.queue dequeue], @1, @"Queue should follow FIFO (First In First Out) order.");
	XCTAssertEqualObjects([self.queue dequeue], @2, @"Second dequeued element should be the second enqueued.");
	XCTAssertEqualObjects([self.queue dequeue], @3, @"Third dequeued element should be the third enqueued.");
}

- (void)testCountOperation {
	MTQueue *queue = [[MTQueue alloc] init];
	
	XCTAssertEqual([queue count], 0, @"Expected count to be 0 initially");
	
	[queue enqueue:@1];
	[queue enqueue:@2];
	
	XCTAssertEqual([queue count], 2, @"Expected count to be 2 after enqueuing two items");
	
	[queue dequeue];
	
	XCTAssertEqual([queue count], 1, @"Expected count to be 1 after dequeuing one item");
}

- (void)testCountAfterMultipleOperations {
	[self.queue enqueue:@1];
	[self.queue enqueue:@2];
	[self.queue dequeue];
	[self.queue enqueue:@3];
	
	XCTAssertEqual([self.queue count], 2, @"Queue count should correctly reflect enqueues and dequeues.");
}

- (void)testLargeNumberOfItems {
	MTQueue *queue = [[MTQueue alloc] init];
	NSUInteger largeNumber = 100000; // Adjust this number based on your performance requirements
	
	for (NSUInteger i = 0; i < largeNumber; i++) {
		[queue enqueue:@(i)];
	}
	
	XCTAssertEqual([queue count], largeNumber, @"Expected count to match the number of enqueued items");
	
	for (NSUInteger i = 0; i < largeNumber; i++) {
		XCTAssertEqual([queue dequeue], @(i), @"Expected dequeued item to match enqueued item");
	}
	
	XCTAssertEqual([queue count], 0, @"Expected count to be 0 after dequeuing all items");
}

- (void)testEnqueueDequeueWithNil {
	MTQueue *queue = [[MTQueue alloc] init];
	
	[queue enqueue:nil];
	[queue enqueue:@1];
	
	XCTAssertNil([queue dequeue], @"Expected nil to be dequeued");
	XCTAssertEqual([queue dequeue], @1, @"Expected 1 to be dequeued");
	XCTAssertNil([queue dequeue], @"Expected nil when queue is empty");
}

- (void)testFastEnumeration {
	[self.queue enqueue:@1];
	[self.queue enqueue:@2];
	[self.queue enqueue:@3];
	
	NSMutableArray *collectedElements = [NSMutableArray array];
	for (id obj in self.queue) {
		[collectedElements addObject:obj];
	}
	
	NSArray *expectedElements = @[@1, @2, @3];
	XCTAssertEqualObjects(collectedElements, expectedElements, @"Fast enumeration should iterate over all enqueued elements in order.");
}

- (void)testFastEnumerationEmpty {
	
	NSMutableArray *collectedElements = [NSMutableArray array];
	for (id obj in self.queue) {
		[collectedElements addObject:obj];
	}
	
	NSArray *expectedElements = @[];
	XCTAssertEqualObjects(collectedElements, expectedElements, @"Fast enumeration should iterate over all enqueued elements in order.");
}

- (void)testFastEnumerationWithLargeNumberOfItems {
	MTQueue *queue = [[MTQueue alloc] init];
	NSUInteger largeNumber = 1000; // Use a number larger than the internal buffer size (e.g., 16 or 32)
	
	// Enqueue a large number of items
	for (NSUInteger i = 0; i < largeNumber; i++) {
		[queue enqueue:@(i)];
	}
	
	// Verify the count
	XCTAssertEqual([queue count], largeNumber, @"Expected count to match the number of enqueued items");
	
	// Use fast enumeration to collect all items
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in queue) {
		[enumeratedItems addObject:item];
	}
	
	// Verify that all items were enumerated correctly
	XCTAssertEqual([enumeratedItems count], largeNumber, @"Expected all items to be enumerated");
	
	for (NSUInteger i = 0; i < largeNumber; i++) {
		XCTAssertEqualObjects(enumeratedItems[i], @(i), @"Expected enumerated item to match enqueued item");
	}
}

@end
