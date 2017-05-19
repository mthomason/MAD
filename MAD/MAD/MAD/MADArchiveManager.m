//
//  MADArchiveManager.m
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADArchiveManager.h"

#import <stdlib.h>
#import <string.h>
#import <copyfile.h>
#import <unistd.h>
#import <unistd.h>
#import <fcntl.h>
#import <errno.h>
#import <asl.h>

#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileWrapper.h>

#import <MADFileManager/MADFileUtilities.h>

#import "madmalloc.h"
#import "madpath.h"
#import "madtar.h"
#import "archive.h"
#import "archive_entry.h"
#import "NSString+RelativePath.h"

@interface MADArchiveManager ()

    @property (nonatomic, copy) NSURL *filewrapper;
    @property (nonatomic, copy) NSURL *archive;

@end

@implementation MADArchiveManager

int backup_file(char *, char *, char *);
int write_archive(char *, NSURL *);
int restore_backup(char *, char *, char *);

+ (NSString *)newStringWithPath:(NSString *)basePath relativeTo:(NSString *)anchorPath {
    NSString *baseString = basePath.copy;
    NSString *anchorString = anchorPath.copy;
    
    NSString *pathComponent, *anchorComponent;
    NSArray <NSString *> *pathComponents = baseString.pathComponents,
                         *anchorComponents = anchorString.pathComponents;
    
    NSUInteger componentsInCommon = MIN(pathComponents.count, anchorComponents.count);
    
    for (NSUInteger i = 0, n = componentsInCommon; i < n; i++) {
        pathComponent = pathComponents[i];
        anchorComponent = anchorComponents[i];
        if (![pathComponent isEqualToString:anchorComponent]) {
            componentsInCommon = i;
            break;
        }
    }
    
    const NSUInteger numberOfParentComponents = anchorComponents.count - componentsInCommon;
    const NSUInteger numberOfPathComponents = pathComponents.count - componentsInCommon;
    
    NSMutableArray *relativeComponents;
    relativeComponents = [[NSMutableArray alloc] initWithCapacity:
                          numberOfParentComponents + numberOfPathComponents];
    for (NSUInteger i = 0; i < numberOfParentComponents; i++) {
        [relativeComponents addObject:@".."];
    }
    NSArray <NSString *> *subarrayWithRange;
    subarrayWithRange = [pathComponents subarrayWithRange:
                         NSMakeRange(componentsInCommon, numberOfPathComponents)];
    [relativeComponents addObjectsFromArray: subarrayWithRange];
    return [NSString pathWithComponents:relativeComponents];
}

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive {
    if (self = [super init]) {
        _filewrapper = fileWrapper.copy;
        _archive = archive.copy;
    }
    return self;
}

///
/// 1. Remove Backup
/// 2. Copy archive to backup location
/// 3. Restore backup on failure.
///

- (BOOL)archive:(BOOL)overwrite {
    
    BOOL success = NO;
    int r;

    //Change directory to the location to archive.
    char *origin_path = strdup(self.filewrapper.fileSystemRepresentation);
    char *archive_path = strdup(self.archive.fileSystemRepresentation);
    char *backup_path;
    size_t backup_size = mad_malloc(&backup_path, strlen(archive_path) + 2);
    backup_path[0] = '\n';
    strlcpy(backup_path, archive_path, backup_size);
    strlcat(backup_path, "~", backup_size);
    
    // 1. Remove backup.
    if ((r = backup_file(origin_path, backup_path, archive_path)) < 0) {
        asl_log(NULL, NULL, ASL_LEVEL_ERR, "Failed to backup file with %d.", r);
    } else {
        
        //2. Write archive.
        if ((r = write_archive(archive_path, self.filewrapper)) < 0) {
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "Failed to archive file with %d.", r);
        }
        mad_file_remove_if_exist(backup_path);
    }

    success = r == ARCHIVE_OK;

    // 3. Restore backup on failure.
    if (!success && access(backup_path, F_OK)) {
        if ((r = restore_backup(origin_path, backup_path, archive_path)) < 0) {
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error in restore_backup.");
        }
    }
    free(archive_path);
    free(origin_path);
    free(backup_path);
    
    if (!success) asl_log(NULL, NULL, ASL_LEVEL_ERR, "Failed to write archive.");
    
    return success;
}

