//
//  libgen.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  dirname(3) / basename(3), which the UCRT does not have.  Like glibc's, they
//  may modify their argument and return a pointer into it (or a string literal
//  for the degenerate cases), which is exactly the contract MADArchiveManager.m's
//  backup_file relies on (it strdup's the buffers it passes and frees them
//  after use).  Both '/' and '\' are treated as separators, since the archive
//  path is a Windows path.
//
//  Windows-only; never included on Apple or Linux.
//

#ifndef MADCompat_libgen_h
#define MADCompat_libgen_h

#include <string.h>

static inline char *mad_compat_dirname(char *path) {
	if (path == NULL || path[0] == '\0') return (char *)".";
	size_t len = strlen(path);
	while (len > 1 && (path[len - 1] == '/' || path[len - 1] == '\\')) path[--len] = '\0';
	char *slash = strrchr(path, '/');
	char *bslash = strrchr(path, '\\');
	char *sep = (slash > bslash) ? slash : bslash;
	if (sep == NULL) return (char *)".";
	if (sep == path) return (char *)"/";
	*sep = '\0';
	return path;
}

static inline char *mad_compat_basename(char *path) {
	if (path == NULL || path[0] == '\0') return (char *)".";
	size_t len = strlen(path);
	while (len > 1 && (path[len - 1] == '/' || path[len - 1] == '\\')) path[--len] = '\0';
	char *slash = strrchr(path, '/');
	char *bslash = strrchr(path, '\\');
	char *sep = (slash > bslash) ? slash : bslash;
	return sep == NULL ? path : sep + 1;
}

#define dirname  mad_compat_dirname
#define basename mad_compat_basename

#endif /* MADCompat_libgen_h */
