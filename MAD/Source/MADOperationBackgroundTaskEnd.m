//
//  MADOperationBackgroundTaskEnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationBackgroundTaskEnd.h"
#import "MADOperationBackgroundTaskBegin.h"
#import <MADFoundation/madlog.h>

@implementation MADOperationBackgroundTaskEnd

- (void)dealloc { }

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	// This operation does nothing.  Code is left here to show old behavior.
	[self finish];
	return;
/*
	UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	NSArray<NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationBackgroundTaskProtocol)]) {
			backgroundTaskIdentifier = [(id <MADOperationBackgroundTaskProtocol>)dependency backgroundTaskIdentifier];
		}
	}
	if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
		[self finish];
	} else {
		NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:23 userInfo:nil];
		[self finishWithError:error];
	}
*/
}

@end
