//
//  sys/fcntl.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  MADDirectoryMonitor.m imports <sys/fcntl.h> (an Apple spelling).  The UCRT's
//  fcntl.h already carries the O_* flags the code needs, so this forwards to it.
//

#ifndef MADCompat_sys_fcntl_h
#define MADCompat_sys_fcntl_h

#include <fcntl.h>

#endif /* MADCompat_sys_fcntl_h */
