//
//  madtar.c
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
#import "madtar.h"
#import <fcntl.h>
#import <string.h>
#import <limits.h>
#import <unistd.h>
#import <stdlib.h>
#import <dirent.h>
#import <stdbool.h>
#import <errno.h>
#import <assert.h>
#if __APPLE__
#import <copyfile.h>
#else
#import <MADCompatFileCopy.h>
#endif

#import <MADFoundation/madlog.h>

#import "archive.h"
#import "archive_entry.h"

#ifndef BUFF_SIZE
#define BUFF_SIZE 8192
#endif

bool archive_function_result_handler(int ar, const char *description);
bool directory_exist(const char *path);
char *mad_copy_path_fix(const char *path);
void strip_trailing_slashes(char **path);
static inline bool path_exist(const char *path);
bool mad_mkdir(const char *path);

int mad_copy_data(struct archive *ar, struct archive *aw) {
	
	la_ssize_t r;
	size_t size;
	int64_t offset;
	const void *buff;
	
	for (;;) {
		
		r = archive_read_data_block(ar, &buff, &size, &offset);
		
		if (r == ARCHIVE_EOF)
			return ARCHIVE_OK;
		
		if (r != ARCHIVE_OK)
			return -1;
		
		r = archive_write_data_block(aw, buff, size, offset);
		if (r != ARCHIVE_OK)
			return -1;
		
	}
}

static inline bool path_exist(const char *path) {
	int access_i = access(path, F_OK);
	if ((access_i < 0)) {
		os_log_debug(OS_LOG_DEFAULT, "Debug (path_exist)(%d): %s.", errno, strerror(errno));
		return false;
	} else {
		return true;
	}
}


bool directory_exist(const char *path) {
	bool opened_directory = false;
	size_t path_len = (strlen(path) + 1) * sizeof(char);
	char *p = (char *) malloc(path_len);
	p[0] = '\0';
	strlcpy(p, path, path_len);
	strip_trailing_slashes(&p);
	DIR *dir = opendir(p);
	if (dir) {
		opened_directory = true;
		closedir(dir);
	}
	free(p);
	return opened_directory;
}

bool archive_function_result_handler(int ar, const char *description) {
	bool result = false;
	switch (ar) {
		case ARCHIVE_OK:
			result = true;
			break;
		case ARCHIVE_WARN:
			printf("WARNING: %s", description);
			break;
		default:
			printf("[%d] %s", ar, description);
			break;
	}
	return result;
}

bool mad_mkdir(const char *path) {
	bool success;
	size_t path_len = (strlen(path) + 1) * sizeof(char);
	char *p = (char *) malloc(path_len);
	p[0] = '\0';
	strlcpy(p, path, path_len);
	strip_trailing_slashes(&p);
	
	success = mkdir(p, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH) == 0;
	//    success = mkdir(p, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) == 0;
	if (!success) {
		switch (errno) {
			case EACCES:
				printf("Access denied. %s", path);
				break;
			case EEXIST:
				printf("Directory exist. %s", path);
				break;
			case ELOOP:
				printf("Symbolic link loop found. %s", path);
				break;
			case EMLINK:
				printf("Too many links. %s", path);
				break;
			case ENAMETOOLONG:
				printf("Path name is too long. %s", path);
				break;
			case ENOENT:
				printf("Path name missing or bad. %s", path);
				break;
			case ENOSPC:
				printf("System does not have enough space for this file. %s", path);
				break;
			case ENOTDIR:
				printf("A component of the path prefix is not a directory. %s", path);
				break;
			case EROFS:
				printf("The parent directory resides on a read-only file system. %s", path);
				break;
			default:
				printf("Unknown error creating file. %s", path);
				break;
		}
	}
	free(p);
	return success;
}

void strip_trailing_slashes(char **path) {
	unsigned long last;
	last = strlen((char *)*path) - 1;
	while (last > 0 && ((char)((char *)(*path))[last]) == '/')
		(*path)[last--] = '\0';
}

