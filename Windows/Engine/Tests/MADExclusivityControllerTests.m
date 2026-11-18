//
//  MADExclusivityControllerTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADExclusivityControllerTests.m: coverage
//  for MADExclusivityController, the app-wide singleton that chains
//  mutually-exclusive operations via dependencies.  Each test uses its own
//  category so the shared instance is not polluted across tests.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADExclusivityController.h>
#import <MADFoundation/MADOperation.h>

static void testSharedInstanceIsSingleton(void) {
	MADExclusivityController *a = [MADExclusivityController sharedExclusivityController];
	MADExclusivityController *b = [MADExclusivityController sharedExclusivityController];
	MAD_PASS(a != nil, "sharedExclusivityController is not nil");
	MAD_PASS(a == b, "sharedExclusivityController returns the same instance");
}

static void testFirstOperationHasNoDependency(void) {
	MADExclusivityController *controller = [MADExclusivityController sharedExclusivityController];
	MADOperation *op = [[MADOperation alloc] init];
	NSString *category = @"MADExclusivityControllerTests.firstOperation";

	[controller addOperation:op categories:@[category]];
	MAD_PASS(op.dependencies.count == (NSUInteger)0, "the first operation for a category has no dependency");

	[controller removeOperation:op categories:@[category]];
}

static void testSecondOperationDependsOnFirst(void) {
	MADExclusivityController *controller = [MADExclusivityController sharedExclusivityController];
	MADOperation *first = [[MADOperation alloc] init];
	MADOperation *second = [[MADOperation alloc] init];
	NSString *category = @"MADExclusivityControllerTests.secondOperation";

	[controller addOperation:first categories:@[category]];
	[controller addOperation:second categories:@[category]];

	MAD_PASS([second.dependencies containsObject:first], "the second operation for a category depends on the first");

	[controller removeOperation:first categories:@[category]];
	[controller removeOperation:second categories:@[category]];
}

MAD_TEST_MAIN("MADExclusivityControllerTests",
	MAD_TEST(testSharedInstanceIsSingleton),
	MAD_TEST(testFirstOperationHasNoDependency),
	MAD_TEST(testSecondOperationDependsOnFirst));
