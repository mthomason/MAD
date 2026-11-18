//
//  sys/unistd.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  MADDirectoryMonitor.m imports <sys/unistd.h> and <sys/fcntl.h> (Apple
//  spellings it keeps unconditionally).  On Windows both forward to the
//  platform's own headers: this one to the Compat unistd.h beside it.
//

#ifndef MADCompat_sys_unistd_h
#define MADCompat_sys_unistd_h

#include <unistd.h>

#endif /* MADCompat_sys_unistd_h */
