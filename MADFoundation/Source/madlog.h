//
//  madlog.h
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
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
// No os_log off Apple platforms: MADLogEmit writes the formatted message to
// stderr, and to syslog when there is one (a container usually is not running
// one).  The call sites keep os_log's spelling -- a C string literal format --
// so the literal is bridged with @() before Foundation formats it.
#include <stdio.h>
#include <syslog.h>
void MADLogEmit(int priority, NSString *message);

#if DEBUG
#define MADLogDebug(fmt, ...) MADLogEmit(LOG_DEBUG, [[NSString alloc] initWithFormat:@(fmt), ##__VA_ARGS__])
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  MADLogEmit(LOG_INFO,  [[NSString alloc] initWithFormat:@(fmt), ##__VA_ARGS__])
#define MADLogError(fmt, ...) MADLogEmit(LOG_ERR,   [[NSString alloc] initWithFormat:@(fmt), ##__VA_ARGS__])
#define MADLogFault(fmt, ...) MADLogEmit(LOG_CRIT,  [[NSString alloc] initWithFormat:@(fmt), ##__VA_ARGS__])
#endif

#endif /* madlog_h */
