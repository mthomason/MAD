//
//  MADArchiveManager.m
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADArchiveManager.h"
#import <MADFileManager/MADFileUtilities.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileWrapper.h>
#import <stdlib.h>
#import <string.h>
#import <copyfile.h>
#import <unistd.h>
//#import "madpath.h"
//#import "madtar.h"
#import "archive.h"
#import "archive_entry.h"
#import "NSString+RelativePath.h"
#import <unistd.h>
#import <fcntl.h>

@interface MADArchiveManager ()

    @property (nonatomic, copy) NSURL *filewrapper;
    @property (nonatomic, copy) NSURL *archive;

@end

@implementation MADArchiveManager

int mad_file_remove_if_exist(char *path) {
    return (access(path, F_OK) == 0) ?
    remove(path) :
    -1;
}

int mad_path_is_absolute(const char *path) {
    return strlen(path) > 1 && path[0] == '/' ? 1 : 0;
}

int mad_path_is_relative(const char *path) {
    return mad_path_is_absolute(path) ? 0 : 1;
}

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive {
    if (self = [super init]) {
        _filewrapper = fileWrapper.copy;
        _archive = archive.copy;
    }
    return self;
}

- (BOOL)archive:(BOOL)overwrite {
    NSDirectoryEnumerator <NSURL *> * directory =
    [[NSFileManager defaultManager] enumeratorAtURL: _filewrapper
                         includingPropertiesForKeys: nil
                                            options: NSDirectoryEnumerationSkipsHiddenFiles
                                       errorHandler: nil];
    BOOL success = NO;
    int r;
    struct archive *archive;

    char *relativePathFileSystem;
    char *origionalURLFileSystem;
    char *archiveFilename;
    char *filename;
    
    NSString *basePath = _filewrapper.path.copy;
    NSString *relativePath;

    
    origionalURLFileSystem = strdup(_filewrapper.fileSystemRepresentation);
    chdir(origionalURLFileSystem);
    
    archiveFilename = strdup(_archive.fileSystemRepresentation);
    
    
    char *outname = malloc( (strlen(archiveFilename) + 1 ) * sizeof(char *) + 1 );
    char *backup = malloc( ( strlen(archiveFilename) + 1 ) * sizeof(char *) + 2 );
    
    strcpy(outname, archiveFilename);
    strcpy(backup, archiveFilename);
    strcat(backup, "~\0");
    
    mad_file_remove_if_exist(backup);
    
    
    r = copyfile(archiveFilename, backup, NULL,
                 COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
                 COPYFILE_COPY_XATTR | COPYFILE_DATA);
    
    if (r < 0) goto ARCHIVE_FILE_AT_URL_SHORT;
    
    archive = archive_write_new();

    r = archive_write_set_format_pax_restricted(archive);   // Note 1
    if (r != ARCHIVE_OK) goto ARCHIVE_FILE_AT_URL_SHORT;

    r = archive_write_add_filter_bzip2(archive);
    if (r != ARCHIVE_OK) goto ARCHIVE_FILE_AT_URL_SHORT;

    r = archive_write_open_filename(archive, outname);
    if (r != ARCHIVE_OK) goto ARCHIVE_FILE_AT_URL_SHORT;
    
    for (NSURL *url in directory) {

        relativePath = [url.path stringWithPathRelativeTo:basePath];
        
        filename = strdup(url.fileSystemRepresentation);
        relativePathFileSystem = strdup(relativePath.fileSystemRepresentation);
        
        mad_archive_write_file(archive, filename, relativePathFileSystem);

        free(relativePathFileSystem); free(filename);
        
    }
    
    success = YES;
    
    mad_file_remove_if_exist(backup);
    
    archive_write_close(archive);
    archive_write_free(archive);

ARCHIVE_FILE_AT_URL_SHORT:;
    
    //restore backup on error
    if (!success && access(backup, F_OK)) {
        copyfile(backup, archiveFilename, NULL,
                 COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
                 COPYFILE_COPY_XATTR | COPYFILE_DATA);
    }
    
    free(backup); free(outname);
    free(origionalURLFileSystem);
    free(archiveFilename);
    
    return success;
}

- (BOOL)unarchive {
    BOOL success = NO, isDirectory;
    int r;
    //NSURL *urlGuts = _filewrapper.copy;
    NSString *fileWrapperPath = _filewrapper.path;
    NSError * __autoreleasing *errorCreate = nil;
    

    [MADFileUtilities deleteCoreDataFilesAtDirectory: _filewrapper];

    success = [[NSFileManager defaultManager] fileExistsAtPath: fileWrapperPath
                                                   isDirectory: &isDirectory];
    
    if (!success || !isDirectory) {
        BOOL successCreate;
        successCreate = [[NSFileManager defaultManager] createDirectoryAtPath: fileWrapperPath
                                                  withIntermediateDirectories: YES
                                                                   attributes: nil
                                                                        error: errorCreate];
        
        BOOL sucessExist;
        sucessExist = [[NSFileManager defaultManager] fileExistsAtPath: fileWrapperPath
                                                           isDirectory: &isDirectory];
        
        if (!sucessExist) goto READ_FAIL;
    }

    
    const char *fileWrapperDirectoryCString = _filewrapper.fileSystemRepresentation;
    r = chdir(fileWrapperDirectoryCString);
    if (r != 0) goto READ_FAIL;
    
    const char *madArchivePathCString = _archive.fileSystemRepresentation;
    
    success = mad_extract(madArchivePathCString) == 0;
    if (!success) goto READ_FAIL;
    
    goto READ_END;
    
    
READ_FAIL:;
    
    {
        
        NSError * __autoreleasing *errorReading = NULL;
        NSData *data = [[NSData alloc] initWithContentsOfURL:_archive];
        
        NSAssert(data != nil, @"Failed to read data from\n\t%@\n\t\twith error %@\n\t\t at %s",
                 _archive, *errorReading, __PRETTY_FUNCTION__);
        
        NSFileWrapper *fileWrapper;
        fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        
        NSError * __autoreleasing *error = NULL;
        success = [fileWrapper writeToURL: _filewrapper
                                  options: NSFileWrapperWritingAtomic
                      originalContentsURL: _archive
                                    error: error];
        
        NSAssert(success, @"Failed to write at %s.", __PRETTY_FUNCTION__);
    }
    
READ_END:;
    return success;
}

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

@end
