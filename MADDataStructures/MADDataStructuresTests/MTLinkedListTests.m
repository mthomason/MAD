//
//  MTLinkedListTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/4/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
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

- (void)testInit {
	XCTAssertNotNil(self.linkedList, @"LinkedList instance should not be nil after initialization.");
	XCTAssertEqual([self.linkedList count], 0, @"LinkedList should initially have a count of 0.");
}

#pragma mark - Insertion and Count Tests

- (void)testInsert {
	[self.linkedList insert:@1];
	XCTAssertEqual([self.linkedList count], 1, @"LinkedList count should be 1 after inserting one object.");
	
	[self.linkedList insert:@2];
	XCTAssertEqual([self.linkedList count], 2, @"LinkedList count should be 2 after inserting another object.");
}

- (void)testAdd {
	[self.linkedList add:@1];
	XCTAssertEqual([self.linkedList count], 1, @"LinkedList count should be 1 after adding one object.");
	
	[self.linkedList add:@2];
	XCTAssertEqual([self.linkedList count], 2, @"LinkedList count should be 2 after adding another object.");
}

#pragma mark - Element Access Tests

- (void)testHead {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	XCTAssertEqualObjects([self.linkedList head], @1, @"Head should return the first object added.");
}

- (void)testGetTopAndBottom {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	XCTAssertEqualObjects([self.linkedList getTop], @1, @"getTop should return the first object added.");
	XCTAssertEqualObjects([self.linkedList getBottom], @3, @"getBottom should return the last object added.");
}

- (void)testObjectAtIndex {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	XCTAssertEqualObjects([self.linkedList objectAtIndex:0], @1, @"Object at index 0 should be the first added object.");
	XCTAssertEqualObjects([self.linkedList objectAtIndex:2], @3, @"Object at index 2 should be the last added object.");
}

#pragma mark - Navigation Tests

- (void)testGetNextAndIsNext {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	XCTAssertTrue([self.linkedList isNext], @"isNext should return true when there is a next element.");
	XCTAssertEqualObjects([self.linkedList getNext], @2, @"getNext should return the second element.");
	
	[self.linkedList getNext]; // Move to the next node.
	XCTAssertFalse([self.linkedList isNext], @"isNext should return false when there is no next element.");
}

- (void)testGetPreviousAndIsPrevious {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	[self.linkedList getNext]; // Move to the second node.
	XCTAssertTrue([self.linkedList isPrevious], @"isPrevious should return true when there is a previous element.");
	XCTAssertEqualObjects([self.linkedList getPrevious], @1, @"getPrevious should return the first element.");
	
	XCTAssertFalse([self.linkedList isPrevious], @"isPrevious should return false when there is no previous element.");
}

#pragma mark - Reverse Tests

- (void)testReverse {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	[self.linkedList reverse];
	XCTAssertEqualObjects([self.linkedList head], @3, @"After reversal, head should be the last added object.");
	XCTAssertEqualObjects([self.linkedList getTop], @3, @"After reversal, getTop should return the last added object.");
	XCTAssertEqualObjects([self.linkedList getBottom], @1, @"After reversal, getBottom should return the first added object.");
}

- (void)testReverseEmptyList {
	[self.linkedList reverse];
	XCTAssertNil([self.linkedList head], @"Reversing an empty list should not cause any changes.");
	XCTAssertNil([self.linkedList getTop], @"Reversing an empty list should not cause any changes.");
	XCTAssertNil([self.linkedList getBottom], @"Reversing an empty list should not cause any changes.");
}

- (void)testReverseSingleItemList {
	[self.linkedList add:@1];
	[self.linkedList reverse];
	XCTAssertEqualObjects([self.linkedList head], @1, @"Reversing a single-item list should keep the head the same.");
	XCTAssertEqualObjects([self.linkedList getTop], @1, @"Reversing a single-item list should keep getTop the same.");
	XCTAssertEqualObjects([self.linkedList getBottom], @1, @"Reversing a single-item list should keep getBottom the same.");
}

- (void)testReverseTwoItemList {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList reverse];
	XCTAssertEqualObjects([self.linkedList head], @2, @"After reversal, head should be the last added object.");
	XCTAssertEqualObjects([self.linkedList getTop], @2, @"After reversal, getTop should return the last added object.");
	XCTAssertEqualObjects([self.linkedList getBottom], @1, @"After reversal, getBottom should return the first added object.");
}

- (void)testReverseMultipleItemList {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	[self.linkedList reverse];
	XCTAssertEqualObjects([self.linkedList head], @3, @"After reversal, head should be the last added object.");
	XCTAssertEqualObjects([self.linkedList getTop], @3, @"After reversal, getTop should return the last added object.");
	XCTAssertEqualObjects([self.linkedList getBottom], @1, @"After reversal, getBottom should return the first added object.");
}

#pragma mark - Conversion Tests

- (void)testToArray {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	NSArray *array = [self.linkedList toArray];
	NSArray *expected = @[@1, @2, @3];
	XCTAssertEqualObjects(array, expected, @"toArray should return an array containing all the elements in insertion order.");
}

#pragma mark - Test Fast Enumeration

- (void)testFastEnumerationEmptyList {
	NSUInteger count = 0;
	for (id object in self.linkedList) {
		count++;
	}
	XCTAssertEqual(count, 0, @"Fast enumeration on an empty list should iterate zero times.");
}

- (void)testFastEnumerationFewItems {
	[self.linkedList add:@1];
	[self.linkedList add:@2];
	[self.linkedList add:@3];
	
	NSArray *expected = @[@1, @2, @3];
	NSMutableArray *result = [NSMutableArray array];
	
	for (id object in self.linkedList) {
		[result addObject:object];
	}
	
	XCTAssertEqualObjects(result, expected, @"Fast enumeration should iterate over all items in order.");
}

- (void)testFastEnumerationManyItems {
	const NSUInteger itemCount = 34;
	NSMutableArray *expected = [NSMutableArray arrayWithCapacity:itemCount];
	for (NSUInteger i = 1; i <= itemCount; i++) {
		[expected addObject:@(i)];
		[self.linkedList add:@(i)];
	}
	
	NSMutableArray *result = [NSMutableArray array];
	for (id object in self.linkedList) {
		[result addObject:object];
	}
	
	XCTAssertEqualObjects(result, expected, @"Fast enumeration should iterate over all 34 items in order.");
}

@end
