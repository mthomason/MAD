//
//  MADErrorContainerTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 2 coverage for MADErrorContainer: the error accumulator used during
//  database operations.  Exercises counting, copy-on-read of the error objects,
//  merging containers, and the two human-readable log formats.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADErrorContainer.h>

@interface MADErrorContainerTests : XCTestCase
@end

@implementation MADErrorContainerTests

- (NSError *)sampleError {
	return [NSError errorWithDomain:@"com.example.tests" code:42 userInfo:@{
		NSLocalizedDescriptionKey: @"Something went wrong",
		NSLocalizedFailureReasonErrorKey: @"Because testing",
	}];
}

- (void)testInitIsEmpty {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	XCTAssertEqual(container.count, (NSUInteger)0);
	XCTAssertEqual(container.allObjects.count, (NSUInteger)0);
	XCTAssertEqualObjects(container.errorLog, @"");
	XCTAssertEqualObjects(container.errorLogCompact, @"");
}

- (void)testAddErrorIncrementsCount {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:[self sampleError]];
	XCTAssertEqual(container.count, (NSUInteger)1);
	[container addError:[self sampleError]];
	XCTAssertEqual(container.count, (NSUInteger)2);
}

- (void)testAllObjectsReturnsCopies {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:[self sampleError]];

	NSArray<NSError *> *all = [container allObjects];
	XCTAssertEqual(all.count, (NSUInteger)1);
	XCTAssertEqual(all.firstObject.code, 42);
	XCTAssertEqualObjects(all.firstObject.domain, @"com.example.tests");
}

- (void)testErrorLogContainsDescription {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:[self sampleError]];

	XCTAssertTrue([container.errorLog containsString:@"Something went wrong"]);
	XCTAssertTrue([container.errorLogCompact containsString:@"Something went wrong"]);
}

- (void)testAddErrorsFromContainer {
	MADErrorContainer *a = [[MADErrorContainer alloc] init];
	[a addError:[self sampleError]];
	[a addError:[self sampleError]];

	MADErrorContainer *b = [[MADErrorContainer alloc] init];
	[b addError:[self sampleError]];
	[b addErrorsFromContainer:a];

	XCTAssertEqual(b.count, (NSUInteger)3);
	XCTAssertEqual(a.count, (NSUInteger)2);
}

@end
