//
//  NSOperationAdvancedTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/NSOperationAdvancedTests.m: coverage for
//  the NSOperation (Advanced) category -- the completion-block chaining (the
//  new block runs *after* the existing one, in that order) and the bulk
//  dependency adder.
//

#import "MADTestSupport.h"
#import <MADFoundation/NSOperation+Advanced.h>

#pragma mark - Completion blocks

static void testAddCompletionBlockOnAFreshOperation(void) {
	NSOperation *operation = [[NSOperation alloc] init];
	__block BOOL ran = NO;

	[operation addCompletionBlock:^{
		ran = YES;
	}];

	MAD_PASS(operation.completionBlock != nil, "the completion block is set");
	operation.completionBlock();
	MAD_PASS(ran, "the block ran");
}

static void testAddCompletionBlockChainsAfterTheExistingOne(void) {
	NSOperation *operation = [[NSOperation alloc] init];
	NSMutableArray<NSString *> *order = [NSMutableArray array];

	operation.completionBlock = ^{
		[order addObject:@"existing"];
	};
	[operation addCompletionBlock:^{
		[order addObject:@"added"];
	}];

	operation.completionBlock();

	MAD_PASS_EQUAL(order, (@[@"existing", @"added"]), "the existing block runs before the added one");
}

static void testChainedCompletionBlocksRunOnceEach(void) {
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

	MAD_PASS(existingCount == (NSUInteger)1, "the existing block ran once");
	MAD_PASS(addedCount == (NSUInteger)1, "the added block ran once");
}

#pragma mark - Dependencies

static void testAddDependenciesAddsEach(void) {
	NSOperation *operation = [[NSOperation alloc] init];
	NSOperation *first = [[NSOperation alloc] init];
	NSOperation *second = [[NSOperation alloc] init];

	[operation addDependencies:@[first, second]];

	MAD_PASS(operation.dependencies.count == (NSUInteger)2, "two dependencies");
	MAD_PASS([operation.dependencies containsObject:first], "the first dependency was added");
	MAD_PASS([operation.dependencies containsObject:second], "the second dependency was added");
}

static void testAddDependenciesWithAnEmptyArrayIsANoOp(void) {
	NSOperation *operation = [[NSOperation alloc] init];

	[operation addDependencies:@[]];

	MAD_PASS(operation.dependencies.count == (NSUInteger)0, "no dependencies were added");
	MAD_PASS(operation.isReady, "the operation is still ready");
}

MAD_TEST_MAIN("NSOperationAdvancedTests",
	MAD_TEST(testAddCompletionBlockOnAFreshOperation),
	MAD_TEST(testAddCompletionBlockChainsAfterTheExistingOne),
	MAD_TEST(testChainedCompletionBlocksRunOnceEach),
	MAD_TEST(testAddDependenciesAddsEach),
	MAD_TEST(testAddDependenciesWithAnEmptyArrayIsANoOp));
