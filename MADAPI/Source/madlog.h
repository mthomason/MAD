//
//  madlog.h
//  MADAPI
//
//  Created by Michael on 6/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//


#ifndef MADAPI_madlog_h
#define MADAPI_madlog_h

#import <os/log.h>

os_log_t GetApiLog(void);

#if DEBUG
#define MADLogDebug(fmt, ...) os_log_debug(GetApiLog(), fmt, ##__VA_ARGS__)
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(GetApiLog(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(GetApiLog(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(GetApiLog(), fmt, ##__VA_ARGS__)

#endif /* madlog_h */
