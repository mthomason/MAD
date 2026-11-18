//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADNotificationAndOperationTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADNotificationAndOperationTests.m: coverage for the
//  two small notifications and MADOperationUniqueUrlForFilename.  Page 0 always
//  posts (0 % interval == 0) and resets the pacing, so it is the one page that
//  can be asserted regardless of what ran before.  The blocks run synchronously
//  on the posting thread (queue nil), but MRC __block variables do not retain
//  and GNUstep releases the posted notification as soon as the post returns,
//  so the captures hold on to what the assertions need and are read while the
//  observer block is still alive.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADOperation.h>

#import <MAD/MADNotificationDidFormatPage.h>
#import <MAD/MADNotificationFileUpdate.h>
#import <MAD/MADNotificationProtocol.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>

#pragma mark - MADNotificationDidFormatPage

static void testFormatPageSingletonIdentity(void) {
	MADNotificationDidFormatPage *a = [MADNotificationDidFormatPage sharedObject];
	MADNotificationDidFormatPage *b = [MADNotificationDidFormatPage sharedObject];

	MAD_PASS(a != nil, "the singleton exists");
	MAD_PASS(a == b, "two lookups give the same object");
	MAD_PASS([a copy] == a, "the copy is the singleton itself");
}

static void testFormatPageZeroPostsNotification(void) {
	MADNotificationDidFormatPage *notifier = [MADNotificationDidFormatPage sharedObject];
	id formatter = [[NSObject alloc] init];

	__block NSNotification *captured = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationDidFormatPagesName
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		// MRC __block variables do not retain, and the notification dies with
		// the post; hold on to it for the assertions.
		captured = [note retain];
	}];

	[notifier reportFormatter:formatter formattedPage:0];

	MAD_PASS(captured != nil, "page 0 posts the notification");
	MAD_PASS(captured.object == formatter, "the formatter is the notification's object");
	MAD_PASS_EQUAL(captured.userInfo[MTDatabaseNumberOfPagesFormattedKey], @0, "the formatted page rides in the userInfo");
	[captured release];

	// Removed after the assertions: MRC retains nothing for the observer
	// block's __block captures, so they must be read while the block is alive.
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
	[formatter release];
}

#pragma mark - MADNotificationFileUpdate

static void testFileUpdateNotifyPostsURL(void) {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/Report.mad"];
	MADNotificationFileUpdate *update = [[MADNotificationFileUpdate alloc] initWithURL:url];

	__block NSNotification *captured = nil;
	__block NSUInteger count = 0;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationIdentifierFileUpdate
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		// MRC __block variables do not retain, and the notification dies with
		// the post; hold on to it for the assertions.
		captured = [note retain];
		count++;
	}];

	[update notify];

	MAD_PASS(count == (NSUInteger)1, "one notification is posted");
	MAD_PASS_EQUAL(captured.object, url, "the URL is the notification's object");
	[captured release];

	// Removed after the assertions: MRC retains nothing for the observer
	// block's __block captures, so they must be read while the block is alive.
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	[update release];
}

#pragma mark - MADOperationUniqueUrlForFilename

static NSURL *temporaryDirectory(void) {
	NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
								  isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	return directory;
}

static void testUniqueUrlForFreeFilename(void) {
	NSURL *directory = temporaryDirectory();
	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@"mad"
															 andDocumentsDirectory:directory];

	MAD_PASS(operation.isAsynchronous, "the operation runs asynchronously");

	[operation execute];

	MAD_PASS(operation.isFinished, "the operation finishes");
	MAD_PASS(operation.uniqueUrl != nil, "a unique URL is resolved");
	MAD_PASS_EQUAL(operation.uniqueUrl.lastPathComponent, @"Report.mad", "the free filename is used untouched");
	MAD_PASS_EQUAL(operation.uniqueUrl.URLByDeletingLastPathComponent.path, directory.path, "the URL lands in the requested directory");

	[operation release];
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testUniqueUrlSkipsExistingFile(void) {
	NSURL *directory = temporaryDirectory();
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@"mad"
															 andDocumentsDirectory:directory];
	[operation execute];

	MAD_PASS_EQUAL(operation.uniqueUrl.lastPathComponent, @"Report 0.mad", "a taken name gets a numbered sibling");

	[operation release];
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testUniqueUrlWithoutExtension(void) {
	NSURL *directory = temporaryDirectory();
	MADOperationUniqueUrlForFilename *operation;
	operation = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename:@"Report"
																	pathExtension:@""
															 andDocumentsDirectory:directory];
	[operation execute];

	MAD_PASS_EQUAL(operation.uniqueUrl.lastPathComponent, @"Report", "an empty extension leaves the name alone");

	[operation release];
	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

MAD_TEST_MAIN("MADNotificationAndOperationTests",
	MAD_TEST(testFormatPageSingletonIdentity),
	MAD_TEST(testFormatPageZeroPostsNotification),
	MAD_TEST(testFileUpdateNotifyPostsURL),
	MAD_TEST(testUniqueUrlForFreeFilename),
	MAD_TEST(testUniqueUrlSkipsExistingFile),
	MAD_TEST(testUniqueUrlWithoutExtension));
