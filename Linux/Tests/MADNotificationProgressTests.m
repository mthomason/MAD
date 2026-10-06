//
//  MADNotificationProgressTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADNotificationProgressTests.m: coverage for
//  MADNotificationProgress, the singleton that posts progress notifications,
//  plus its notification-name/key constants.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADProgress.h>

static void testSharedObjectIsSingleton(void) {
	MADNotificationProgress *a = [MADNotificationProgress sharedObject];
	MADNotificationProgress *b = [MADNotificationProgress sharedObject];
	MAD_PASS(a != nil, "sharedObject is not nil");
	MAD_PASS(a == b, "sharedObject returns the same instance");
}

static void testCopyReturnsSelf(void) {
	MADNotificationProgress *a = [MADNotificationProgress sharedObject];
	MAD_PASS([a copy] == a, "copy returns the singleton itself");
}

static void testNotificationConstants(void) {
	MAD_PASS_EQUAL(MADNotificationProgressIdentifier, @"MADProgressNotification", "the notification name");
	MAD_PASS_EQUAL(MADNotificationProgressKey, @"p", "the user-info key");
}

static void testUpdateProgressOfObjectPostsNotification(void) {
	MADNotificationProgress *notifier = [MADNotificationProgress sharedObject];
	NSObject *object = [[NSObject alloc] init];
	// The singleton throttles posts to 1/60s; back off to let the throttle pass.
	[NSThread sleepForTimeInterval:0.1];

	__block id capturedObject = nil;
	__block MADProgress *capturedProgress = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationProgressIdentifier
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		// MRC __block variables do not retain, and the notification's
		// userInfo dictionary dies with the post; hold on to what we keep.
		capturedObject = [note.object retain];
		capturedProgress = [note.userInfo[MADNotificationProgressKey] retain];
	}];

	[notifier updateProgressOfObject:object withMessage:@"hello" progress:0.75f];

	MAD_PASS(capturedObject == object, "the notification object is the updated object");
	MAD_PASS(capturedProgress != nil, "the user info carries a MADProgress");
	MAD_PASS_EQUAL(capturedProgress.message, @"hello", "the progress message");
	MAD_PASS(capturedProgress.progress == 0.75f, "the progress value");

	// Removed after the assertions: MRC retains nothing for the observer
	// block's __block captures, so they must be read while the block is alive.
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
}

MAD_TEST_MAIN("MADNotificationProgressTests",
	MAD_TEST(testSharedObjectIsSingleton),
	MAD_TEST(testCopyReturnsSelf),
	MAD_TEST(testNotificationConstants),
	MAD_TEST(testUpdateProgressOfObjectPostsNotification));
