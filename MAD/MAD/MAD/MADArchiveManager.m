//
//  MADArchiveManager.m
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADArchiveManager.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileWrapper.h>

#import <MADFileManager/MADFileUtilities.h>

#import <stdlib.h>
#import <string.h>
#import <copyfile.h>
#import <unistd.h>

#import "madmalloc.h"
#import "madpath.h"
#import "madtar.h"
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

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive {
    if (self = [super init]) {
        _filewrapper = fileWrapper.copy;
        _archive = archive.copy;
    }
    return self;
}

- (BOOL)archive:(BOOL)overwrite {
    
    NSURL *fileWrapperURL = self.filewrapper.copy;
    NSURL *archiveURL = self.archive.copy;
    
    NSDirectoryEnumerator <NSURL *> * directory =
    [[NSFileManager defaultManager] enumeratorAtURL: fileWrapperURL
                         includingPropertiesForKeys: nil
                                            options: NSDirectoryEnumerationSkipsHiddenFiles
                                       errorHandler: nil];
    BOOL success = NO;
    int r;
    struct archive *archive;
    
    NSString *relativePath;
    NSString *unpacked_name = fileWrapperURL.lastPathComponent.copy;

    char *origionalURLFileSystem = strdup(fileWrapperURL.fileSystemRepresentation);
    chdir(origionalURLFileSystem);
    
    char *archiveFilename = strdup(archiveURL.fileSystemRepresentation);
    char *outname = strdup(archiveURL.fileSystemRepresentation);
    
    const char * pathToArchive = strdup(archiveURL.fileSystemRepresentation);
    char *backup;
    mad_malloc(&backup, strlen(pathToArchive) + 2);
    strcpy(backup, pathToArchive);
    strcat(backup, "~");
    mad_file_remove_if_exist(backup);
    
    NSString *tmpRelativePath, *tmpRelativePath2;
    NSURL *url;
    
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
    
    
    for (url in directory) {

        NSURL *baseUrl = url.copy;
        while (![baseUrl.lastPathComponent isEqualToString:unpacked_name]) {
            baseUrl = baseUrl.URLByDeletingLastPathComponent.copy;
        }
        NSString *basePathFileName = baseUrl.path.copy;
        
        tmpRelativePath = url.path.copy;
        tmpRelativePath2 = [MADArchiveManager newStringWithPath:tmpRelativePath
                                                     relativeTo:basePathFileName];
        relativePath = tmpRelativePath2.copy;
        
        char *filename = strdup(url.fileSystemRepresentation);
        char *relativePathFileSystem = strdup(relativePath.fileSystemRepresentation);
        
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
    
    free(origionalURLFileSystem);
    free(backup); free(outname);
    free(archiveFilename);
    
    return success;
}

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
    NSString *result = [NSString pathWithComponents:relativeComponents];
    return result.copy;
}

- (BOOL)unarchive {
    BOOL success = NO, isDirectory;
    int r;
    //NSURL *urlGuts = _filewrapper.copy;
    NSString *fileWrapperPath = _filewrapper.path.copy;
    NSError * __autoreleasing *errorCreate = nil;
    [MADFileUtilities deleteCoreDataFilesAtDirectory: _filewrapper];
    
    NSURL *destionURL;
    NSString *lastPathComponent;
    char *dest;
    char *filename;
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
    
    destionURL = _filewrapper.URLByDeletingLastPathComponent.copy;
    lastPathComponent = _filewrapper.lastPathComponent.copy;
    
    dest = strdup(destionURL.fileSystemRepresentation);
    filename = strdup(lastPathComponent.fileSystemRepresentation);
    
    r = chdir(dest);
    if (r != 0) goto READ_FAIL;
    
    char *source = strdup(_archive.fileSystemRepresentation);
    success = mad_extract(source, dest, filename) == ARCHIVE_OK;
    
    free(dest); free(filename); free(source);
    
    if (!success) goto READ_FAIL;
    
    goto READ_END;
    
READ_FAIL:;
    
    {
        //Test to see if it's it's not a compressed  archive
        NSError * __autoreleasing *errorReading = NULL;
        NSData *data;
        data = [[NSData alloc] initWithContentsOfURL:_archive options:NSDataReadingUncached
                                               error:errorReading];
        
        NSAssert(!errorReading, @"Failed to read data from\n\t%@\n\t\twith error %@\n\t\t at %s",
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

@end