int mad_extract(const char *source, const char *dest, const char *filename) {
	
	struct stat source_status;
	stat(source, &source_status);
	
	switch (source_status.st_mode) {
		case S_IFDIR: {
			os_log_debug(OS_LOG_DEFAULT, "Source file is a directory.  Going to try to copy it.");
#if __APPLE__
			if (copyfile(source, dest, NULL,
						 COPYFILE_RECURSIVE | COPYFILE_ALL | COPYFILE_COPY_DATA | COPYFILE_COPY_XATTR) < 0) {
#else
			if (MADCompatCopyPath(source, dest) < 0) {
#endif
				os_log_debug(OS_LOG_DEFAULT, "Error (%d): %s\n\tFailed to copy directory %s to %s.", errno, strerror(errno), source, dest);
				return ARCHIVE_FAILED;
			} else {
				return ARCHIVE_OK;
			}
			break;
		}
			
		case S_IFREG:
			os_log_debug(OS_LOG_DEFAULT, "Source file is a regular file.  Going to try to unarchive it.");
			break;
			
		default:
			//assert(source_status.st_mode);
			break;
	}
	
	struct archive *source_archive, *dest_archive;
	struct archive_entry *source_archive_entry;
	
	char *dest_root = 0;
	int flags, r, ar;
	bool mkdirstatus = 0;
	
	os_log_debug(OS_LOG_DEFAULT, "Unpacking archiver.");
	// Does dest exist?
	
	if (!path_exist(dest)) {
		os_log_debug(OS_LOG_DEFAULT, "Destination doesn't exist.  Going to create path.");
		mkdirstatus = mad_mkdir(dest);
		assert(mkdirstatus);
	}
	
	flags = ARCHIVE_EXTRACT_TIME |
	ARCHIVE_EXTRACT_PERM |
	ARCHIVE_EXTRACT_ACL |
	ARCHIVE_EXTRACT_FFLAGS;
	
	os_log_debug(OS_LOG_DEFAULT, "Enable unarchiver.");
	
	source_archive = archive_read_new();
	ar = archive_read_support_format_all(source_archive);
	archive_function_result_handler(ar, "Archive enabled format all.");
	
	os_log_debug(OS_LOG_DEFAULT, "Enabled support for bzip2.");
	
	ar = archive_read_support_filter_bzip2(source_archive);
	archive_function_result_handler(ar, "Archive enbled format bzip2.");
	
	os_log_debug(OS_LOG_DEFAULT, "Set disk options.");
	
	dest_archive = archive_write_disk_new();
	ar = archive_write_disk_set_options(dest_archive, flags);
	archive_function_result_handler(ar, "Archive correctly set disk options.");
	
	os_log_debug(OS_LOG_DEFAULT, "Archive set standard lookup.");
	
	ar = archive_write_disk_set_standard_lookup(dest_archive);
	archive_function_result_handler(ar, "Archive correctly set standard lookup.");
	
	r = archive_read_open_filename(source_archive, source, 10240);
	
	if (r < 0) {
		if (r == ARCHIVE_FATAL) {
			os_log_debug(OS_LOG_DEFAULT, "archive_read_open_filename returned %d.  Probably opening an old file.  Not an error.", r);
			
		} else {
			os_log_debug(OS_LOG_DEFAULT, "Error: archiver failed with %d", r);
			os_log_debug(OS_LOG_DEFAULT, "Probably not an archive, but an older format.");
			os_log_debug(OS_LOG_DEFAULT, "Aborting extraction.");
		}
		
		goto EXTRACT_MAD_FAIL;  // Problably using non archvie format.
		assert(r);
	}
	
	//size_t dest_root_len = (strlen(dest) + strlen(filename) + 1 + 1);
	dest_root = (char *)malloc((strlen(dest) + strlen(filename) + 1 + 1) * sizeof(char));
	dest_root[0] = '\0';
	strlcpy(dest_root, dest, strlen(dest_root) + strlen(dest) + 1);
	strlcat(dest_root, "/", strlen(dest_root) + 2);
	strlcat(dest_root, filename, strlen(dest_root) + strlen(filename) + 1);
	assert(strlen(dest_root) > strlen(dest));
	
	if (!path_exist(dest_root)) {
		mad_mkdir(dest_root);
	}
	
	while ((r = archive_read_next_header(source_archive, &source_archive_entry)) >= ARCHIVE_WARN &&
		   r != ARCHIVE_EOF) {
		
		const char *entry_pathname;
		entry_pathname = archive_entry_pathname(source_archive_entry);
		
		char *location = (char *)malloc((strlen(entry_pathname) + strlen(filename) + 1 + 1) * sizeof(char));
		location[0] = '\0';
		strlcpy(location, filename, strlen(location) + strlen(filename) + 1);
		strlcat(location, "/", strlen(location) + 2);
		strlcat(location, entry_pathname, strlen(location) + strlen(entry_pathname) + 1);
		
		char *path = (char *)malloc((strlen(dest) + strlen(location) + 1 + 1) * sizeof(char));
		path[0] = '\0';
		strlcpy(path, dest, strlen(path) + strlen(dest) + 1);
		strlcat(path, "/", strlen(path) + 2);
		strlcat(path, location, strlen(path) + strlen(location) + 1);
		
		mode_t file_mode = archive_entry_filetype(source_archive_entry);
		bool file_is_directory = S_ISDIR(file_mode);
		if (file_is_directory) {
			if (!directory_exist(path)) {
				mad_mkdir(path);
			}
		}
		
		archive_entry_set_pathname(source_archive_entry, location);
		
		if (!file_is_directory) {
			r = archive_write_header(dest_archive, source_archive_entry);
			
		}
		if (r >= ARCHIVE_OK && archive_entry_size(source_archive_entry) > 0) {
			r = mad_copy_data(source_archive, dest_archive);
			if (r < ARCHIVE_WARN) {
				os_log_debug(OS_LOG_DEFAULT, "Error (%d): mad_copy_data", r);
				free(path); free(location);
				goto EXTRACT_MAD_FAIL;
			}
		} else {
			const char *error = archive_error_string(dest_archive);
			os_log_debug(OS_LOG_DEFAULT, "%s", error);
		}
		
		archive_write_finish_entry(dest_archive);
		free(path); free(location);
	}
	goto EXTRACT_MAD_FINISH;
	
	EXTRACT_MAD_FAIL:;
	
	EXTRACT_MAD_FINISH:;
	
	free(dest_root);
	
	archive_read_close(source_archive);
	archive_read_free(source_archive);
	archive_write_close(dest_archive);
	archive_write_free(dest_archive);
	
	if (r == ARCHIVE_EOF)
		r = ARCHIVE_OK;
	
	return r;
}

void mad_archive_entry_set_attributes(struct archive_entry **e, struct stat *st, int reproducible) {

	// A reproducible member carries none of what the machine put in it -- owner,
	// group, device, links, modification time -- just its path and its bytes, so the
	// same members make the same archive on any machine and on either platform
	// (docs/project/BUGS.md, the .mad byte-identity entry).
	if (reproducible) {
		archive_entry_set_uid(*e, 0);
		archive_entry_set_gid(*e, 0);
		archive_entry_set_dev(*e, 0);
		archive_entry_set_nlink(*e, 1);
		archive_entry_set_mode(*e, (*st).st_mode);
		archive_entry_set_mtime(*e, MADArchiveReproducibleModificationTime, 0);
	} else {
		archive_entry_set_gid(*e, (*st).st_gid);
		archive_entry_set_uid(*e, (*st).st_uid);
		archive_entry_set_dev(*e, (*st).st_dev);
		archive_entry_set_mode(*e, (*st).st_mode);
		archive_entry_set_nlink(*e, (*st).st_nlink);
#if __APPLE__
		archive_entry_set_mtime(*e, (*st).st_mtimespec.tv_sec, (*st).st_mtimespec.tv_nsec);
		archive_entry_set_birthtime(*e, (*st).st_birthtimespec.tv_sec, (*st).st_birthtimespec.tv_nsec);
#else
		/* Darwin spells the modified time st_mtimespec; POSIX st_mtim, and has no
		   birth time to hand over. */
		archive_entry_set_mtime(*e, (*st).st_mtim.tv_sec, (*st).st_mtim.tv_nsec);
#endif
	}
	
	if (S_ISREG((*st).st_mode)) {
		archive_entry_set_filetype(*e, AE_IFREG);
		archive_entry_set_perm(*e, 0644);
		
	} else if (S_ISDIR((*st).st_mode)) {
		archive_entry_set_filetype(*e, AE_IFDIR);
		archive_entry_set_perm(*e, 0755);
		
	} else if (S_ISCHR((*st).st_mode)) {
		archive_entry_set_filetype(*e, AE_IFCHR);
		archive_entry_set_perm(*e, 0644);
		
	} else if (S_ISLNK((*st).st_mode)) {
		archive_entry_set_filetype(*e, AE_IFLNK);
		archive_entry_set_perm(*e, 0644);
		
	} else if (S_ISBLK((*st).st_mode)) {
		archive_entry_set_filetype(*e, AE_IFBLK);
		archive_entry_set_perm(*e, 0644);
		
	} else {
		archive_entry_set_filetype(*e, AE_IFREG);
		archive_entry_set_perm(*e, 0644);
	}
}

int mad_archive_write_file(struct archive *archive, const char *filename, const char *relativePath, int reproducible) {
	
	int fd = 0, status = 0;
	ssize_t len;

	char buff[BUFF_SIZE];
	
	struct archive_entry *entry = NULL;
	struct stat st;
	
	if ((status = stat(filename, &st)) < 0) {
		os_log_error(OS_LOG_DEFAULT, "Failed to get file status for %s.", filename);
	} else {
		entry = archive_entry_new2(archive);
		archive_entry_copy_stat(entry, &st);
		archive_entry_set_pathname(entry, relativePath);
		mad_archive_entry_set_attributes(&entry, &st, reproducible);
		if ((status = archive_write_header(archive, entry)) != ARCHIVE_OK) {
			os_log_error(OS_LOG_DEFAULT, "Error: archive_write_header() returned %d.", status);
		}
		
		if ((fd = open(filename, O_RDONLY)) == -1) {
			os_log_error(OS_LOG_DEFAULT, "Failed to open file %s.\n", filename);
		} else {
			la_ssize_t w_size = 0;
			while ((len = read(fd, buff, BUFF_SIZE)) > 0) {
				w_size = archive_write_data(archive, buff, (size_t)len);
				if (w_size < 0) {
					// The library's own words, not just the code: -30 (ARCHIVE_FATAL)
					// arrives from the filter, and which filter said what is the whole
					// diagnosis.
					os_log_error(OS_LOG_DEFAULT, "Error: archive_write_data() returned %ld: %s.",
								 w_size, archive_error_string(archive) ?: "no error string");
				}
			}
			
			if ((status = close(fd)) == -1) {
				os_log_error(OS_LOG_DEFAULT, "Error (%d): %s.", errno, strerror(errno));
			}
		}
	}
	
	
	if (entry) {
		archive_entry_free(entry);
	}
	return status;
}
