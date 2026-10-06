//
//  madlog.m
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "madlog.h"

#if __APPLE__

// One helper behind every accessor.  The display name is what the accessors
// logged before they were consolidated; the category is what Console.app
// filters on, so the two are not derived from each other ("MADSqlite3"'s
// category keeps its long-standing "sqltite3" typo).
static os_log_t MADLogCreate(const char *category, const char *name, BOOL debugLevel) {
	os_log_t log = os_log_create("com.mt", category);
	if (log == nil || log == OS_LOG_DISABLED || log == OS_LOG_DEFAULT) {
		NSLog(@"Warning: %s log facility could not be created as specified, using default.", name);
		if (log == nil) log = OS_LOG_DEFAULT;
	}
	if (debugLevel) {
		os_log_debug(log, "%s log facility initialized.", name);
	} else {
		os_log_info(log, "%s log facility initialized.", name);
	}
	return log;
}

os_log_t GetFoundationLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madfoundation", "MADFoundation", YES); });
	return log;
}

os_log_t GetMadLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("mad", "MAD", NO); });
	return log;
}

os_log_t GetSqlite3Log(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("sqltite3", "MADSqlite3", NO); });
	return log;
}

os_log_t GetApiLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madapi", "MADAPI", NO); });
	return log;
}

os_log_t GetFileManagerLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madfilemanager", "MADFileManager", YES); });
	return log;
}

os_log_t GetMadExtLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madcocoaextensions", "MADCocoaExtensions", NO); });
	return log;
}

os_log_t GetMySqlLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madmysql", "MADMySQL", NO); });
	return log;
}

os_log_t GetDesignerLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("maddesigner", "MADDesigner", NO); });
	return log;
}

os_log_t GetExplorerLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madexplorer", "MADExplorer", YES); });
	return log;
}

os_log_t GetTdsLog(void) {
	static os_log_t log;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ log = MADLogCreate("madtds", "MADTds", NO); });
	return log;
}

#else
void MADLogEmit(int priority, NSString *message) {
	fprintf(stderr, "[MADFoundation] %s\n", message.UTF8String);
	syslog(priority, "%s", message.UTF8String);
}
#endif
