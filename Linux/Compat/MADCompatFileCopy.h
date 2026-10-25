//
//  MADCompatFileCopy.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Apple's copyfile(3) -- the single-file and recursive cases the archive
//  code uses, in POSIX.  The flags the call sites pass (COPYFILE_ALL,
//  COPYFILE_COPY_DATA, COPYFILE_COPY_XATTR, COPYFILE_SECURITY) have no
//  separate meaning here: the data and the mode bits are copied, which is
//  what the store's backup and the extract paths need.
//
//  Both return 0 on success and -1 with errno set, like copyfile does.
//  Non-Apple only.
//

#ifndef MADCompat_MADCompatFileCopy_h
#define MADCompat_MADCompatFileCopy_h

#if !__APPLE__
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static inline int MADCompatCopyFile(const char *src, const char *dst) {
	int in = open(src, O_RDONLY);
	if (in < 0) return -1;
	struct stat st;
	if (fstat(in, &st) != 0) {
		int saved = errno; close(in); errno = saved; return -1;
	}
	int out = open(dst, O_WRONLY | O_CREAT | O_TRUNC, st.st_mode & 07777);
	if (out < 0) {
		int saved = errno; close(in); errno = saved; return -1;
	}
	char buffer[65536];
	ssize_t n;
	int rc = 0;
	while ((n = read(in, buffer, sizeof(buffer))) > 0) {
		ssize_t written = 0;
		while (written < n) {
			ssize_t w = write(out, buffer + written, (size_t)(n - written));
			if (w < 0) { rc = -1; break; }
			written += w;
		}
		if (rc != 0) break;
	}
	if (n < 0) rc = -1;
	close(in);
	if (close(out) != 0) rc = -1;
	return rc;
}

// copyfile(..., COPYFILE_RECURSIVE): the directory tree, files and directories.
static inline int MADCompatCopyPath(const char *src, const char *dst) {
	struct stat st;
	if (stat(src, &st) != 0) return -1;
	if (!S_ISDIR(st.st_mode)) {
		return MADCompatCopyFile(src, dst);
	}
	if (mkdir(dst, st.st_mode & 07777) != 0 && errno != EEXIST) return -1;
	DIR *directory = opendir(src);
	if (directory == NULL) return -1;
	struct dirent *entry;
	int rc = 0;
	while ((entry = readdir(directory)) != NULL && rc == 0) {
		if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;
		char childSrc[4096], childDst[4096];
		if (snprintf(childSrc, sizeof(childSrc), "%s/%s", src, entry->d_name) >= (int)sizeof(childSrc) ||
			snprintf(childDst, sizeof(childDst), "%s/%s", dst, entry->d_name) >= (int)sizeof(childDst)) {
			rc = -1;
			break;
		}
		rc = MADCompatCopyPath(childSrc, childDst);
	}
	closedir(directory);
	return rc;
}

#endif /* !__APPLE__ */

#endif /* MADCompat_MADCompatFileCopy_h */
