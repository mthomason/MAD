//
//  MADTestSupport.h
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Glue over GNUstep's Testing.h (gnustep-make's TestFramework), which is the
//  zero-dependency runner on Linux -- there is no XCTest for Objective-C
//  here.  Two properties of the stock header shape this glue:
//
//    * Testing.h's PASS/PASS_EQUAL set only the testPassed variable
//      (last-write-wins), and END_SET's setEnded hook reports only sets ended
//      by an exception.  Neither can latch an assertion failure, so
//      MAD_PASS/MAD_PASS_EQUAL count failures themselves before calling
//      pass().  MAD_TEST_MAIN latches escaping exceptions through setEnded.
//    * Testing.h is manual-retain-release: the test translation units build
//      with -fno-objc-arc while the library stays ARC (a per-TU matter).
//
//  A ported test file reads:
//
//    #import "MADTestSupport.h"
//    #import <MADFoundation/MADProgress.h>
//
//    static void testCopy(void) {
//        MADProgress *p = [[MADProgress alloc] initWithMessage:@"x" andProgress:0];
//        MAD_PASS_EQUAL(p.message, @"x", "message survives the copy");
//    }
//
//    MAD_TEST_MAIN("MADProgressTests", MAD_TEST(testCopy));
//

#ifndef MADTestSupport_h
#define MADTestSupport_h

#import "Testing.h"

static unsigned gMadTestChecks __attribute__((unused)) = 0;
static unsigned gMadTestFailures __attribute__((unused)) = 0;
static unsigned gMadTestNeeds __attribute__((unused)) = 0;
static unsigned gMadTestSetFailures __attribute__((unused)) = 0;

// END_SET reports a set ended by an exception (or by a SkipSet skip, which
// these tests do not use); counting it here is what makes a crashed test fail
// the run rather than vanish.
static void madTestSetEnded(const char *setName, BOOL completed, double duration) __attribute__((unused));
static void madTestSetEnded(const char *setName, BOOL completed, double duration) {
	(void)duration;
	if (!completed) {
		gMadTestSetFailures++;
		printf("MADTEST-FAIL set: %s (exception escaped)\n", setName);
	}
}

// pass() has a printf format attribute, so the format must be a literal --
// the same constraint Testing.h's own macros carry.
#define MAD_PASS(expression, format, ...) \
	do { \
		gMadTestChecks++; \
		int _madOk = (expression) ? 1 : 0; \
		pass(_madOk, "%s:%d ... " format, __FILE__, __LINE__, ##__VA_ARGS__); \
		if (!_madOk) gMadTestFailures++; \
	} while (0)

#define MAD_PASS_EQUAL(expression, expected, format, ...) \
	do { \
		gMadTestChecks++; \
		id _madGot = (expression); \
		id _madExpected = (expected); \
		int _madOk = (_madGot == _madExpected || [_madGot isEqual:_madExpected]) ? 1 : 0; \
		pass(_madOk, "%s:%d ... " format, __FILE__, __LINE__, ##__VA_ARGS__); \
		if (!_madOk) { \
			gMadTestFailures++; \
			fprintf(stderr, "        got %s, expected %s\n", \
				[[_madGot description] UTF8String], [[_madExpected description] UTF8String]); \
		} \
	} while (0)

// A need the platform cannot meet: counted, printed, and never a failure.
// Takes an NSString literal (not a printf format).  Leaves the test function
// early, so every test function must return void.
#define MAD_NEED(condition, message) \
	do { \
		if (!(condition)) { \
			gMadTestNeeds++; \
			fprintf(stderr, "NEED: %s\n", [(message) UTF8String]); \
			return; \
		} \
	} while (0)

// Runs the run loop until *flag is YES or the timeout elapses -- the XCTest
// waitForExpectations replacement, for tests whose completion comes back on a
// dispatch queue or the main thread.
static BOOL MADWaitForFlag(volatile BOOL *flag, NSTimeInterval timeout) __attribute__((unused));
static BOOL MADWaitForFlag(volatile BOOL *flag, NSTimeInterval timeout) {
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
	while (!*flag && deadline.timeIntervalSinceNow > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	return *flag != NO;
}

#define MAD_TEST(function) { #function, function }
typedef struct { const char *name; void (*function)(void); } MADTestEntry;

static int MADTestMain(const char *suite, const MADTestEntry *tests, size_t count) __attribute__((unused));
static int MADTestMain(const char *suite, const MADTestEntry *tests, size_t count) {
	setEnded = madTestSetEnded;
	size_t i;
	for (i = 0; i < count; i++) {
		START_SET(tests[i].name)
			tests[i].function();
		END_SET(tests[i].name)
	}
	unsigned failed = gMadTestFailures + gMadTestSetFailures;
	printf("MADTEST %s tests=%zu needs=%u failed=%u\n", suite, count, gMadTestNeeds, failed);
	if (failed > 0) {
		printf("FAIL %s: %u failure(s)\n", suite, failed);
		return 1;
	}
	printf("OK %s: %zu tests, %u check(s), %u need(s)\n", suite, count, gMadTestChecks, gMadTestNeeds);
	return 0;
}

#define MAD_TEST_MAIN(suite, ...) \
	static const MADTestEntry gMadTests[] = { __VA_ARGS__ }; \
	int main(void) { \
		@autoreleasepool { \
			return MADTestMain(suite, gMadTests, sizeof(gMadTests) / sizeof(gMadTests[0])); \
		} \
	}

#endif /* MADTestSupport_h */
