//
//  madlog.m
//  MADSqlite3
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#include "madlog.h"

static os_log_t gMADExtLog;

os_log_t GetMadLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADExtLog = os_log_create("com.mt", "sqltite3");
		if (gMADExtLog == nil || gMADExtLog == OS_LOG_DISABLED || gMADExtLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADSqlite3 log facility could not be created as specified, using default.");
			if (gMADExtLog == nil) gMADExtLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADExtLog, "MADSqlite3 log facility initialized.");
	});
	return gMADExtLog;
}
