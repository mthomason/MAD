//
//  madtar.c
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "madtar.h"
//#import <fcntl.h>
#import "archive.h"
#import "archive_entry.h"
#import <unistd.h>
#import <fcntl.h>

int mad_copy_data(struct archive *ar, struct archive *aw) {
    
    int r;
    size_t size;
    int64_t offset;
    const void *buff;
    
    for (;;) {
    
        r = archive_read_data_block(ar, &buff, &size, &offset);
        
        if (r == ARCHIVE_EOF)
            return ARCHIVE_OK;

        if (r != ARCHIVE_OK)
            return r;
        
        if ((r = archive_write_data_block(aw, buff, size, offset)) != ARCHIVE_OK)
            return r;
        
    }
}

int mad_extract(const char *filename) {
    
    struct archive *a, *ext;
    struct archive_entry *entry;
    int flags, r, ar;
    
    flags = ARCHIVE_EXTRACT_TIME;
    flags |= ARCHIVE_EXTRACT_PERM;
    flags |= ARCHIVE_EXTRACT_ACL;
    flags |= ARCHIVE_EXTRACT_FFLAGS;
    
    a = archive_read_new();
    ar = archive_read_support_format_all(a);
    ar = archive_read_support_filter_bzip2(a);
    
    ext = archive_write_disk_new();
    ar = archive_write_disk_set_options(ext, flags);
    ar = archive_write_disk_set_standard_lookup(ext);
    
    if ((r = archive_read_open_filename(a, filename, 10240)))
        goto EXTRACT_MAD_FAIL;
    
    while ((r = archive_read_next_header(a, &entry)) >= ARCHIVE_WARN &&
           r != ARCHIVE_EOF) {
        
        r = archive_write_header(ext, entry);
        
        if (r >= ARCHIVE_OK && archive_entry_size(entry) > 0) {
            
            r = mad_copy_data(a, ext);
            
            if (r < ARCHIVE_WARN)
                goto EXTRACT_MAD_FAIL;
            
        }
        
        r = archive_write_finish_entry(ext);
        
    }
    
    goto EXTRACT_MAD_FINISH;
    
EXTRACT_MAD_FAIL:;
    
EXTRACT_MAD_FINISH:;
    
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
    
    struct stat st;
    int fd, len;
    char buff[8192];
    struct archive_entry *entry;
    
    stat(filename, &st);
    entry = archive_entry_new2(archive);
    archive_entry_copy_stat(entry, &st);
    archive_entry_set_pathname(entry, relativePath);
    mad_archive_entry_set_attributes(&entry, &st);
    
    archive_write_header(archive, entry);
    fd = open(filename, O_RDONLY);
    len = read(fd, buff, sizeof(buff));
    while ( len > 0 ) {
        archive_write_data(archive, buff, (size_t)len);
        len = read(fd, buff, sizeof(buff));
    }
    close(fd);
    archive_entry_free(entry);
}
