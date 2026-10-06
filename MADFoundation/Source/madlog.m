//
//  madlog.m
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"

#if __APPLE__
#import <Foundation/NSObjCRuntime.h>
#import <os/log.h>

static os_log_t gMADFoundationLog;

os_log_t GetFoundationLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADFoundationLog = os_log_create("com.mt", "madfoundation");
		if (gMADFoundationLog == nil || gMADFoundationLog == OS_LOG_DISABLED || gMADFoundationLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADFoundation log facility could not be created as specified, using default.");
			if (gMADFoundationLog == nil) gMADFoundationLog = OS_LOG_DEFAULT;
		}
		os_log_debug(gMADFoundationLog, "MADFoundation log facility initialized.");
	});
	return gMADFoundationLog;
}
#else
void MADLogEmit(int priority, NSString *message) {
	fprintf(stderr, "[MADFoundation] %s\n", message.UTF8String);
	syslog(priority, "%s", message.UTF8String);
}
#endif
