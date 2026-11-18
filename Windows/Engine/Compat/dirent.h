//
//  dirent.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The POSIX dirent.h the .mad container code reaches for (madtar.m's
//  directory_exist, and MADCompatFileCopy.h's recursive copy): DIR /
//  struct dirent / opendir / readdir / closedir over the Win32 find APIs.
//  Paths are UTF-8 (the engine's fileSystemRepresentation), so the wide
//  FindFirstFileW/FindNextFileW spellings are used and d_name is converted
//  back to UTF-8.
//
//  Windows-only; never included on Apple or Linux.
//

#ifndef MADCompat_dirent_h
#define MADCompat_dirent_h

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

struct dirent {
	char d_name[260];	/* NAME_MAX-ish; the archive members are short */
};

typedef struct {
	HANDLE handle;
	WIN32_FIND_DATAW find_data;
	struct dirent entry;
	int first;	/* 1 before the first readdir */
} DIR;

static inline DIR *opendir(const char *path) {
	if (path == NULL || path[0] == '\0') { errno = EINVAL; return NULL; }

	/* FindFirstFileW wants "<path>\\*" to list a directory's entries. */
	size_t plen = strlen(path);
	int need_sep = (plen > 0 && path[plen - 1] != '\\' && path[plen - 1] != '/');
	size_t wplen = plen + (need_sep ? 1 : 0) + 2;	/* sep + "*" + NUL */
	wchar_t *wpath = (wchar_t *)malloc(wplen * sizeof(wchar_t));
	if (wpath == NULL) { errno = ENOMEM; return NULL; }
	int wc = MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, (int)wplen);
	if (wc == 0) { free(wpath); errno = EINVAL; return NULL; }
	/* Recompute from the converted length; append "\\*". */
	size_t used = wcslen(wpath);
	if (need_sep) wpath[used++] = L'\\';
	wpath[used++] = L'*';
	wpath[used] = L'\0';

	DIR *dir = (DIR *)calloc(1, sizeof(DIR));
	if (dir == NULL) { free(wpath); errno = ENOMEM; return NULL; }

	dir->handle = FindFirstFileW(wpath, &dir->find_data);
	free(wpath);
	if (dir->handle == INVALID_HANDLE_VALUE) {
		free(dir);
		errno = ENOENT;
		return NULL;
	}
	dir->first = 1;
	return dir;
}

static inline struct dirent *readdir(DIR *dir) {
	if (dir == NULL) return NULL;
	if (!dir->first) {
		if (!FindNextFileW(dir->handle, &dir->find_data)) return NULL;
	}
	dir->first = 0;
	int n = WideCharToMultiByte(CP_UTF8, 0, dir->find_data.cFileName, -1,
								dir->entry.d_name, sizeof(dir->entry.d_name), NULL, NULL);
	if (n <= 0) dir->entry.d_name[0] = '\0';
	return &dir->entry;
}

static inline int closedir(DIR *dir) {
	if (dir == NULL) { errno = EBADF; return -1; }
	BOOL ok = FindClose(dir->handle);
	free(dir);
	return ok ? 0 : -1;
}

#endif /* MADCompat_dirent_h */
