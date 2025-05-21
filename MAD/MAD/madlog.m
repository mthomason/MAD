//
//  madlog.c
//  MAD
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>

static os_log_t gMADLog;

os_log_t GetMadLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADLog = os_log_create("com.mt", "mad");
		if (gMADLog == nil || gMADLog == OS_LOG_DISABLED || gMADLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADOperations log facility could not be created as specified, using default.");
			if (gMADLog == nil) gMADLog = OS_LOG_DEFAULT; // Ensure it's not nil
		}
		os_log_info(gMADLog, "MADOperations log facility initialized.");
	});
	return gMADLog;
}
