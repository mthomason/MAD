//
//  MTLinkedListTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/4/24.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTLinkedList.h"

@interface MTLinkedListTests : XCTestCase

@property (nonatomic, strong) MTLinkedList *linkedList;

@end

@implementation MTLinkedListTests

- (void)setUp {
	[super setUp];
	self.linkedList = [[MTLinkedList alloc] init];
}

- (void)tearDown {
	self.linkedList = nil;
	[super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitialization {
	XCTAssertNotNil(self.linkedList, @"LinkedList should be initialized.");
	XCTAssertEqual(self.linkedList.count, 0, @"Initial count should be 0.");
	XCTAssertNil(self.linkedList.head, @"Head should be nil for an empty list.");
}

#pragma mark - Insertion Tests

- (void)testInsertWithValidObjects {
	[self.linkedList insert:@1];
	[self.linkedList insert:@2];
	[self.linkedList insert:@3];
	XCTAssertEqual(self.linkedList.count, 3, @"Count should reflect inserted objects.");
	XCTAssertEqualObjects(self.linkedList.head, @3, @"Insert should place objects at the head.");
}

- (void)testInsertWithNil {
	[self.linkedList insert:nil];
	XCTAssertEqual(self.linkedList.count, 0, @"Inserting nil should not affect count.");
}

- (void)testAddWithValidObjects {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	XCTAssertEqual(self.linkedList.count, 2, @"Count should reflect added objects.");
	XCTAssertEqualObjects(self.linkedList.head, @1, @"Add should maintain insertion order at head.");
}

- (void)testAddWithNil {
	[self.linkedList add:nil];
	XCTAssertEqual(self.linkedList.count, 0, @"Adding nil should not affect count.");
}

#pragma mark - Element Access Tests

- (void)testHeadForEmptyList {
	XCTAssertNil(self.linkedList.head, @"Head should be nil for an empty list.");
}

- (void)testGetTopAndBottom {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	XCTAssertEqualObjects([self.linkedList getTop], @1, @"getTop should return the first object.");
	XCTAssertEqualObjects([self.linkedList getBottom], @3, @"getBottom should return the last object.");
}

- (void)testObjectAtIndex {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	// Valid indices
	XCTAssertEqualObjects([self.linkedList objectAtIndex:0], @1, @"Index 0 should return first object.");
	XCTAssertEqualObjects([self.linkedList objectAtIndex:2], @3, @"Index 2 should return last object.");
	
	// Out-of-bounds indices
	XCTAssertNil([self.linkedList objectAtIndex:3], @"Out-of-bounds index should return nil.");
	XCTAssertNil([self.linkedList objectAtIndex:-1], @"Negative index should return nil.");
}

#pragma mark - Navigation Tests

- (void)testGetNextAndIsNext {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	XCTAssertTrue([self.linkedList isNext], @"isNext should be true initially.");
	XCTAssertEqualObjects([self.linkedList getNext], @2, @"getNext should return the second object.");
	
	[self.linkedList getNext]; // Move to third object
	XCTAssertFalse([self.linkedList isNext], @"isNext should be false at the end.");
	XCTAssertNil([self.linkedList getNext], @"getNext at end should return nil.");
}

- (void)testGetPreviousAndIsPrevious {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	[self.linkedList getNext]; // Move to second object
	[self.linkedList getNext]; // Move to third object
	
	XCTAssertTrue([self.linkedList isPrevious], @"isPrevious should be true.");
	XCTAssertEqualObjects([self.linkedList getPrevious], @2, @"getPrevious should return the second object.");
	XCTAssertEqualObjects([self.linkedList getPrevious], @1, @"getPrevious should return the first object.");
	XCTAssertFalse([self.linkedList isPrevious], @"isPrevious should be false at the start.");
	XCTAssertNil([self.linkedList getPrevious], @"getPrevious at start should return nil.");
}

#pragma mark - Reverse Tests

- (void)testReverseEmptyList {
	[self.linkedList reverse];
	XCTAssertEqual(self.linkedList.count, 0, @"Reversing empty list should not change count.");
	XCTAssertNil([self.linkedList head], @"Head should remain nil.");
}

- (void)testReverseSingleItemList {
	[self.linkedList add:@1];
	[self.linkedList reverse];
	XCTAssertEqualObjects([self.linkedList toArray], @[@1], @"Reversing single item should have no effect.");
}

- (void)testReverseMultipleItems {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	[self.linkedList reverse];
	
	NSArray *expected = @[@3, @2, @1];
	XCTAssertEqualObjects([self.linkedList toArray], expected, @"Reversed list should match expected order.");
	XCTAssertEqualObjects([self.linkedList getTop], @3, @"getTop should return new head after reversal.");
	XCTAssertEqualObjects([self.linkedList getBottom], @1, @"getBottom should return new tail after reversal.");
}

#pragma mark - Conversion Tests

- (void)testToArrayEmptyList {
	XCTAssertEqualObjects([self.linkedList toArray], @[], @"Empty list should return empty array.");
}

- (void)testToArrayWithItems {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	XCTAssertEqualObjects([self.linkedList toArray], (@[@1, @2, @3]), @"toArray should preserve insertion order.");
}

#pragma mark - Fast Enumeration Tests

- (void)testFastEnumerationEmptyList {
	NSUInteger count = 0;
	for (__unused id obj in self.linkedList) { count++; }
	XCTAssertEqual(count, 0, @"No iterations should occur for empty list.");
}

- (void)testFastEnumerationOrderAndCompleteness {
	// Test with 34 items to exceed typical fast enumeration buffer size (16/32)
	const NSUInteger itemCount = 34;
	NSMutableArray *expected = [NSMutableArray array];
	for (NSUInteger i = 1; i <= itemCount; i++) {
		[expected addObject:@(i)];
		[self.linkedList add:@(i)];
	}
	
	NSMutableArray *enumerated = [NSMutableArray array];
	for (id obj in self.linkedList) {
		[enumerated addObject:obj];
	}
	
	XCTAssertEqualObjects(enumerated, expected, @"Enumeration should capture all items in order.");
}

- (void)testFastEnumerationMutation {
	[self.linkedList add:@1];
	[self.linkedList add:@2];

	// Define the mutation block
	void (^mutationBlock)(void) = ^{
		NSMutableArray *collected = [NSMutableArray array];
		for (id obj in self.linkedList) {
			[collected addObject:obj];
			[self.linkedList add:@99]; // Modify during enumeration
		}
	};

	// Test for exception
	XCTAssertThrows(mutationBlock(), @"Mutating during enumeration should throw exception.");
}

@end
