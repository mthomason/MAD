//
//  madlog.m
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/Foundation.h>

static os_log_t gMADFoundationLog;

os_log_t GetFoundationLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *category = NSStringFromClass([NSOperation class]);
		gMADFoundationLog = os_log_create("com.mt", category.UTF8String);
		if (gMADFoundationLog == nil || gMADFoundationLog == OS_LOG_DISABLED || gMADFoundationLog == OS_LOG_DEFAULT) {
			// Fallback or log an issue with a more basic mechanism if critical
			// For simplicity, os_log_create often defaults to a usable log handle.
			NSLog(@"Warning: MADOperations log facility could not be created as specified, using default.");
			if (gMADFoundationLog == nil) gMADFoundationLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADFoundationLog, "MADOperations log facility initialized.");
	});
	return gMADFoundationLog;
}
