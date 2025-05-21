//
//  madlog.c
//  MADSqlite3
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#include "madlog.h"

static os_log_t gMADSqlite3Log;

os_log_t GetMadLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADSqlite3Log = os_log_create("com.mt", "dblocal");
		if (gMADSqlite3Log == nil || gMADSqlite3Log == OS_LOG_DISABLED || gMADSqlite3Log == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADOperations log facility could not be created as specified, using default.");
			if (gMADSqlite3Log == nil) gMADSqlite3Log = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADSqlite3Log, "MADOperations log facility initialized.");
	});
	return gMADSqlite3Log;
}
