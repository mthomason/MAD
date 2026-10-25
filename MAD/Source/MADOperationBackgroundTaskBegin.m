//
//  MADOperationBackgroundTaskBegin.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationBackgroundTaskBegin.h"
#import <MADFoundation/madlog.h>

//#import <UIKit/UIApplication.h>

@interface MADOperationBackgroundTaskBegin ()
//@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation MADOperationBackgroundTaskBegin

- (void)dealloc { }

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	// This operation does nothing.  Code is left here to show old behavior.
	[self finish];
	return;
/*
	MADOperationBackgroundTaskBegin * __weak weakself = self;
	NSString *taskName = @"com.everdayapps.operation.document.create.begin";
	self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName: taskName
																				 expirationHandler: ^{
		MADOperationBackgroundTaskBegin *sself = weakself;
		[[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskIdentifier];
		sself.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	}];

	if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
		[self finish];
	} else {
		NSString *domain = NSStringFromClass(self.class);
		NSError *error = [NSError errorWithDomain:domain code:22 userInfo:nil];
		[self finishWithError:error];
	}
*/
}

@end
