//
//  madlog.m
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
// The accessors exist off Apple only so the call sites that store a handle
// (`os_log_t log = GetMadLog();`) still compile: every one is a no-op, and
// MADLogEmit below is what actually logs.  The categories the Apple branch
// gives each accessor have no Linux equivalent here.
#define MAD_LOG_NOOP_ACCESSOR(name) \
	os_log_t name(void) { return NULL; }
MAD_LOG_NOOP_ACCESSOR(GetFoundationLog)
MAD_LOG_NOOP_ACCESSOR(GetMadLog)
MAD_LOG_NOOP_ACCESSOR(GetSqlite3Log)
MAD_LOG_NOOP_ACCESSOR(GetApiLog)
MAD_LOG_NOOP_ACCESSOR(GetFileManagerLog)
MAD_LOG_NOOP_ACCESSOR(GetMadExtLog)
MAD_LOG_NOOP_ACCESSOR(GetMySqlLog)
MAD_LOG_NOOP_ACCESSOR(GetDesignerLog)
MAD_LOG_NOOP_ACCESSOR(GetExplorerLog)
MAD_LOG_NOOP_ACCESSOR(GetTdsLog)
#undef MAD_LOG_NOOP_ACCESSOR

// Strip os_log's privacy annotations -- "%{public}@", "%{private}d", any
// "%{...}" group -- because GNUstep's formatter would print the braces
// literally.  A "%%" escape is not a specifier, so "{...}" after it stays.
NSString *MADLogFormat(NSString *format) {
	if ([format rangeOfString:@"%{"].location == NSNotFound) {
		return format;
	}
	NSMutableString *stripped = [format mutableCopy];
	NSUInteger i = 0;
	while (i < stripped.length) {
		unichar c = [stripped characterAtIndex:i];
		if (c != '%') {
			i++;
			continue;
		}
		if (++i >= stripped.length) {
			break;
		}
		unichar next = [stripped characterAtIndex:i];
		if (next == '%') {
			i++;
		} else if (next == '{') {
			NSRange close = [stripped rangeOfString:@"}" options:0 range:NSMakeRange(i, stripped.length - i)];
			if (close.location == NSNotFound) {
				break;	// malformed; leave the remainder alone
			}
			[stripped deleteCharactersInRange:NSMakeRange(i, close.location - i + 1)];
		}
	}
	return stripped;
}

void MADLogEmit(int priority, NSString *message) {
	static const char *names[] = { "emergency", "alert", "critical", "error", "warning", "notice", "info", "debug" };
	const char *name = (priority >= LOG_EMERG && priority <= LOG_DEBUG) ? names[priority] : "log";
	fprintf(stderr, "[%s] %s\n", name, message.UTF8String);
	syslog(priority, "%s", message.UTF8String);
}
#endif
