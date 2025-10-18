//
//  madlog.m
//  MADFileManager
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>

static os_log_t gMADFileManagerLog;

os_log_t GetFileManagerLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADFileManagerLog = os_log_create("com.mt", "madfilemanager");
		if (gMADFileManagerLog == nil || gMADFileManagerLog == OS_LOG_DISABLED || gMADFileManagerLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADFileManager log facility could not be created as specified, using default.");
			if (gMADFileManagerLog == nil) gMADFileManagerLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_debug(gMADFileManagerLog, "MADFileManager log facility initialized.");
	});
	return gMADFileManagerLog;
}
