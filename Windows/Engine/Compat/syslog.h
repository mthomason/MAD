//
//  syslog.h — Windows shim for MADFoundation's off-Apple madlog path.
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  madlog.h's non-Apple branch (which Windows takes, since __APPLE__ is not
//  defined) includes <syslog.h> and calls syslog().  Windows has neither, so
//  this shim supplies the LOG_* priority constants and a no-op syslog() — the
//  real logging on Windows already goes to stderr via MADLogEmit's fprintf.
//

#ifndef MAD_WINDOWS_SYSLOG_H
#define MAD_WINDOWS_SYSLOG_H

#define LOG_EMERG   0
#define LOG_ALERT   1
#define LOG_CRIT    2
#define LOG_ERR     3
#define LOG_WARNING 4
#define LOG_NOTICE  5
#define LOG_INFO    6
#define LOG_DEBUG   7

#ifdef __cplusplus
extern "C" {
#endif

static inline void syslog(int priority, const char *format, ...) {
	(void)priority;
	(void)format;
}

#ifdef __cplusplus
}
#endif

#endif /* MAD_WINDOWS_SYSLOG_H */
