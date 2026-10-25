//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADErrorContainerTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADErrorContainerTests.m: the error accumulator --
//  counting, copy-on-read of the error objects, merging containers and the
//  two human-readable log formats.
//

#import "MADTestSupport.h"
#import <MADAPI/MADErrorContainer.h>

static NSError *sampleError(void) {
	return [NSError errorWithDomain:@"com.example.tests" code:42 userInfo:@{
		NSLocalizedDescriptionKey: @"Something went wrong",
		NSLocalizedFailureReasonErrorKey: @"Because testing",
	}];
}

static void testInitIsEmpty(void) {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	MAD_PASS(container.count == (NSUInteger)0, "a new container is empty");
	MAD_PASS(container.allObjects.count == (NSUInteger)0, "and holds no objects");
	MAD_PASS_EQUAL(container.errorLog, @"", "the log is empty");
	MAD_PASS_EQUAL(container.errorLogCompact, @"", "the compact log is empty");
}

static void testAddErrorIncrementsCount(void) {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:sampleError()];
	MAD_PASS(container.count == (NSUInteger)1, "one error");
	[container addError:sampleError()];
	MAD_PASS(container.count == (NSUInteger)2, "two errors");
}

static void testAllObjectsReturnsCopies(void) {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:sampleError()];

	NSArray<NSError *> *all = [container allObjects];
	MAD_PASS(all.count == (NSUInteger)1, "one object comes back");
	MAD_PASS(all.firstObject.code == 42, "the code survives");
	MAD_PASS_EQUAL(all.firstObject.domain, @"com.example.tests", "the domain survives");
}

static void testErrorLogContainsDescription(void) {
	MADErrorContainer *container = [[MADErrorContainer alloc] init];
	[container addError:sampleError()];
	MAD_PASS([container.errorLog containsString:@"Something went wrong"], "the log carries the description");
	MAD_PASS([container.errorLogCompact containsString:@"Something went wrong"], "the compact log carries it too");
}

static void testAddErrorsFromContainer(void) {
	MADErrorContainer *a = [[MADErrorContainer alloc] init];
	[a addError:sampleError()];
	[a addError:sampleError()];

	MADErrorContainer *b = [[MADErrorContainer alloc] init];
	[b addError:sampleError()];
	[b addErrorsFromContainer:a];

	MAD_PASS(b.count == (NSUInteger)3, "the target has all three");
	MAD_PASS(a.count == (NSUInteger)2, "the source is unchanged");
}

MAD_TEST_MAIN("MADErrorContainerTests",
	MAD_TEST(testInitIsEmpty),
	MAD_TEST(testAddErrorIncrementsCount),
	MAD_TEST(testAllObjectsReturnsCopies),
	MAD_TEST(testErrorLogContainsDescription),
	MAD_TEST(testAddErrorsFromContainer));
