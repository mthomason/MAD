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

@implementation NSFileManager (Common)

- (NSURL *)localCachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *handle = [fileUrl filenameMinusExtention];
    NSString *fileNameId = [MACloudManager filenameId:[handle hash]];
    return [self localCacheDirectoryNamed:fileNameId];
}

- (NSURL *)localCacheDirectoryNamed:(NSString *)handle {
    NSURL *cachedArrayDirectories = [[self localCacheDirectory] URLByAppendingPathComponent:handle isDirectory:YES];
    BOOL exist, isDirectory;
    exist = [self fileExistsAtPath: cachedArrayDirectories.path
                       isDirectory: &isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [self createDirectoryAtURL: cachedArrayDirectories withIntermediateDirectories: YES
                        attributes: @{} error: &error];
        if (error) {
            error = nil;
            [self createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES attributes:@{} error:&error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

- (NSSet *)contentsOfDirectory:(NSURL *)directory withPathExtension:(NSString *)extension {
    NSMutableSet *result = [[NSMutableSet alloc] init];
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

+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url {
    NSError *error = nil;
    BOOL directoryGood = [[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        directoryGood = NO;
        NSAssert(error, @"Error creating directory!  %@", error);
    }
    return directoryGood;
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

- (NSURL *)localDocumentsDirectory {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [documentsDirectories firstObject];
    return [NSURL URLWithString:path];
}

- (NSURL *)localTemporaryDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

- (NSURL *)localCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [NSURL fileURLWithPath:paths.firstObject isDirectory:YES];
}

@end