- (BOOL)unarchive {
    asl_add_log_file(NULL, STDERR_FILENO);
    
    int success = 0;
    @autoreleasepool {
        success = [self unarchiveV8];
    }

    if (success != 0) {
        @autoreleasepool {
            success = [self unvarchiveLegacy];
        }
    }
    return success == 0;
}

- (int)unarchiveV8 {
    int success = 0;
    BOOL isDirectory;
    int r;
    //NSURL *urlGuts = _filewrapper.copy;
    NSString *destinationPath = _filewrapper.path;
    NSString *destinationLastPathComponent = _filewrapper.lastPathComponent;
    NSURL *destinationURL = _filewrapper.URLByDeletingLastPathComponent;
    
    NSError * __autoreleasing *errorCreate = nil;
    [MADFileUtilities deleteCoreDataFilesAtDirectory: _filewrapper];
    
    char *dest = 0, *filename = 0, *source = 0;
    success = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
                                                   isDirectory: &isDirectory];
    
    if (!success || !isDirectory) {
        BOOL successCreate, sucessExist;
        successCreate = [[NSFileManager defaultManager] createDirectoryAtPath: destinationPath
                                                  withIntermediateDirectories: YES
                                                                   attributes: nil
                                                                        error: errorCreate];
        if (successCreate) {
            sucessExist = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
                                                               isDirectory: &isDirectory];
        } else {
            sucessExist = NO;
        }
        
        if (!sucessExist) success = -1;
    }
    if (success >= 0) {
        dest = strdup(destinationURL.fileSystemRepresentation);
        filename = strdup(destinationLastPathComponent.fileSystemRepresentation);
        
        if (((r = chdir(dest))) != 0) {
            asl_log(NULL, NULL, ASL_LEVEL_DEBUG,
                    "Error %d: %s. Chdir (%s) failed.", errno, strerror(errno), dest);
            
            success = -1;
        } else {
            source = strdup(_archive.fileSystemRepresentation);
            success = mad_extract(source, dest, filename);
        }
    }

    if (dest != 0) free(dest);
    if (filename != 0) free(filename);
    if (source != 0) free(source);

    return success;
}

- (int)unvarchiveLegacy {
    int success = 0;
    //Test to see if it's it's not a compressed  archive
    NSError * __autoreleasing *errorReading = NULL;
    NSData *data;
    data = [[NSData alloc] initWithContentsOfURL: _archive
                                         options: NSDataReadingUncached
                                           error: errorReading];
    if (errorReading != nil) {
        asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: %s.", (*errorReading).localizedDescription.UTF8String);
        success = -2;
    }
    
    if (success == 0) {
        NSFileWrapper *fileWrapper;
        fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        
        NSError * __autoreleasing *errorWriting = NULL;
        success = [fileWrapper writeToURL: _filewrapper
                                  options: NSFileWrapperWritingAtomic
                      originalContentsURL: _archive
                                    error: errorWriting] ? 0 : -1;
        
        if (success < 0 && errorWriting != nil) {
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: %s.", (*errorWriting).localizedDescription.UTF8String);
        }
        
        NSAssert(success >= 0, @"Failed to write at %s.", __PRETTY_FUNCTION__);
    }
    return success;
}

