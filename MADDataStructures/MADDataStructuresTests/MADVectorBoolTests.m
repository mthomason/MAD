//
//  MADVectorBoolTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/2/24.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>
#import "MADVectorBool.h"

@interface MADVectorBoolTests : XCTestCase

@end

@implementation MADVectorBoolTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testVectorBool {
	@autoreleasepool {
		// Initialize the vector
		MADVectorBool *vector = [[MADVectorBool alloc] init];
		XCTAssertNotNil(vector, @"Vector should be initialized properly");
		
		// Test adding booleans
		[vector push:YES];
		[vector push:NO];
		[vector addTrue];
		[vector addFalse];
		
		XCTAssertEqual([vector count], 4, @"Count should be 4 after adding 4 values");
		
		// Test enumeration
		__block NSUInteger trueCount = 0;
		__block NSUInteger falseCount = 0;
		__block BOOL stopEarly = NO;
		
		[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
			if (idx == 2 && stopEarly) {
				*stop = YES;
				return;
			}
			
			if (idx < 4) {
				if (idx % 2 == 0) {
					XCTAssertEqual(valid, YES, @"Even indices should correspond to YES");
					trueCount++;
				} else {
					XCTAssertEqual(valid, NO, @"Odd indices should correspond to NO");
					falseCount++;
				}
			}
		}];
		XCTAssertEqual(trueCount, 2, @"There should be 2 'true' values in the vector");
		XCTAssertEqual(falseCount, 2, @"There should be 2 'false' values in the vector");
		
		
		// Add more values and verify
		[vector push:YES];
		[vector push:NO];
		XCTAssertEqual([vector count], 6, @"Count should be 6 after adding 2 more values");
		
		__block NSArray<NSNumber *> *expectedValues = @[@YES, @NO, @YES, @NO, @YES, @NO];
		__block NSUInteger index = 0;
		
		[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
			XCTAssertEqual(idx, index, @"Index should match the expected order");
			XCTAssertEqual(valid, expectedValues[idx].boolValue, @"Boolean value should match expected values");
			index++;
		}];
		
		XCTAssertEqual(index, expectedValues.count, @"Enumeration should process all elements");
		
		// Test stopping enumeration early
		stopEarly = YES;
		__block NSUInteger enumeratedCount = 0;
		
		[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
			enumeratedCount++;
			if (idx == 2) {
				*stop = YES;
			}
		}];
		XCTAssertEqual(enumeratedCount, 3, @"Enumeration should stop after 3 iterations when *stop is set to YES");
	}
}

- (void)testEmptyVector {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	XCTAssertEqual([vector count], 0, @"Initial count should be 0");
	
	__block NSUInteger callCount = 0;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		callCount++;
	}];
	XCTAssertEqual(callCount, 0, @"No elements should enumerate");
	
	NSString *debugString = [vector debugQuickLookObject];
	XCTAssertEqualObjects(debugString, @"", @"Debug string for empty vector should be empty");
}

- (void)testDebugQuickLook {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	[vector addTrue];
	[vector addFalse];
	[vector addTrue];
	
	NSString *expected = @"YES\nNO\nYES\n";
	NSString *debugString = [vector debugQuickLookObject];
	XCTAssertEqualObjects(debugString, expected, @"Debug string should match elements");
}

- (void)testPushNonStandardBOOL {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	BOOL nonStandardValue = 2; // Non-zero, treated as YES
	[vector push:nonStandardValue];
	
	XCTAssertEqual([vector count], 1, @"Count should be 1");
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		XCTAssertEqual(valid, YES, @"Non-zero BOOL should be treated as YES");
	}];
}

- (void)testSingleElement {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	[vector addFalse];
	
	XCTAssertEqual([vector count], 1, @"Count should be 1");
	
	__block BOOL receivedValue = NO;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		receivedValue = valid;
	}];
	XCTAssertEqual(receivedValue, NO, @"Single element should be NO");
}


@end
