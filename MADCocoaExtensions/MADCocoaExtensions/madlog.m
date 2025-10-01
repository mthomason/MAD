//
//  madlog.m
//  MADCocoaExtensions
//
//  Created by Michael on 7/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//


#include "madlog.h"

static os_log_t gMADExtLog;

os_log_t GetMadExtLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADExtLog = os_log_create("com.mt", "madcocoaextensions");
		if (gMADExtLog == nil || gMADExtLog == OS_LOG_DISABLED || gMADExtLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADCocoaExtensions log facility could not be created as specified, using default.");
			if (gMADExtLog == nil) gMADExtLog = OS_LOG_DEFAULT;
		}
		os_log_info(gMADExtLog, "MADCocoaExtensions log facility initialized.");
	});
	return gMADExtLog;
}
