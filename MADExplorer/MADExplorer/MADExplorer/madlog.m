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

static os_log_t gMADExplorerLog;

os_log_t GetExplorerLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADExplorerLog = os_log_create("com.mt", "MADFoundation");
		if (gMADExplorerLog == nil || gMADExplorerLog == OS_LOG_DISABLED || gMADExplorerLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADOperations log facility could not be created as specified, using default.");
			if (gMADExplorerLog == nil) gMADExplorerLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADExplorerLog, "MADOperations log facility initialized.");
	});
	return gMADExplorerLog;
}
