//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADFileUtilitiesTests.m
//  Linux/Tests
//
//  Ported from MADFileManagerTests/MADFileUtilitiesTests.m: the pure
//  filesystem helpers on MADFileUtilities, surfaced through the same
//  test-only category the Xcode suite uses.
//

#import "MADTestSupport.h"
#import <MADFileManager/MADFileUtilities.h>

@interface MADFileUtilities (TestAccess)
+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url;
+ (NSArray <NSURL *> *)contentsOfDirectory:(NSURL *)directory withPathExtension:(NSString *)extension;
+ (BOOL)removeContentsOfDirectory:(NSURL *)directory;
@end

static NSURL *uniqueTempDirectoryURL(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	return [NSURL fileURLWithPath:path];
}

static void testQueueIsSingleton(void) {
	MAD_PASS([MADFileUtilities queue] != nil, "the queue exists");
	MAD_PASS([MADFileUtilities queue] == [MADFileUtilities queue], "the queue is a singleton");
}

static void testCreateDirectoryForUrlIfItDoesNotExist(void) {
	NSURL *directory = uniqueTempDirectoryURL();
	MAD_PASS([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:directory], "the directory is created");

	BOOL isDirectory = NO;
	MAD_PASS([[NSFileManager defaultManager] fileExistsAtPath:directory.path isDirectory:&isDirectory],
			 "the directory exists");
	MAD_PASS(isDirectory, "the path is a directory");

	MAD_PASS([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:directory],
			 "creating an existing directory still reports success");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testContentsOfDirectoryFiltersByExtension(void) {
	NSURL *directory = uniqueTempDirectoryURL();
	MAD_PASS([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:directory], "the directory is created");
	[@"a" writeToURL:[directory URLByAppendingPathComponent:@"a.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"b" writeToURL:[directory URLByAppendingPathComponent:@"b.mad"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"c" writeToURL:[directory URLByAppendingPathComponent:@"c.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"d" writeToURL:[directory URLByAppendingPathComponent:@"d"] atomically:YES encoding:NSUTF8StringEncoding error:nil];

	NSArray *txt = [MADFileUtilities contentsOfDirectory:directory withPathExtension:@"txt"];
	MAD_PASS(txt.count == 2, "two txt files");
	NSArray *mad = [MADFileUtilities contentsOfDirectory:directory withPathExtension:@"mad"];
	MAD_PASS(mad.count == 1, "one mad file");
	NSArray *none = [MADFileUtilities contentsOfDirectory:directory withPathExtension:@"zzz"];
	MAD_PASS(none.count == 0, "no zzz files");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testRemoveContentsOfDirectoryAlsoRemovesDirectory(void) {
	// The method name promises to remove only the contents, but it also
	// deletes the directory itself (as the Xcode suite documents).
	NSURL *directory = uniqueTempDirectoryURL();
	MAD_PASS([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:directory], "the directory is created");
	[@"a" writeToURL:[directory URLByAppendingPathComponent:@"a.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];

	MAD_PASS([MADFileUtilities removeContentsOfDirectory:directory], "the removal reports success");
	MAD_PASS(![[NSFileManager defaultManager] fileExistsAtPath:directory.path], "the directory itself is gone");
}

MAD_TEST_MAIN("MADFileUtilitiesTests",
	MAD_TEST(testQueueIsSingleton),
	MAD_TEST(testCreateDirectoryForUrlIfItDoesNotExist),
	MAD_TEST(testContentsOfDirectoryFiltersByExtension),
	MAD_TEST(testRemoveContentsOfDirectoryAlsoRemovesDirectory));
