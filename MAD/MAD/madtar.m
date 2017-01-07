//
//  madtar.c
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
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

#import "archive.h"
#import "archive_entry.h"

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
    return !(access(path, F_OK) == -1);
}


bool directory_exist(const char *path) {
    bool opened_directory = false;
    size_t path_len = strlen(path);
    char *p = (char *) malloc((path_len) * sizeof(char));
    p[0] = '\0';
    strlcpy(p, path, sizeof(p));
    strip_trailing_slashes(&path);
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
    size_t path_len = strlen(path);
    char *p = (char *) malloc((path_len + 1) * sizeof(char));
    p[0] = '\0';
    strlcpy(p, path, sizeof(p));
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
    
    struct archive *a, *ext;
    struct archive_entry *entry;
    int flags, r, ar;
    bool mkdirstatus = 0;
    
    // Does dest exist?
    
    if (!path_exist(dest)) {
        mkdirstatus = mad_mkdir(dest);
        assert(mkdirstatus);
    }
    
    flags = ARCHIVE_EXTRACT_TIME |
        ARCHIVE_EXTRACT_PERM |
        ARCHIVE_EXTRACT_ACL |
        ARCHIVE_EXTRACT_FFLAGS;
    
    a = archive_read_new();
    ar = archive_read_support_format_all(a);
    archive_function_result_handler(ar, "Archive enabled format all.");

    
    ar = archive_read_support_filter_bzip2(a);
    archive_function_result_handler(ar, "Archive enbled format bzip2.");
    
    ext = archive_write_disk_new();
    ar = archive_write_disk_set_options(ext, flags);
    archive_function_result_handler(ar, "Archive correctly set disk options.");

    ar = archive_write_disk_set_standard_lookup(ext);
    archive_function_result_handler(ar, "Archive correctly set standard lookup.");
    
    r = archive_read_open_filename(a, source, 10240);
    
    if (r < 0) {
        goto EXTRACT_MAD_FAIL;  // Problably using non archvie format.
        assert(r);
    }

//    char dest_root[(strlen(dest) + strlen(filename) + 1)];
    char *dest_root;
    dest_root = (char *)malloc((strlen(dest) + strlen(filename) + 1 + 1) * sizeof(char));
    dest_root[0] = '\0';
    strlcpy(dest_root, dest, sizeof(dest_root));
    strlcat(dest_root, "/", sizeof(dest_root));
    strlcat(dest_root, filename, sizeof(dest_root));

    if (!path_exist(dest_root)) {
        mkdirstatus = mad_mkdir(dest_root);
    }
    
    while ((r = archive_read_next_header(a, &entry)) >= ARCHIVE_WARN &&
           r != ARCHIVE_EOF) {
        
        const char *entry_pathname;
        entry_pathname = archive_entry_pathname(entry);
        
        char *location = (char *)malloc((strlen(entry_pathname) + strlen(filename) + 1 + 1) * sizeof(char));
        location[0] = '\0';
        strlcpy(location, filename, sizeof(location));
        strlcat(location, "/", sizeof(location));
        strlcat(location, entry_pathname, sizeof(location));
        
        char *path = (char *)malloc((strlen(dest) + strlen(location) + 1 + 1) * sizeof(char));
        path[0] = '\0';
        
        strlcpy(path, dest, sizeof(path));
        
        //if (!path_exist(path)) {
        //    mkdirstatus = mad_mkdir(path);
        //    assert(mkdirstatus);
        //}
        strlcat(path, "/", sizeof(path));
        strlcat(path, location, sizeof(path));

        mode_t file_mode = archive_entry_filetype(entry);
        bool file_is_directory = S_ISDIR(file_mode);
        if (file_is_directory) {
            if (!directory_exist(path)) {
                mad_mkdir(path);
                //assert(mkdirstatus);
            }
            
        } else {
            //int fd;
            //fd = open(path, O_RDONLY);
            //close(fd);
        }
        
        archive_entry_set_pathname(entry, location);
        //const char *entry_pathname_confirm = archive_entry_pathname(entry);
        
        if (!file_is_directory) {
            r = archive_write_header(ext, entry);
            
        }
        
        //if (access(path, F_OK) == -1) {
            //exit(2);
        //}
        
        
        if (r >= ARCHIVE_OK && archive_entry_size(entry) > 0) {
            
            r = mad_copy_data(a, ext);
            
            if (r < ARCHIVE_WARN)
                goto EXTRACT_MAD_FAIL;
            
        } else {
            const char *error = archive_error_string(ext);
            printf("%s", error);
        }
        
        archive_write_finish_entry(ext);
        
        free(path);

        //free(path);
        free(location);
        
        
    }
    

    //free(dest_root);
    
    goto EXTRACT_MAD_FINISH;
    
EXTRACT_MAD_FAIL:;
    
EXTRACT_MAD_FINISH:;
    
    free(dest_root);

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);
    
    if (r == ARCHIVE_EOF)
        r = ARCHIVE_OK;
    
    return r;
}

void mad_archive_entry_set_attributes(struct archive_entry **e, struct stat *st) {
    
    archive_entry_set_gid(*e, (*st).st_gid);
    archive_entry_set_uid(*e, (*st).st_uid);
    archive_entry_set_dev(*e, (*st).st_dev);
    archive_entry_set_mode(*e, (*st).st_mode);
    archive_entry_set_nlink(*e, (*st).st_nlink);
    archive_entry_set_mtime(*e, (*st).st_mtimespec.tv_sec, (*st).st_mtimespec.tv_nsec);
    archive_entry_set_birthtime(*e, (*st).st_birthtimespec.tv_sec, (*st).st_birthtimespec.tv_nsec);
    
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

void mad_archive_write_file(struct archive *archive, const char *filename, const char *relativePath) {
    
    const ssize_t buff_size = 8192;
    int fd = 0, status = 0;
    ssize_t len;
    char buff[buff_size];
    
    struct archive_entry *entry = NULL;
    struct stat st;
    
    status = stat(filename, &st);
    if (status == -1) {
        fprintf(stderr, "Failed to get file status for %s.\n", filename);
        goto ARCHIVE_WRITE_MAD_CLEANUP;
    }
    
    entry = archive_entry_new2(archive);
    archive_entry_copy_stat(entry, &st);
    archive_entry_set_pathname(entry, relativePath);
    mad_archive_entry_set_attributes(&entry, &st);
    
    archive_write_header(archive, entry);
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "Failed to open file %s.\n", filename);
        goto ARCHIVE_WRITE_MAD_CLEANUP;
    }

    la_ssize_t w_size;
    while ((len = read(fd, buff, buff_size)) > 0) {
        w_size = archive_write_data(archive, buff, len);
    }
    
    status = close(fd);
    if (status == -1) {
        fprintf(stderr, "Failed to close file.\n");
        goto ARCHIVE_WRITE_MAD_CLEANUP;
    }
    
ARCHIVE_WRITE_MAD_CLEANUP:;
    if (entry) {
        archive_entry_free(entry);
    }
}

