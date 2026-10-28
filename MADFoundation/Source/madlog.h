//
//  madlog.h
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The program's one logging header: the nine per-framework accessors (plus
//  MADTds's) all live here now.  Each keeps its own os_log category, so
//  Console.app filters exactly as it did when every framework carried its own
//  copy.  A framework's MADLog* calls route through MADLOG_ACCESSOR, which the
//  target sets to its own accessor in GCC_PREPROCESSOR_DEFINITIONS
//  (MADFoundation is the default); the table of accessors and their categories
//  is in madlog.m.
//

#ifndef madlog_h
#define madlog_h

#import <Foundation/NSString.h>

#if __APPLE__
#import <os/log.h>
#else
// No os_log off Apple platforms.  The handle is an opaque no-op -- the type
// and the two constants exist so the call sites keep Apple's spelling -- and
// the five os_log_* functions are macros over MADLogEmit below.
typedef struct MADLogHandle *os_log_t;
#define OS_LOG_DEFAULT ((os_log_t)NULL)
#define OS_LOG_DISABLED ((os_log_t)NULL)
#define os_log_create(_subsystem_, _category_) ((os_log_t)NULL)
#endif

os_log_t GetFoundationLog(void);
os_log_t GetMadLog(void);
os_log_t GetSqlite3Log(void);
os_log_t GetApiLog(void);
os_log_t GetFileManagerLog(void);
os_log_t GetMadExtLog(void);
os_log_t GetMySqlLog(void);
os_log_t GetDesignerLog(void);
os_log_t GetExplorerLog(void);
os_log_t GetTdsLog(void);
os_log_t GetPostgresLog(void);

#if __APPLE__

#ifndef MADLOG_ACCESSOR
#define MADLOG_ACCESSOR GetFoundationLog
#endif

#if DEBUG
#define MADLogDebug(fmt, ...) os_log_debug(MADLOG_ACCESSOR(), fmt, ##__VA_ARGS__)
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(MADLOG_ACCESSOR(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(MADLOG_ACCESSOR(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(MADLOG_ACCESSOR(), fmt, ##__VA_ARGS__)
#else
// MADLogEmit writes the formatted message to stderr, and to syslog when there
// is one (a container usually is not running one).  The call sites keep
// os_log's spelling -- a C string literal format -- so the literal is bridged
// with @() before Foundation formats it.  The os_log privacy annotations the
// Apple call sites use ("%{public}@") are stripped by MADLogFormat first:
// GNUstep would print them literally.
#include <stdio.h>
#include <syslog.h>
void MADLogEmit(int priority, NSString *message);
NSString *MADLogFormat(NSString *format);

#if DEBUG
#define MADLogDebug(fmt, ...) MADLogEmit(LOG_DEBUG, [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  MADLogEmit(LOG_INFO,  [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define MADLogError(fmt, ...) MADLogEmit(LOG_ERR,   [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define MADLogFault(fmt, ...) MADLogEmit(LOG_CRIT,  [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])

// The os_log_* calls the frameworks already have.  The handle argument is
// ignored -- there is nothing behind it on Linux -- and the first format
// argument is kept last so the literal stays in its familiar place.
#define os_log(_log, fmt, ...)       MADLogEmit(LOG_NOTICE, [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define os_log_debug(_log, fmt, ...) MADLogEmit(LOG_DEBUG,  [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define os_log_info(_log, fmt, ...)  MADLogEmit(LOG_INFO,   [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define os_log_error(_log, fmt, ...) MADLogEmit(LOG_ERR,    [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#define os_log_fault(_log, fmt, ...) MADLogEmit(LOG_CRIT,   [[NSString alloc] initWithFormat:MADLogFormat(@(fmt)), ##__VA_ARGS__])
#endif

#endif /* madlog_h */
