//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "MACloudManager.h"
#import "MTLog.h"
#import "Constants.h"

@implementation NSFileManager (Common)

- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *handle = [fileUrl filenameMinusExtention];
    NSString *fileNameId = [NSFileManager filenameId:[handle hash]];
    return [self cacheDirectoryNamed:fileNameId];
}

- (NSURL *)duplicateUrl:(NSURL *)urlToDupe {
    NSURL *directory = [urlToDupe URLByDeletingLastPathComponent];
    NSString *lastPathComponent = [urlToDupe lastPathComponent];
    NSString *handle = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [lastPathComponent pathExtension];
    NSURL *uniqueUrl = [NSURL uniqueUrlInDirectory:directory
                                 withDesiredHandle:handle
                                      andExtension:extention];
    NSError *error = nil; NSInteger tryCounter = 0;
    while ([self copyItemAtURL:urlToDupe toURL:uniqueUrl error:&error] == NO) {
        tryCounter++;
        if (tryCounter > 2) {
            break;
        }
        error = nil;
    }
    if (error || tryCounter > 2) {
        uniqueUrl = nil;
    }
    return uniqueUrl;
}

- (NSSet *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension {
    NSURL *documentsDataDirectory = [[MACloudManager sharedManager] documentsDataDirectoryURL];
    return [self contentsOfDirectory:[documentsDataDirectory path] withPathExtension:extension];
}

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {
    return [self contentsOfDirectory:[self applicationDocumentsDirectory] withPathExtension:extension];
}

- (NSSet *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension {
    NSString *directoryPath = directory;
    NSMutableSet *result = [[NSMutableSet alloc] init];
    NSError *error = nil;
	NSArray *directoryContents = [self contentsOfDirectoryAtPath:directory error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        NSString *filePath = [fileURL path];
        if ([self fileExistsAtPath:filePath isDirectory:&isDirectory]) {
            NSString *pathExtension = [fileURL pathExtension];
            if ([pathExtension isEqualToString:extension]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url {
    NSError *error = nil;
    BOOL directoryGood = [[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        directoryGood = NO;
        NSAssert(error, @"Error creating directory!  %@", error);
    }
    return directoryGood;
}

- (NSURL *)applicationSupportDirectory {
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *possibleUrls = [self URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    NSURL *appSupportDirectoryForApp = nil;
    if ([possibleUrls count] >= 1) {
        appSupportDirectory = possibleUrls[0];
        
        BOOL isDirectory;
        BOOL fileExist = [self fileExistsAtPath:[appSupportDirectory path] isDirectory:&isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [self createDirectoryAtURL:appSupportDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        NSString *appBundleID = [mainBundle bundleIdentifier];
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:appBundleID];
        
        fileExist = [self fileExistsAtPath:[appSupportDirectoryForApp path] isDirectory:&isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [self createDirectoryAtURL:appSupportDirectoryForApp withIntermediateDirectories:YES attributes:nil error:&error];
        }
    }
    return appSupportDirectoryForApp;
}

- (NSString *)applicationDocumentsDirectory {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *result = nil;
    if ([documentsDirectories count] >= 1) {
        result = documentsDirectories[0];
    }
	return result;
}

- (NSURL *)localTemporaryDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

+ (NSString *)cachedPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

+ (NSURL *)cacheDirectory {
    NSString *cachesPath = [self cachedPath];
    return [NSURL fileURLWithPath:cachesPath isDirectory:YES];
}

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention {
    return [[self filenameId:tag] stringByAppendingPathExtension:fileExtention];
}

- (NSURL *)cacheDirectoryNamed:(NSString *)handle {
    NSURL *cachedArrayDirectories = [[NSFileManager cacheDirectory] URLByAppendingPathComponent:handle isDirectory:YES];
    BOOL exist, isDirectory;
    exist = [self fileExistsAtPath:[cachedArrayDirectories path] isDirectory:&isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [self createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES attributes:@{} error:&error];
        if (error) {
            error = nil;
            [self createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES attributes:@{} error:&error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

- (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
    BOOL isDirectory;
    BOOL exists = [self fileExistsAtPath:[destinationUrl path] isDirectory:&isDirectory];
    if (exists) {
        NSError *deleteError = nil;
        if (isDirectory) {
            
            BOOL(^ErrorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *url, NSError *error) {
                MTLog(@"Error %@", error);
                return YES;
            };
            NSArray *requestedKeys = @[NSURLIsDirectoryKey];
            NSDirectoryEnumerator *enumerator = [self enumeratorAtURL:destinationUrl
                                           includingPropertiesForKeys:requestedKeys
                                                              options:-1
                                                         errorHandler:ErrorHandler];
            for (NSURL *file in enumerator) {
                NSError *error = nil;
                
                [self removeItemAtURL:file error:&error];
                if (error != nil) {
                    MTLog(@"Error %@", error);
                    [self removeItemAtURL:file error:&error];
                }
                
            }
            
            [self removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                MTLog(@"%@", deleteError);
                [self removeItemAtURL:destinationUrl error:&deleteError];
            }
            
        } else {
            [self removeItemAtURL:destinationUrl error:&deleteError];
            if (deleteError != nil) {
                MTLog(@"%@", deleteError);
                [self removeItemAtURL:destinationUrl error:&deleteError];
            }
        }
    }
}

- (NSURL *)unpackMadFile:(NSURL *)url toDestinationUrl:(NSURL *)destinationUrl {
    NSURL *urlToOpen = nil;
    BOOL fileexist = [self fileExistsAtPath:[url path]];
    if (fileexist) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
        NSError *fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        if (fileWrittingError) {
            fileWrittingError = nil;
            [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        }
        if (fileWrittingError == nil) {
            urlToOpen = destinationUrl;
        }
    } else {
        urlToOpen = url;
    }
    return urlToOpen;
}

- (NSData *)dataForUrl:(NSURL *)url {
    NSError *readError = nil;
    NSData *data = nil;
    if ([self fileExistsAtPath:[url path]]) {
        data = [NSData dataWithContentsOfURL: url options:NSDataReadingUncached error:&readError];
        if (readError != nil) {
            data = [NSData dataWithContentsOfURL: url options:NSDataReadingUncached error:&readError];
        }
    }
    return data;
}

@end
