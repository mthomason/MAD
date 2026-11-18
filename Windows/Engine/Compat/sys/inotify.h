//
//  sys/inotify.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  inotify is Linux-only.  MADDirectoryMonitor.m uses it in its !__APPLE__
//  branch (Darwin uses kqueue).  On Windows the monitor is inert: inotify_init1
//  answers -1, so startMonitoring returns without watching anything.  The CLI
//  is single-shot (refresh/export run once and exit), so nothing depends on
//  change events; the app's live monitor arrives with the WPF shell (Phase 5+).
//
//  Windows-only; never included on Apple or Linux.
//

#ifndef MADCompat_sys_inotify_h
#define MADCompat_sys_inotify_h

#include <stdint.h>
#include <errno.h>

#define IN_NONBLOCK    0x0000
#define IN_MODIFY      0x0002
#define IN_ATTRIB      0x0004
#define IN_CLOSE_WRITE 0x0008
#define IN_MOVED_FROM  0x0040
#define IN_MOVED_TO    0x0080
#define IN_CREATE      0x0100
#define IN_DELETE      0x0200
#define IN_DELETE_SELF 0x0400

struct inotify_event {
	int wd;
	int mask;
	int cookie;
	int len;
	char name[];
};

static inline int inotify_init1(int flags) {
	(void)flags;
	errno = ENOSYS;
	return -1;
}

static inline int inotify_add_watch(int fd, const char *path, uint32_t mask) {
	(void)fd; (void)path; (void)mask;
	errno = ENOSYS;
	return -1;
}

#endif /* MADCompat_sys_inotify_h */
