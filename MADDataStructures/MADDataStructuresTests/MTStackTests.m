//
//  MTStackTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/2/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
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

- (void)testStackInitialization {
	// Test default initializer
	MTStack *stack = [[MTStack alloc] init];
	XCTAssertNotNil(stack, @"Stack should be initialized properly");
	XCTAssertTrue([stack isEmpty], @"Stack should be empty after default initialization");

	// Test initialization with an object
	NSString *initialObject = @"FirstObject";
	MTStack *stackWithObject = [[MTStack alloc] initWithObject:initialObject];
	XCTAssertNotNil(stackWithObject, @"Stack with an initial object should be initialized properly");
	XCTAssertFalse([stackWithObject isEmpty], @"Stack should not be empty after initialization with an object");
	XCTAssertEqualObjects([stackWithObject pop], initialObject, @"Popped object should match the initial object");
	XCTAssertTrue([stackWithObject isEmpty], @"Stack should be empty after popping the only object");
}

- (void)testPushAndPop {
	MTStack *stack = [[MTStack alloc] init];

	// Push objects onto the stack
	NSString *firstObject = @"First";
	NSString *secondObject = @"Second";
	[stack push:firstObject];
	[stack push:secondObject];

	XCTAssertFalse([stack isEmpty], @"Stack should not be empty after pushing objects");

	// Pop objects and verify order (LIFO)
	XCTAssertEqualObjects([stack pop], secondObject, @"Popped object should be the last pushed (LIFO)");
	XCTAssertEqualObjects([stack pop], firstObject, @"Popped object should be the first pushed (LIFO)");

	// Verify stack is empty after popping all elements
	XCTAssertTrue([stack isEmpty], @"Stack should be empty after popping all objects");
}

- (void)testEmptyStackBehavior {
	MTStack *stack = [[MTStack alloc] init];
	
	XCTAssertTrue([stack isEmpty], @"Stack should be empty upon initialization");

	// Attempt to pop from an empty stack
	id poppedObject = [stack pop];
	XCTAssertNil(poppedObject, @"Popping from an empty stack should return nil");
}

- (void)testLoggingConformance {
	// Assuming `MTProtocolLog` requires a specific method (e.g., logDescription)
	MTStack *stack = [[MTStack alloc] init];
	[stack push:@"Loggable Object"];

	if ([stack conformsToProtocol:@protocol(MTProtocolLog)]) {
		XCTAssertTrue([stack respondsToSelector:@selector(toStringDebug)], @"Stack should conform to MTProtocolLog and implement logDescription");
	}
}

@end