// Backup a file.
// 1. Change directory to the origional directory.
// 1. Does a previous backup exist exist?
// 2. If a previous backup exist, delete it.
// 3. Copy file to backup location... that is, create the backup.
int backup_file(char *origional_path, char *backup_path, char *backup_name) {
    
    int r;
    
    if ((r = chdir(origional_path)) < 0) {
        asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: Change directory returned %d. Error (%d): %s",
                r, errno, strerror(errno));
    } else {
        // 1. Does a previous backup exist exist?
        if ((r = access(backup_path, F_OK)) < 0)
            asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "No backup file to delete (%d): %s\n\t%s)",
                    errno, strerror(errno), backup_path);
        else
            // 2. If a previous backup exist, delete it.
            if ((r = remove(backup_path)) < 0)
                asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error removing file: %s\n\t%d: %s)",
                        backup_path, errno, strerror(errno));
        
        // 3. Copy file to backup location... that is, create the backup.
        if ((r = copyfile(backup_name, backup_path, NULL,
                          COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
                          COPYFILE_COPY_XATTR)) < 0)
            asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: Copyfile %s.\n\tGot %d: %s.\n\t\n\tStore is migration directory?",
                  backup_name, errno, strerror(errno));
    }
    
    return r;
}

int write_archive(char *outname, NSURL *filewrapper) {
    int r = 0;
    NSString *directoryToArchiveFileName = filewrapper.lastPathComponent;
    struct archive *archive = archive_write_new();
    
    if ((r = archive_write_set_format_pax_restricted(archive)) != ARCHIVE_OK) {
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Error (%d): %s.", errno, strerror(errno));
    }

    if ((r = archive_write_add_filter_bzip2(archive)) != ARCHIVE_OK) {
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Error (%d): %s.", errno, strerror(errno));
    }
    
    if ((r = archive_write_open_filename(archive, outname)) != ARCHIVE_OK) {
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Error (%d): %s.", errno, strerror(errno));
    }
    
    NSDirectoryEnumerator <NSURL *> * directoryToArchive =
    [[NSFileManager defaultManager] enumeratorAtURL: filewrapper
                         includingPropertiesForKeys: nil
                                            options: NSDirectoryEnumerationSkipsHiddenFiles
                                       errorHandler: ^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                           asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: %s\n\t%s",
                                                   error.localizedDescription.UTF8String,
                                                   url.absoluteString.UTF8String);
                                           return YES;
                                       }];
    NSURL *urlToArchive, *baseUrl;
    NSString *relativePath;
    for (urlToArchive in directoryToArchive) {
        
        baseUrl = urlToArchive.copy;
        while (![baseUrl.lastPathComponent isEqualToString:directoryToArchiveFileName]) {
            baseUrl = baseUrl.URLByDeletingLastPathComponent;
        }
        
        relativePath = [MADArchiveManager newStringWithPath: urlToArchive.path
                                                 relativeTo: baseUrl.path];
        
        char *filename = strdup(urlToArchive.fileSystemRepresentation);
        char *relativePathFileSystem = strdup(relativePath.fileSystemRepresentation);
        
        mad_archive_write_file(archive, filename, relativePathFileSystem);
        
        free(relativePathFileSystem); free(filename);
        
    }
    
    archive_write_close(archive);
    archive_write_free(archive);
    return r;
}

int restore_backup(char *origional_path, char *backup_path, char *backup_name) {
    int r = 0;
    if ((r = chdir(origional_path)) < 0) {
        asl_log(NULL, NULL, ASL_LEVEL_ERR, "Error: Change directory returned %d. Error (%d): %s",
                r, errno, strerror(errno));
    } else {
        if ((r = access(backup_path, F_OK)) < 0) {
            asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Can't access file that we want to backup.\n\t%s", backup_path);
        } else {
            if ((r = copyfile(backup_path, backup_name, NULL,
                              COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
                              COPYFILE_COPY_XATTR | COPYFILE_DATA)) < 0)
                asl_log(NULL, NULL, ASL_LEVEL_ERR, "Copyfile %s error %d - %s", backup_name, errno, strerror(errno));
            
        }
    }

    return r;
}

@end
