//
//  MADMapStringsTests.m
//  MADDataStructuresTests
//
//  Created by Michael on 12/2/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MADMapStrings.h"

@interface MADMapStringsTests : XCTestCase

@end

@implementation MADMapStringsTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testMapStrings {
	@autoreleasepool {
		// Initialize the map
		MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
		XCTAssertNotNil(map, @"Map should be initialized properly");
		
		// Add some key-value pairs
		[map setObject:@"Three" toKey:3];
		[map setObject:@"Two Hundred" toKey:200];
		XCTAssertEqual([map count], 2, @"Count should reflect the added entries");
		
		@autoreleasepool {
			NSString *ttt = [NSString stringWithFormat:@"%@", @"Three hundred thirty three"];
			[map setObject:ttt toKey:333];
		}
		
		@autoreleasepool {
			NSString *ttt = [NSString stringWithFormat:@"%@", @"Thirty"];
			[map setObject:ttt toKey:30];
			ttt = nil; // Ensure no strong reference remains
		}
		
		// Overwrite existing keys
		[map setObject:@"Thirty" toKey:30];
		[map setObject:@"Forty-Seven" toKey:47];
		
		@autoreleasepool {
			NSString *ttt = [NSString stringWithFormat:@"%@", @"Three hundred thirty three again"];
			[map setObject:ttt toKey:333];
		}
		
		[map setObject:@"Eighty-Four" toKey:84];
		[map setObject:@"Four" toKey:4];
		
		// Test removing entries
		[map setObject:nil toKey:48]; // Non-existing key
		[map setObject:nil toKey:200]; // Existing key
		[map setObject:nil toKey:3];   // Existing key
		[map setObject:nil toKey:47];  // Existing key
		
		// Validate count after deletions
		XCTAssertEqual([map count], 4, @"Count should reflect the remaining entries");
		
		// Validate retrieval of values
		NSString *result = [map objectAtIndex:333];
		XCTAssertEqualObjects(result, @"Three hundred thirty three again", @"Should retrieve the correct value for key 333");
		
		result = [map objectAtIndex:30];
		XCTAssertEqualObjects(result, @"Thirty", @"Should retrieve the correct value for key 30");
		
		result = [map objectAtIndex:200];
		XCTAssertNil(result, @"Key 200 should have been removed");
		
		result = [map objectAtIndex:48];
		XCTAssertNil(result, @"Key 48 does not exist");
		
		// Boundary tests
		result = [map objectAtIndex:UINT_MAX];
		XCTAssertNil(result, @"Should handle out-of-bounds key gracefully");
		
		[map setObject:@"BoundaryTest" toKey:UINT_MAX];
		result = [map objectAtIndex:UINT_MAX];
		XCTAssertEqualObjects(result, @"BoundaryTest", @"Should handle maximum unsigned integer key correctly");
	}
}

@end
