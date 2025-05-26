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
		[self endBackgroundTask:bgTask];
		bgTask = UIBackgroundTaskInvalid;
	}];
	return bgTask;
}

@end
