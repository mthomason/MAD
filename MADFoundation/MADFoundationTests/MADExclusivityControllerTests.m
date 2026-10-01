//
//  MADExclusivityControllerTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADExclusivityController: the app-wide singleton that chains
//  mutually-exclusive operations via dependencies.  Uses a unique category per
//  test to avoid polluting the shared instance.
//

#import <XCTest/XCTest.h>

#import "../Source/MADExclusivityController.h"
#import <MADFoundation/MADOperation.h>

@interface MADExclusivityControllerTests : XCTestCase
@end

@implementation MADExclusivityControllerTests

- (void)testSharedInstanceIsSingleton {
	MADExclusivityController *a = [MADExclusivityController sharedExclusivityController];
	MADExclusivityController *b = [MADExclusivityController sharedExclusivityController];
	XCTAssertNotNil(a);
	XCTAssertEqual(a, b);
}

- (void)testFirstOperationHasNoDependency {
	MADExclusivityController *controller = [MADExclusivityController sharedExclusivityController];
	MADOperation *op = [[MADOperation alloc] init];
	NSString *category = [NSString stringWithFormat:@"cat_%p", self];

	[controller addOperation:op categories:@[category]];
	XCTAssertEqual(op.dependencies.count, (NSUInteger)0);

	[controller removeOperation:op categories:@[category]];
}

- (void)testSecondOperationDependsOnFirst {
	MADExclusivityController *controller = [MADExclusivityController sharedExclusivityController];
	MADOperation *first = [[MADOperation alloc] init];
	MADOperation *second = [[MADOperation alloc] init];
	NSString *category = [NSString stringWithFormat:@"cat_%p", self];

	[controller addOperation:first categories:@[category]];
	[controller addOperation:second categories:@[category]];

	XCTAssertTrue([second.dependencies containsObject:first]);

	[controller removeOperation:first categories:@[category]];
	[controller removeOperation:second categories:@[category]];
}

@end
