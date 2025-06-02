//
//  madlog.h
//  MADMySQL
//
//  Created by Michael on 6/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MADMySQL_madlog_h
#define MADMySQL_madlog_h

#import <os/log.h>

os_log_t GetMySqlLog(void);

#if DEBUG
#define MADLogDebug(fmt, ...) os_log_debug(GetMySqlLog(), fmt, ##__VA_ARGS__)
#else
#define MADLogDebug(fmt, ...) do {} while (0)
#endif

#define MADLogInfo(fmt, ...)  os_log_info(GetMySqlLog(), fmt, ##__VA_ARGS__)
#define MADLogError(fmt, ...) os_log_error(GetMySqlLog(), fmt, ##__VA_ARGS__)
#define MADLogFault(fmt, ...) os_log_fault(GetMySqlLog(), fmt, ##__VA_ARGS__)

#endif /* madlog_h */
