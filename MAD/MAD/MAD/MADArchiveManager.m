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
#import <stdlib.h>
#import <string.h>
#import <copyfile.h>
#import <unistd.h>
//#import <usr/lib/libarchive.h>
#import <archive.h>
//#import <archive_entry.h>
#import "madpath.h"
#import "madtar.h"
#import <MADFileManager/MADFileUtilities.h>
#import "NSString+RelativePath.h"

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

@end
