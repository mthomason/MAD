//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "NSURL+Document.h"

NSString * const MADPathComponentDocuments  = @"Documents";
NSString * const MADPathComponentCache      = @"Cache";
NSString * const MADPathComponentAppSupport = @"Application Support";
NSString * const MADPathComponentTemporary  = @"Temporary";
NSString * const MADPathComponentData       = @"Data";

@implementation NSFileManager (Common)

- (NSURL *)cloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID {
    NSURL *cloudDirectoryURL = [self URLForUbiquityContainerIdentifier:ubiquityID];
    NSURL *documentsDirectoryURL = [cloudDirectoryURL URLByAppendingPathComponent:MADPathComponentDocuments];
    return documentsDirectoryURL;
}

- (NSURL *)localDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier
                                    pathComponent: MADPathComponentDocuments
                              alternativeSelector: @selector(localDocumentsDirectory)];
}

- (NSURL *)localDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier
                                    pathComponent: MADPathComponentData
                              alternativeSelector: @selector(localDataDirectory)];
}

- (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier
                                    pathComponent: MADPathComponentCache
                              alternativeSelector: @selector(localCacheDirectory)];
}

- (NSURL *)localApplicationSupportDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier
                                    pathComponent: MADPathComponentAppSupport
                              alternativeSelector: @selector(localApplicationSupportDirectory)];
}

- (NSURL *)localTemporaryDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier
                                    pathComponent: MADPathComponentTemporary
                              alternativeSelector: @selector(localTemporaryDirectory)];
}

- (NSURL *)localDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                              pathComponent:(NSString *)pathComponent
                        alternativeSelector:(SEL)alternativeSelector {
    NSAssert(groupIdentifier != nil, @"Need a group identifier... %s", __PRETTY_FUNCTION__);
    NSError *error;
    NSURL *groupUrl = [self containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil for %@.  Maybe the fucking entitlment file is missing?!?!", groupIdentifier);
    NSURL *cacheURL = [groupUrl URLByAppendingPathComponent: pathComponent
                                                isDirectory: YES];
    BOOL isDirectory;
    BOOL success = [self fileExistsAtPath: cacheURL.path
                              isDirectory: &isDirectory];
    if (!success) {
        isDirectory = [self createDirectoryAtURL: cacheURL
                     withIntermediateDirectories: YES
                                      attributes: nil
                                           error: &error];
    }

    return isDirectory ? cacheURL : [self urlForURLSelector:alternativeSelector];
}

- (NSURL *)urlForURLSelector:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    NSURL* (*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

- (NSArray *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                andExtention: (NSString *)extenstion {
    NSURL *direcotry = [self localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
    return [self contentsOfDirectory:direcotry withPathExtension:extenstion];
}

- (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                         fileURL:(NSURL *)fileURL {
    NSString *fileNameId = [NSString stringWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash];
    return [self localCacheDirectoryForGroupIdentifier:groupIdentifier handle:fileNameId];
}

- (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                          handle:(NSString *)handle {
    NSError *error;
    NSURL *cacheDirectory = [self localCacheDirectoryForGroupIdentifier:groupIdentifier];
    NSURL *cacheURL = [cacheDirectory URLByAppendingPathComponent:handle isDirectory:YES];
    BOOL isDirectory;
    BOOL success = [self fileExistsAtPath:cacheURL.path isDirectory:&isDirectory];
    if (!success) {
        isDirectory = [self createDirectoryAtURL: cacheURL
                     withIntermediateDirectories: YES
                                      attributes: nil
                                           error: &error];
    }
    return cacheURL;
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
        if ([self fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extension]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (NSURL *)localCachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *fileNameId = [NSString stringWithFormat:@"%lu", (unsigned long)fileUrl.lastPathComponent.stringByDeletingPathExtension.hash];
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

- (NSURL *)localTemporaryDirectory {
    return [NSFileManager localTemporaryDirectory];
}

+ (NSURL *)localTemporaryDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

- (NSURL *)localCacheDirectory {
    return [NSFileManager localCacheDirectory];
}

+ (NSURL *)localCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [NSURL fileURLWithPath:paths.firstObject isDirectory:YES];
}

+ (NSURL *)localDataDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:MADPathComponentData isDirectory:YES];
}

- (NSURL *)localApplicationSupportDirectory {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *possibleUrls = [self URLsForDirectory: NSApplicationSupportDirectory
                                         inDomains: NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    NSURL *appSupportDirectoryForApp = nil;
    if (possibleUrls.count >= 1) {
        appSupportDirectory = possibleUrls[0];
        
        BOOL isDirectory;
        BOOL fileExist = [self fileExistsAtPath: appSupportDirectory.path
                                    isDirectory: &isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [self createDirectoryAtURL: appSupportDirectory
           withIntermediateDirectories: YES
                            attributes: nil
                                 error: &error];
        }
        
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:mainBundle.bundleIdentifier];
        
        fileExist = [self fileExistsAtPath: appSupportDirectoryForApp.path
                               isDirectory: &isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [self createDirectoryAtURL: appSupportDirectoryForApp
           withIntermediateDirectories: YES
                            attributes: nil
                                 error: &error];
        }
    }
    return appSupportDirectoryForApp;
}

+ (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [NSFileManager localCachedDirectoryForFileUrl:documentUrl];
    NSArray *contentsOfDirectoryAtUrlCachedDirectory = [defaultManager contentsOfDirectoryAtURL: cachedDirectory
                                                                     includingPropertiesForKeys: nil
                                                                                        options: 0
                                                                                          error: &error];
    for (NSURL *cachedFile in contentsOfDirectoryAtUrlCachedDirectory) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

- (BOOL)removeCachedFileForDocumentUrl:(NSURL *)documentUrl
                       groupIdentifier:(NSString *)groupIdentifier {
    NSURL *cachedDirectory = [self localCacheDirectoryForGroupIdentifier: groupIdentifier
                                                                 fileURL: documentUrl];
    return [self removeContentsOfDirectory:cachedDirectory];
}

- (BOOL)removeContentsOfDirectory:(NSURL *)directory {
    NSError *error = nil;
    NSArray *files = [self contentsOfDirectoryAtURL: directory
                         includingPropertiesForKeys: nil
                                            options: 0
                                              error: &error];
    for (NSURL *file in files) {
        [self removeItemAtURL: file
                        error: &error];
    }
    [self removeItemAtURL: directory
                    error: &error];
    return YES;
}

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url {
    
    [[NSFileManager defaultManager] coordinateCreateDirectoryIfDoesNotExist:url];
}

- (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url {
    
    
    if ([self fileExistsAtPath:url.path] == NO) {
        
        NSError *error = nil;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL: url
                                        options: 0
                                          error: &error
                                     byAccessor: ^(NSURL *newURL) {
                                         
                                         NSError *errorCreateNew = nil;
                                         [self createDirectoryAtPath: newURL.path
                                         withIntermediateDirectories: YES
                                                          attributes: nil
                                                               error: &errorCreateNew];
                                         NSAssert(errorCreateNew == nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
                                     }];
        NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}


@end
