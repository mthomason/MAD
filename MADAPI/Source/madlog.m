//
//  madlog.c
//  MADAPI
//
//  Created by Michael on 6/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>
#import <dispatch/once.h>

static os_log_t gApiLog;

os_log_t GetApiLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gApiLog = os_log_create("com.mt", "madapi");
		if (gApiLog == nil || gApiLog == OS_LOG_DISABLED || gApiLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADAPI log facility could not be created as specified, using default.");
			if (gApiLog == nil) gApiLog = OS_LOG_DEFAULT;
		}
		os_log_info(gApiLog, "MADAPI log facility initialized.");
	});
	return gApiLog;
}
