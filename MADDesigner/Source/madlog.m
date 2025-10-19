//
//  madlog.c
//  MAD Designer
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"
#import <Foundation/NSObjCRuntime.h>
#import <dispatch/once.h>

static os_log_t gMADDesignerLog;

os_log_t GetDesignerLog(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMADDesignerLog = os_log_create("com.mt", "maddesigner");
		if (gMADDesignerLog == nil || gMADDesignerLog == OS_LOG_DISABLED || gMADDesignerLog == OS_LOG_DEFAULT) {
			NSLog(@"Warning: MADDesigner log facility could not be created as specified, using default.");
			if (gMADDesignerLog == nil) gMADDesignerLog = OS_LOG_DEFAULT;
		}
		os_log_info(gMADDesignerLog, "MADDesigner log facility initialized.");
	});
	return gMADDesignerLog;
}
