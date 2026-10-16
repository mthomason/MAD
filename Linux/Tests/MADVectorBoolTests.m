//
//  MADVectorBoolTests.m
//  Linux/Tests
//
//  Ported from MADDataStructuresTests/MADVectorBoolTests.m: the std::vector<bool>
//  wrapper -- pushing, the two convenience adders, enumeration with early
//  stop, and the debug string.
//

#import "MADTestSupport.h"
#import <MADDataStructures/MADVectorBool.h>

static void testVectorBool(void) {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	MAD_PASS(vector != nil, "the vector initializes");

	[vector push:YES];
	[vector push:NO];
	[vector addTrue];
	[vector addFalse];
	MAD_PASS([vector count] == 4, "count is 4 after adding four values");

	__block NSUInteger trueCount = 0;
	__block NSUInteger falseCount = 0;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		if (idx % 2 == 0) {
			MAD_PASS(valid == YES, "even indices are YES");
			trueCount++;
		} else {
			MAD_PASS(valid == NO, "odd indices are NO");
			falseCount++;
		}
	}];
	MAD_PASS(trueCount == 2, "two true values");
	MAD_PASS(falseCount == 2, "two false values");

	[vector push:YES];
	[vector push:NO];
	MAD_PASS([vector count] == 6, "count is 6 after adding two more values");

	NSArray<NSNumber *> *expectedValues = @[@YES, @NO, @YES, @NO, @YES, @NO];
	__block NSUInteger index = 0;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		MAD_PASS(idx == index, "the index matches the enumeration order");
		MAD_PASS(valid == expectedValues[idx].boolValue, "the value matches the expected vector");
		index++;
	}];
	MAD_PASS(index == expectedValues.count, "all elements enumerate");

	__block NSUInteger enumeratedCount = 0;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		enumeratedCount++;
		if (idx == 2) {
			*stop = YES;
		}
	}];
	MAD_PASS(enumeratedCount == 3, "enumeration stops after the requested index");
}

static void testEmptyVector(void) {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	MAD_PASS([vector count] == 0, "initial count is 0");

	__block NSUInteger callCount = 0;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		callCount++;
	}];
	MAD_PASS(callCount == 0, "nothing enumerates");

	MAD_PASS_EQUAL([vector debugQuickLookObject], @"", "the empty debug string is empty");
}

static void testDebugQuickLook(void) {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	[vector addTrue];
	[vector addFalse];
	[vector addTrue];
	MAD_PASS_EQUAL([vector debugQuickLookObject], @"YES\nNO\nYES\n", "the debug string matches the elements");
}

static void testPushNonStandardBOOL(void) {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	[vector push:2];
	MAD_PASS([vector count] == 1, "count is 1");
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		MAD_PASS(valid == YES, "a non-zero BOOL is YES");
	}];
}

static void testSingleElement(void) {
	MADVectorBool *vector = [[MADVectorBool alloc] init];
	[vector addFalse];
	MAD_PASS([vector count] == 1, "count is 1");

	__block BOOL receivedValue = YES;
	[vector enumerateBools:^(NSUInteger idx, BOOL valid, BOOL *stop) {
		receivedValue = valid;
	}];
	MAD_PASS(receivedValue == NO, "the single element is NO");
}

MAD_TEST_MAIN("MADVectorBoolTests",
	MAD_TEST(testVectorBool),
	MAD_TEST(testEmptyVector),
	MAD_TEST(testDebugQuickLook),
	MAD_TEST(testPushNonStandardBOOL),
	MAD_TEST(testSingleElement));
