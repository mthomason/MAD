//
//  madlog.h
//  MAD
//
//  Created by Michael on 5/16/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef madlog_h
#define madlog_h

#import <Foundation/NSObjCRuntime.h>
#import <os/log.h>

os_log_t GetMadLog(void);

#if DEBUG
#define MADLogDebug(fmt, ...) os_log_debug(GetMadLog(), fmt, ##__VA_ARGS__)
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(GetMadLog(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(GetMadLog(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(GetMadLog(), fmt, ##__VA_ARGS__)

#endif /* madlog_h */
