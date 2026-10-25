//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADFileInfoTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADFileInfoTests.m: MADFileInfo's URL and
//  name handling, copying, equality and hashing, and the asynchronous size
//  fetch.  The Xcode setUp/tearDown pair is a fresh temp directory and file
//  per test here.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADFileInfo.h>

static NSURL *makeTempFile(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:nil];
	NSURL *directory = [NSURL fileURLWithPath:path];
	NSURL *file = [directory URLByAppendingPathComponent:@"doc.mad"];
	[@"data" writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
	return file;
}

static void testInitStoresURL(void) {
	NSURL *file = makeTempFile();
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:file];
	MAD_PASS_EQUAL(info.URL, file, "the URL is stored");
}

static void testNameStripsExtension(void) {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:makeTempFile()];
	MAD_PASS_EQUAL(info.name, @"doc", "the name drops the extension");
}

static void testNameEmptyForNilURL(void) {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:nil];
	MAD_PASS_EQUAL(info.name, @"", "a nil URL yields an empty name");
}

static void testCopy(void) {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:makeTempFile()];
	MADFileInfo *copy = [info copy];
	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS_EQUAL(copy.URL, info.URL, "the copy carries the same URL");
	MAD_PASS(copy != info, "the copy is a different object");
}

static void testEquality(void) {
	NSURL *file = makeTempFile();
	MADFileInfo *a = [[MADFileInfo alloc] initWithURL:file];
	MADFileInfo *b = [[MADFileInfo alloc] initWithURL:file];
	MAD_PASS_EQUAL(a, b, "equal URLs are equal objects");

	NSURL *other = [[file URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"other.mad"];
	MADFileInfo *c = [[MADFileInfo alloc] initWithURL:other];
	MAD_PASS(![a isEqual:c], "different URLs are different objects");
}

static void testEqualObjectsHaveEqualHashes(void) {
	NSURL *file = makeTempFile();
	MADFileInfo *a = [[MADFileInfo alloc] initWithURL:file];
	MADFileInfo *b = [[MADFileInfo alloc] initWithURL:file];
	MAD_PASS_EQUAL(a, b, "equal URLs are equal objects");
	MAD_PASS(a.hash == b.hash, "equal objects hash equally");
}

static void testFetchInfoCallsCompletion(void) {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:makeTempFile()];
	__block BOOL called = NO;
	[info fetchInfoWithCompletionHandler:^{
		called = YES;
	}];
	// Generous: the fetch is a dispatch hop, but a cold image running every
	// suite in parallel has been seen to miss a five-second deadline once.
	MAD_PASS(MADWaitForFlag(&called, 30.0), "the fetch completion is called");
}

MAD_TEST_MAIN("MADFileInfoTests",
	MAD_TEST(testInitStoresURL),
	MAD_TEST(testNameStripsExtension),
	MAD_TEST(testNameEmptyForNilURL),
	MAD_TEST(testCopy),
	MAD_TEST(testEquality),
	MAD_TEST(testEqualObjectsHaveEqualHashes),
	MAD_TEST(testFetchInfoCallsCompletion));
