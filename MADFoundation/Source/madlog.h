//
//  madlog.h
//  MADFoundation
//
//  Created by Michael on 5/15/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef madlog_h
#define madlog_h

#import <Foundation/NSString.h>

#if __APPLE__
#import <os/log.h>

os_log_t GetFoundationLog(void);

#if DEBUG
#define MADLogDebug(fmt, ...) os_log_debug(GetFoundationLog(), fmt, ##__VA_ARGS__)
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(GetFoundationLog(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(GetFoundationLog(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(GetFoundationLog(), fmt, ##__VA_ARGS__)
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
