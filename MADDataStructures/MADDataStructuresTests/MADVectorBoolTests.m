//
//  MADVectorBoolTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/2/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
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

@end
