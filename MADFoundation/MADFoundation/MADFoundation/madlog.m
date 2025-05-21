//
//  madlog.m
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>
#import <os/log.h>

static os_log_t gMADFoundationLog;

os_log_t GetFoundationLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADFoundationLog = os_log_create("com.mt", "MADFoundation");
		if (gMADFoundationLog == nil || gMADFoundationLog == OS_LOG_DISABLED || gMADFoundationLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADOperations log facility could not be created as specified, using default.");
			if (gMADFoundationLog == nil) gMADFoundationLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADFoundationLog, "MADOperations log facility initialized.");
	});
	return gMADFoundationLog;
}
