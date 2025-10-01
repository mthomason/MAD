//
//  madlog.m
//  MADExplorer
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
		gMADExplorerLog = os_log_create("com.mt", "madexplorer");
		if (gMADExplorerLog == nil || gMADExplorerLog == OS_LOG_DISABLED || gMADExplorerLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADExplorer log facility could not be created as specified, using default.");
			if (gMADExplorerLog == nil) gMADExplorerLog = OS_LOG_DEFAULT;
		}
		os_log_debug(gMADExplorerLog, "MADExplorer log facility initialized.");
	});
	return gMADExplorerLog;
}
