//
//  NSOperationAdvancedTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the NSOperation (CompletionBlock) category: the completion-block
//  chaining (the new block runs *after* the existing one, in that order) and the
//  bulk dependency adder.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/NSOperation+CompletionBlock.h>

@interface NSOperationAdvancedTests : XCTestCase
@end

@implementation NSOperationAdvancedTests

#pragma mark - Completion blocks

- (void)testAddCompletionBlockOnAFreshOperation {
	NSOperation *operation = [[NSOperation alloc] init];
	__block BOOL ran = NO;

	[operation addCompletionBlock:^{
		ran = YES;
	}];

	XCTAssertNotNil(operation.completionBlock);
	operation.completionBlock();
	XCTAssertTrue(ran);
}

- (void)testAddCompletionBlockNilIsANoOp {
	NSOperation *operation = [[NSOperation alloc] init];
	__block BOOL existingRan = NO;
	operation.completionBlock = ^{
		existingRan = YES;
	};

	[operation addCompletionBlock:nil];
	operation.completionBlock();

	XCTAssertTrue(existingRan);

	NSOperation *fresh = [[NSOperation alloc] init];
	[fresh addCompletionBlock:nil];
	XCTAssertNil(fresh.completionBlock);
}

- (void)testAddCompletionBlockChainsAfterTheExistingOne {
	NSOperation *operation = [[NSOperation alloc] init];
	NSMutableArray<NSString *> *order = [NSMutableArray array];

	operation.completionBlock = ^{
		[order addObject:@"existing"];
	};
	[operation addCompletionBlock:^{
		[order addObject:@"added"];
	}];

	operation.completionBlock();

	XCTAssertEqualObjects(order, (@[@"existing", @"added"]));
}

- (void)testChainedCompletionBlocksRunOnceEach {
	NSOperation *operation = [[NSOperation alloc] init];
	__block NSUInteger existingCount = 0;
	__block NSUInteger addedCount = 0;

	operation.completionBlock = ^{
		existingCount++;
	};
	[operation addCompletionBlock:^{
		addedCount++;
	}];

	operation.completionBlock();

	XCTAssertEqual(existingCount, (NSUInteger)1);
	XCTAssertEqual(addedCount, (NSUInteger)1);
}

#pragma mark - Dependencies

- (void)testAddDependenciesAddsEach {
	NSOperation *operation = [[NSOperation alloc] init];
	NSOperation *first = [[NSOperation alloc] init];
	NSOperation *second = [[NSOperation alloc] init];

	[operation addDependencies:@[first, second]];

	XCTAssertEqual(operation.dependencies.count, (NSUInteger)2);
	XCTAssertTrue([operation.dependencies containsObject:first]);
	XCTAssertTrue([operation.dependencies containsObject:second]);
}

- (void)testAddDependenciesWithAnEmptyArrayIsANoOp {
	NSOperation *operation = [[NSOperation alloc] init];

	[operation addDependencies:@[]];

	XCTAssertEqual(operation.dependencies.count, (NSUInteger)0);
	XCTAssertTrue(operation.isReady);
}

@end
