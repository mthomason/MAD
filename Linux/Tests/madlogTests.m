//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  madlogTests.m
//  Linux/Tests
//
//  The Linux side of madlog.h: the os_log_* shims the frameworks' call sites
//  reach Linux through.  There is no Apple counterpart to port -- on Apple
//  these are os_log's own functions -- so everything here is new platform
//  behaviour and is pinned directly, plus the two cases the Xcode
//  madlogTests.m pins about the accessors (added with the master merge).
//
//  GNUstep's NSString formatting prints an os_log privacy annotation
//  ("%{public}@") literally, so MADLogFormat strips it; the first test group
//  is that stripper, the second is the macro path that keeps Apple's spelling
//  compiling and emitting, and the third is the handle accessors.
//

#import "MADTestSupport.h"
#import <MADFoundation/madlog.h>

static void testPlainFormatIsReturnedUnchanged(void) {
	NSString *format = @"%s: %@";
	MAD_PASS(MADLogFormat(format) == format, "a format with no annotation is not copied");
}

static void testPublicAnnotationIsStripped(void) {
	MAD_PASS_EQUAL(MADLogFormat(@"%{public}@"), @"%@", "a public object annotation is stripped");
	MAD_PASS_EQUAL(MADLogFormat(@"Failed: %{public}@"), @"Failed: %@", "the annotation is stripped mid-format");
}

static void testPrivateAndParameterizedAnnotationsAreStripped(void) {
	MAD_PASS_EQUAL(MADLogFormat(@"%{private}d"), @"%d", "a private annotation is stripped");
	MAD_PASS_EQUAL(MADLogFormat(@"%{errno}d"), @"%d", "a parameterized annotation group is stripped");
}

static void testSeveralAnnotationsAreStripped(void) {
	MAD_PASS_EQUAL(MADLogFormat(@"%{public}@ -> %{private}@"),
		@"%@ -> %@", "every annotation group in the format is stripped");
}

static void testPercentEscapeIsNotAnAnnotation(void) {
	MAD_PASS_EQUAL(MADLogFormat(@"100%%{public}@"), @"100%%{public}@", "an escape is not a specifier");
	MAD_PASS_EQUAL(MADLogFormat(@"%%d %{public}@"), @"%%d %@", "an escape before an annotation leaves both intact");
}

static void testMalformedAnnotationIsLeftAlone(void) {
	MAD_PASS_EQUAL(MADLogFormat(@"%{public"), @"%{public", "an unclosed annotation is not truncated");
	MAD_PASS_EQUAL(MADLogFormat(@"100%"), @"100%", "a trailing percent survives");
}

static void testFormattingThroughTheShim(void) {
	// What the os_log_* macros do with their format argument.
	NSString *string = [[NSString alloc] initWithFormat:MADLogFormat(@"%{public}@: %d"), @"value", 7];
	MAD_PASS_EQUAL(string, @"value: 7", "the stripped format formats normally");
}

static void testFoundationLogIsCreated(void) {
	// The Xcode case pins a real os_log handle (not nil, not OS_LOG_DISABLED);
	// the Linux shim's accessors are no-op handles by design (madlog.m), so the
	// platform's equivalent assertion is the one the shim contract makes:
	// GetFoundationLog() answers the no-op handle.
	MAD_PASS(GetFoundationLog() == NULL, "the Linux shim's handle is the no-op handle");
}

static void testFoundationLogIsStableAcrossCalls(void) {
	MAD_PASS(GetFoundationLog() == GetFoundationLog(), "the handle is stable across calls");
}

static void testHandleTypeAndConstants(void) {
	os_log_t created = os_log_create("com.mad", "tests");
	MAD_PASS(created == NULL, "os_log_create is the no-op handle");
	MAD_PASS(OS_LOG_DEFAULT == NULL, "OS_LOG_DEFAULT is the no-op handle");
	MAD_PASS(GetMadLog() == NULL, "the accessors are no-op handles");
	MAD_PASS(GetTdsLog() == NULL, "every framework accessor is a no-op handle");
}

static void testOsLogCallsCompileAndEmit(void) {
	// The call-site spellings the frameworks already have; the output goes to
	// stderr and is not asserted here -- compiling and not crashing is the
	// test.
	os_log(OS_LOG_DEFAULT, "os_log: %d", 1);
	os_log_debug(GetSqlite3Log(), "os_log_debug: %{public}@", @"debug");
	os_log_info(GetApiLog(), "os_log_info: %s", "info");
	os_log_error(GetMySqlLog(), "os_log_error: %{public}@", @"error");
	os_log_fault(GetFileManagerLog(), "os_log_fault: %@", @"fault");
	MADLogInfo("MADLogInfo: %{public}@", @"info");
	MADLogError("MADLogError: %@", @"error");
	MAD_PASS(YES, "the os_log_* and MADLog* spellings reach MADLogEmit");
}

MAD_TEST_MAIN("madlogTests",
	MAD_TEST(testPlainFormatIsReturnedUnchanged),
	MAD_TEST(testPublicAnnotationIsStripped),
	MAD_TEST(testPrivateAndParameterizedAnnotationsAreStripped),
	MAD_TEST(testSeveralAnnotationsAreStripped),
	MAD_TEST(testPercentEscapeIsNotAnAnnotation),
	MAD_TEST(testMalformedAnnotationIsLeftAlone),
	MAD_TEST(testFormattingThroughTheShim),
	MAD_TEST(testFoundationLogIsCreated),
	MAD_TEST(testFoundationLogIsStableAcrossCalls),
	MAD_TEST(testHandleTypeAndConstants),
	MAD_TEST(testOsLogCallsCompileAndEmit));
