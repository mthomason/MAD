//
//  madtar.c
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#include <sys/types.h>
#include <sys/stat.h>

#include <archive.h>
#include <archive_entry.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
//#include </usr/local/include/odbc>
// usr/lib/libarchive.tbd
/*
void
write_archive(const char *outname, const char **filename)
{
    struct archive *a;
    struct archive_entry *entry;
    struct stat st;
    char buff[8192];
    int len;
    int fd;
    
    a = archive_write_new();
    archive_write_add_filter_gzip(a);
    archive_write_set_format_pax_restricted(a); // Note 1
    archive_write_open_filename(a, outname);
    while (*filename) {
        stat(*filename, &st);
        entry = archive_entry_new(); // Note 2
        archive_entry_set_pathname(entry, *filename);
        archive_entry_set_size(entry, st.st_size); // Note 3
        archive_entry_set_filetype(entry, AE_IFREG);
        archive_entry_set_perm(entry, 0644);
        archive_write_header(a, entry);
        fd = open(*filename, O_RDONLY);
        len = read(fd, buff, sizeof(buff));
        while ( len > 0 ) {
            archive_write_data(a, buff, len);
            len = read(fd, buff, sizeof(buff));
        }
        close(fd);
        archive_entry_free(entry);
        filename++;
    }
    archive_write_close(a); // Note 4
    archive_write_free(a); // Note 5
}*/




#ifdef __linux__
#define _FILE_OFFSET_BITS 64
#endif
#include <sys/stat.h>
#include <archive.h>
#include <archive_entry.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

struct mydata {
    const char *name;
    int fd;
};

int myopen(struct archive *a, void *client_data);
int myopen(struct archive *a, void *client_data) {
    struct mydata *mydata = client_data;
    
    mydata->fd = open(mydata->name, O_WRONLY | O_CREAT, 0644);
    if (mydata->fd >= 0)
        return (ARCHIVE_OK);
    else
        return (ARCHIVE_FATAL);
}

la_ssize_t mywrite(struct archive *a, void *client_data, const void *buff, size_t n);
la_ssize_t mywrite(struct archive *a, void *client_data, const void *buff, size_t n) {
    struct mydata *mydata = client_data;
    
    return (write(mydata->fd, buff, n));
}

int myclose(struct archive *a, void *client_data);
int myclose(struct archive *a, void *client_data) {
    struct mydata *mydata = client_data;
    
    if (mydata->fd > 0)
        close(mydata->fd);
    return (0);
}

void write_archive_example(const char *outname, const char **filename);
void write_archive_example(const char *outname, const char **filename) {
    struct mydata *mydata = malloc(sizeof(struct mydata));
    struct archive *a;
    struct archive_entry *entry;
    struct stat st;
    char buff[8192];
    int len;
    int fd;
    
    a = archive_write_new();
    mydata->name = outname;
    /* Set archive format and filter according to output file extension.
     * If it fails, set default format. Platform depended function.
     * See supported formats in archive_write_set_format_filter_by_ext.c */
    if (archive_write_set_format_filter_by_ext(a, outname) != ARCHIVE_OK)  {
        archive_write_add_filter_gzip(a);
        archive_write_set_format_ustar(a);
    }
    archive_write_open(a, mydata, myopen, mywrite, myclose);
    while (*filename) {
        stat(*filename, &st);
        entry = archive_entry_new();
        archive_entry_copy_stat(entry, &st);
        archive_entry_set_pathname(entry, *filename);
        archive_write_header(a, entry);
        if ((fd = open(*filename, O_RDONLY)) != -1) {
            len = (int)read(fd, buff, (size_t)sizeof(buff));
            while (len > 0) {
                archive_write_data(a, buff, (size_t)len);
                len = (int)read(fd, buff, (size_t)sizeof(buff));
            }
            close(fd);
        }
        archive_entry_free(entry);
        filename++;
    }
    archive_write_free(a);
}

