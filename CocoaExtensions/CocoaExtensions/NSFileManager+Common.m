//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "NSURL+Document.h"

@implementation NSFileManager (Common)

- (NSURL *)localDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    NSError *error;
    NSURL *groupUrl = [self containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSURL *documentsURL = [groupUrl URLByAppendingPathComponent: @"Documents"
                                                    isDirectory: YES];
    BOOL isDirectory;
    BOOL success = [self fileExistsAtPath:documentsURL.path isDirectory:&isDirectory];
    if (!success) {
        isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL:documentsURL withIntermediateDirectories:YES
                                       attributes:nil
                                            error:&error];
    }

    
    return isDirectory ? documentsURL : [NSFileManager localDocumentsDirectory];
}

- (NSArray *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                andExtention: (NSString *)extenstion {
    NSURL *direcotry = [self localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
    return [self contentsOfDirectory:direcotry withPathExtension:extenstion];
}

- (NSArray *)contentOfDirectory:(NSURL *)directory withExtention:(NSString *)extenstion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [self contentsOfDirectoryAtPath:directory.path error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([self fileExistsAtPath: fileURL.path
                       isDirectory: &isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}


- (NSArray *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *directoryContents = [self contentsOfDirectoryAtPath:docPaths.firstObject error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [docPaths.firstObject stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([self fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

- (NSURL *)localCacheDirectoryNamed:(NSString *)handle {
    NSURL *cachedArrayDirectories = [[NSFileManager localCacheDirectory] URLByAppendingPathComponent: handle
                                                                                         isDirectory: YES];
    BOOL exist, isDirectory;
    exist = [self fileExistsAtPath: cachedArrayDirectories.path
                       isDirectory: &isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [self createDirectoryAtURL: cachedArrayDirectories withIntermediateDirectories: YES
                        attributes: @{} error: &error];
        if (error) {
            error = nil;
            [self createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES
                            attributes:@{}
                                 error:&error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

- (NSArray *)contentsOfDirectory:(NSURL *)directory withPathExtension:(NSString *)extension {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
	NSArray *directoryContents = [self contentsOfDirectoryAtPath:directory.path error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
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

- (NSURL *)localApplicationSupportDirectory {
    
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

+ (NSURL *)localCachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *handle = [fileUrl filenameMinusExtention];
    NSString *fileNameId = [NSString stringWithFormat:@"%lu", (unsigned long)handle.hash];
    return [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
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

+ (NSURL *)localDocumentsDirectory {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSURL URLWithString:documentsDirectories.firstObject];
}

+ (NSURL *)localTemporaryDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

+ (NSURL *)localCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [NSURL fileURLWithPath:paths.firstObject isDirectory:YES];
}

@end
