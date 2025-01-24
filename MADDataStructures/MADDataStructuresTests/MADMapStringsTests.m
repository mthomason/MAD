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

// MARK: - Factory Method Tests
- (void)testFactoryMethodCreatesCorrectSubclass {
	MADMapStrings *shortMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeShort];
	XCTAssertTrue([shortMap isKindOfClass:[MADMapStringsShort class]]);
	
	MADMapStrings *intMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeInteger];
	XCTAssertTrue([intMap isKindOfClass:[MADMapStringsInteger class]]);
	
	MADMapStrings *uintMap = [[MADMapStrings alloc] initWithType:MADMapDataTypeUnsignedInteger];
	XCTAssertTrue([uintMap isKindOfClass:[MADMapStringsUnsignedInteger class]]);
}

// MARK: - Integer Map Tests
- (void)testIntegerMap {
	MADMapStringsInteger *map = [[MADMapStringsInteger alloc] init];
	
	[map setObject:@"Value1" toKey:1];
	[map setObject:@"Value2" toKey:2];
	
	XCTAssertEqual([map count], 2);
	XCTAssertEqualObjects([map objectAtIndex:1], @"Value1");
	XCTAssertEqualObjects([map objectAtIndex:2], @"Value2");
	
	[map setObject:nil toKey:1];
	XCTAssertEqual([map count], 1);
	XCTAssertNil([map objectAtIndex:1]);
	
	XCTAssertNil([map objectAtIndex:999]);
}

// MARK: - Short Map Tests
- (void)testShortMap {
	MADMapStringsShort *map = [[MADMapStringsShort alloc] init];
	short key1 = 1;
	short key2 = 2;
	
	[map setObject:@"Value1" toKey:key1];
	[map setObject:@"Value2" toKey:key2];
	
	XCTAssertEqual([map count], 2);
	XCTAssertEqualObjects([map objectAtIndex:key1], @"Value1");
	XCTAssertEqualObjects([map objectAtIndex:key2], @"Value2");
	
	[map setObject:nil toKey:key1];
	XCTAssertEqual([map count], 1);
}

// MARK: - Unsigned Integer Map Tests
- (void)testUnsignedIntegerMap {
	MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
	NSUInteger key1 = 1;
	NSUInteger key2 = 2;
	
	[map setObject:@"Value1" toKey:key1];
	[map setObject:@"Value2" toKey:key2];
	
	XCTAssertEqual([map count], 2);
	XCTAssertEqualObjects([map objectAtIndex:key1], @"Value1");
	XCTAssertEqualObjects([map objectAtIndex:key2], @"Value2");
	
	[map setObject:nil toKey:key1];
	XCTAssertEqual([map count], 1);
}

// MARK: - Edge Cases
- (void)testStringWithEmbeddedNull {
	MADMapStringsInteger *map = [[MADMapStringsInteger alloc] init];
	const char bytes[] = "Hello\0World";
	NSString *testString = [[NSString alloc] initWithBytes:bytes length:11 encoding:NSUTF8StringEncoding];
	[map setObject:testString toKey:1];
	XCTAssertEqualObjects([map objectAtIndex:1], testString);
}

- (void)testEmptyString {
	MADMapStringsShort *map = [[MADMapStringsShort alloc] init];
	[map setObject:@"" toKey:1];
	XCTAssertEqualObjects([map objectAtIndex:1], @"");
}

- (void)testLargeKey {
	MADMapStringsUnsignedInteger *map = [[MADMapStringsUnsignedInteger alloc] init];
	NSUInteger largeKey = NSUIntegerMax;
	[map setObject:@"Large" toKey:largeKey];
	XCTAssertEqualObjects([map objectAtIndex:largeKey], @"Large");
}

@end
