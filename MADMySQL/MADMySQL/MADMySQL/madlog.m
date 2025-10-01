//
//  madlog.c
//  MADMySQL
//
//  Created by Michael on 6/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>
#import <dispatch/once.h>

static os_log_t gMySqlLog;

os_log_t GetMySqlLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMySqlLog = os_log_create("com.mt", "madmysql");
		if (gMySqlLog == nil || gMySqlLog == OS_LOG_DISABLED || gMySqlLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADMySQL log facility could not be created as specified, using default.");
			if (gMySqlLog == nil) gMySqlLog = OS_LOG_DEFAULT;
		}
		os_log_info(gMySqlLog, "MADMySQL log facility initialized.");
	});
	return gMySqlLog;
}
