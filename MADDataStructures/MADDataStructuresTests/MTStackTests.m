//
//  MTStackTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/2/24.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTStack.h"

@interface MTStackTests : XCTestCase

@end

@implementation MTStackTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

// MARK: - Initialization Tests

- (void)testStackInitialization {
	// Test default initializer
	MTStack *emptyStack = [[MTStack alloc] init];
	XCTAssertNotNil(emptyStack, @"Stack should be initialized properly");
	XCTAssertTrue([emptyStack isEmpty], @"Stack should be empty after default initialization");
	
	// Test initialization with nil object
	MTStack *nilStack = [[MTStack alloc] initWithObject:nil];
	XCTAssertNotNil(nilStack, @"Stack initialized with nil object should exist");
	XCTAssertFalse([nilStack isEmpty], @"Stack initialized with nil object should not be empty");
	XCTAssertNil([nilStack pop], @"Popped nil object should return nil");
	
	// Test initialization with valid object
	NSString *initialObject = @"FirstObject";
	MTStack *stackWithObject = [[MTStack alloc] initWithObject:initialObject];
	XCTAssertNotNil(stackWithObject, @"Stack with initial object should be initialized");
	XCTAssertFalse([stackWithObject isEmpty], @"Stack should not be empty after initialization with object");
	XCTAssertEqualObjects([stackWithObject pop], initialObject, @"Popped object should match initial object");
	XCTAssertTrue([stackWithObject isEmpty], @"Stack should be empty after popping initial object");
}

// MARK: - Push/Pop Behavior Tests

- (void)testPushAndPop {
	MTStack *stack = [[MTStack alloc] init];
	
	// Test pushing multiple objects and verify LIFO order
	NSArray *testObjects = @[@"A", @"B", @"C", @"D", @"E"];
	for (id object in testObjects) {
		[stack push:object];
	}
	
	XCTAssertFalse([stack isEmpty], @"Stack should not be empty after pushes");
	
	// Verify pop order (LIFO: last pushed is first popped)
	for (NSUInteger i = testObjects.count - 1; i < testObjects.count; i--) {
		id expectedObject = testObjects[i];
		XCTAssertEqualObjects([stack pop], expectedObject, @"Popped object should match LIFO order");
	}
	
	XCTAssertTrue([stack isEmpty], @"Stack should be empty after all pops");
	
	// Test interleaved push/pop operations
	[stack push:@1];
	[stack push:@2];
	XCTAssertEqualObjects([stack pop], @2, @"Intermediate pop should work");
	[stack push:@3];
	XCTAssertEqualObjects([stack pop], @3, @"Subsequent pop should work");
	XCTAssertEqualObjects([stack pop], @1, @"Final pop should work");
	XCTAssertTrue([stack isEmpty], @"Stack should be empty after interleaved operations");
}

- (void)testEmptyStackBehavior {
	MTStack *stack = [[MTStack alloc] init];
	
	// Verify initial state
	XCTAssertTrue([stack isEmpty], @"Stack should be empty initially");
	XCTAssertNil([stack pop], @"Popping from empty stack should return nil");
	
	// Test repeated pops on empty stack
	for (int i = 0; i < 5; i++) {
		XCTAssertNil([stack pop], @"Repeated pops on empty stack should return nil");
	}
	XCTAssertTrue([stack isEmpty], @"Stack should remain empty after repeated pops");
}

// MARK: - Protocol Conformance Tests

- (void)testLoggingConformance {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@"TestObject"];
	
	// Verify MTProtocolLog conformance
	XCTAssertTrue([stack conformsToProtocol:@protocol(MTProtocolLog)], @"Stack should conform to MTProtocolLog");
	
	// Test debug description (basic smoke test)
	NSString *debugDescription = [stack toStringDebug];
	XCTAssertNotNil(debugDescription, @"Debug description should not be nil");
	XCTAssertTrue([debugDescription isKindOfClass:[NSString class]], @"Debug description should be a string");
}

// MARK: - Fast Enumeration Tests

- (void)testFastEnumerationWithEmptyStack {
	MTStack *stack = [[MTStack alloc] init];
	
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	
	XCTAssertEqual(enumeratedItems.count, 0, @"No items should be enumerated in empty stack");
}

- (void)testFastEnumerationWithSingleItem {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@"LoneItem"];
	
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	
	XCTAssertEqual(enumeratedItems.count, 1, @"Should enumerate single item");
	XCTAssertEqualObjects(enumeratedItems.firstObject, @"LoneItem", @"Enumerated item should match pushed item");
}

- (void)testFastEnumerationOrderAndCompleteness {
	MTStack *stack = [[MTStack alloc] init];
	NSUInteger itemCount = 1000;
	
	// Push items in reverse order (0, 1, 2...999 -> stack becomes 999, 998...0)
	for (NSUInteger i = 0; i < itemCount; i++) {
		[stack push:@(i)];
	}
	
	// Enumerate all items
	NSMutableArray *enumeratedItems = [NSMutableArray array];
	for (id item in stack) {
		[enumeratedItems addObject:item];
	}
	
	// Verify count
	XCTAssertEqual(enumeratedItems.count, itemCount, @"All items should be enumerated");
	
	// Verify LIFO order (first enumerated item = last pushed)
	for (NSUInteger i = 0; i < itemCount; i++) {
		NSUInteger expectedValue = itemCount - 1 - i;
		XCTAssertEqualObjects(enumeratedItems[i], @(expectedValue),
							 @"Item at index %lu should be %lu (LIFO order)", (unsigned long)i, (unsigned long)expectedValue);
	}
}

- (void)testFastEnumerationWithMutationDetection {
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@1];
	[stack push:@2];
	
	// Enumerate and modify the stack during iteration (should NOT crash but may exhibit undefined behavior)
	XCTAssertThrows(
		^{
			NSMutableArray *collectedItems = [NSMutableArray array];
			for (id item in stack) {
				[collectedItems addObject:item];
				[stack push:@99]; // Mutate during enumeration
			}
		}(),
		@"Modifying stack during enumeration should throw mutation exception"
	);
}

@end
