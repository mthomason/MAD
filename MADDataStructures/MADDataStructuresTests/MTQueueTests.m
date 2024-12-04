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

- (void)testCountAfterMultipleOperations {
	[self.queue enqueue:@1];
	[self.queue enqueue:@2];
	[self.queue dequeue];
	[self.queue enqueue:@3];
	
	XCTAssertEqual([self.queue count], 2, @"Queue count should correctly reflect enqueues and dequeues.");
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

@end
