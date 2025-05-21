//
//  UIApplication+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UIApplication+Extras.h"

@implementation UIApplication (Extras)

+ (NSString *)version {
	return CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
}

- (UIBackgroundTaskIdentifier)requestBackgroundTask {
	__block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
	bgTask = [self beginBackgroundTaskWithExpirationHandler:^{
		// Use the current value of bgTask
		[self endBackgroundTask:bgTask];
		bgTask = UIBackgroundTaskInvalid; // Reset the task identifier
	}];
	return bgTask;
}

- (void)handoffBackground:(NSNumber *)bgTask {
	[self endBackgroundTask:bgTask.unsignedIntegerValue];
}

- (void)handoffBackgroundUsingTimer:(NSNumber *)bgTask {
	
	NSTimeInterval time = self.backgroundTimeRemaining > 7.0 ? 5.0 : self.backgroundTimeRemaining - 0.1;
	[NSTimer scheduledTimerWithTimeInterval: time
									 target: self
								   selector: @selector(handoffBackground:)
								   userInfo: bgTask
									repeats: NO];
	
}

@end
