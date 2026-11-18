//
//  unistd.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The POSIX unistd.h the .mad container code reaches for (madtar.m,
//  MADArchiveManager.m): open/read/write/close/access/chdir/mkdir and friends,
//  mapped onto the UCRT's underscore spellings.  The framework's call sites
//  pass the classic two-argument forms, so the mapping is a straight rename
//  except for mkdir, whose POSIX mode argument the UCRT drops.
//
//  Windows-only; never included on Apple or Linux.
//

#ifndef MADCompat_unistd_h
#define MADCompat_unistd_h

#include <sys/types.h>	// ssize_t, off_t, the UCRT's spelling of them
#include <io.h>
#include <direct.h>
#include <process.h>
#include <fcntl.h>

#define open    _open
#define close   _close
#define read    _read
#define write   _write
#define access  _access
#define chdir   _chdir
#define getpid  _getpid
#define unlink  _unlink
#define rmdir   _rmdir
#define getcwd  _getcwd

// The access(2) mode constants.  The UCRT's _access takes the same numeric
// modes (0 exists, 2 write, 4 read, 6 read+write) but does not name them.
#define F_OK 0
#define X_OK 1
#define W_OK 2
#define R_OK 4

// POSIX mkdir(path, mode); the UCRT has only _mkdir(path).  The mode is
// advisory on Windows and is dropped.  A function-like macro (not a bare
// rename) so the two-argument call still compiles.
#define mkdir(path, mode) _mkdir(path)

#endif /* MADCompat_unistd_h */
