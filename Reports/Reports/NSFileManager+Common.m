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

@implementation NSFileManager (Common)

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

+ (NSMutableSet *)contentsOfDocumentsDirectory {
    NSMutableSet *doc = [[NSMutableSet alloc] init];
    NSString *documentsDirectoryPath = [NSFileManager applicationDocumentsDirectory];
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];

    [documentsDirectoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:obj];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isDirectory){
            [doc addObject:fileURL];
        }
        
    }];
        
    return doc;
}


+ (NSMutableArray *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension {
    NSURL *documentsDataDirectory = [[MACloudManager sharedManager] documentsDataDirectoryURL];
    return [NSFileManager contentsOfDirectory:[documentsDataDirectory path] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {
    return [NSFileManager contentsOfDirectory:[NSFileManager applicationDocumentsDirectory] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension {
    NSString *directoryPath = directory;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	NSArray *directoryContents = [defaultFileManager contentsOfDirectoryAtPath:directory error:&error];
    for (NSString *filename in directoryContents) {
        @autoreleasepool {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:filename];
            NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
            BOOL isDirectory;
            NSString *filePath = [fileURL path];
            if ([defaultFileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
                NSString *pathExtension = [fileURL pathExtension];
                if ([pathExtension isEqualToString:extension]) {
                    [result addObject:fileURL];
                }
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

//The application support directory must be created as a sub directory.
+ (NSURL *)applicationSupportDirectory {

    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *possibleUrls = [defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    NSURL *appSupportDirectoryForApp = nil;
    if ([possibleUrls count] >= 1) {
        appSupportDirectory = [possibleUrls objectAtIndex:0];
        
        BOOL isDirectory;
        BOOL fileExist = [defaultManager fileExistsAtPath:[appSupportDirectory path] isDirectory:&isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [defaultManager createDirectoryAtURL:appSupportDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        NSString *appBundleID = [mainBundle bundleIdentifier];
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:appBundleID];
        
        fileExist = [defaultManager fileExistsAtPath:[appSupportDirectoryForApp path] isDirectory:&isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [defaultManager createDirectoryAtURL:appSupportDirectoryForApp withIntermediateDirectories:YES attributes:nil error:&error];
        }
    }
    return appSupportDirectoryForApp;
}

+ (NSString *)applicationSupportDirectoryPath {
	return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationDocumentsDirectory {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *result = nil;
    if ([documentsDirectories count] >= 1) {
        result = [documentsDirectories objectAtIndex: 0];
    }
	return result;
}

+ (NSURL *)localTemporaryDirectory {
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

+ (void)wrapFile:(NSURL *)fileToAttach withExtention:(NSString *)extention overwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion {
    NSError *fileWrapperError = nil;
    BOOL success = NO;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: fileToAttach
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    if (fileWrapperError == nil) {
        NSString *fileName = [[fileToAttach lastPathComponent] stringByDeletingPathExtension];
        if (overwrite) {
            fileName = [fileName stringByAppendingPathExtension:extention];
            NSURL *resultUrl = [[[MACloudManager sharedManager] documentsDirectoryURL] URLByAppendingPathComponent:fileName isDirectory:NO];
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL:resultUrl options:NSDataWritingAtomic error:&errorWriting];
            if (completion != NULL) {
                completion(success, resultUrl);
            }
        } else {
            NSURL *resultUrl = [NSURL uniqueUrlForDocumentWithName:fileName
                                               withExtension:extention];
            NSData *data = [fileWrapper serializedRepresentation];
            success = [data writeToURL:resultUrl atomically:YES];
            if (completion != NULL) {
                completion(success, resultUrl);
            }
        }
    }
}

+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention {
    NSString *filename = [NSString stringWithFormat:@"%lu", (unsigned long)tag];
    return [filename stringByAppendingPathExtension:fileExtention];
}

@end
