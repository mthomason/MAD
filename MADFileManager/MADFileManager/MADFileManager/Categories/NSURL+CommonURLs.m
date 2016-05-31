//
//  NSURL+CommonURLs.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+CommonURLs.h"

static NSString * const MADPathComponentData       = @"Data";
static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";

@implementation NSURL (CommonURLs)

+ (instancetype)newURLSharedApplicationGroupContainer:(NSString *)groupIdentifier {
    NSURL *url;
    url = [[NSFileManager defaultManager]
           containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSAssert(url != nil, @"The shared application group container is unavailable. "
                                  @"Check your entitlements and provisioning profiles for "
                                  @"this target. Details on proper setup can be found in the "
                                  @"PDFs referenced from the README.");
    return url;
}

+ (instancetype)newURLUniqueUrlInDirectory:(NSURL *)directory
                         withDesiredHandle:(NSString *)desiredFileHandle
                              andExtension:(NSString *)extension {
    
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *fileUrl = extension.length > 0 ?
    [baseUrl URLByAppendingPathExtension: extension] :
    baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    NSString *path = fileUrl.path;
    while ([[NSFileManager defaultManager] fileExistsAtPath: path
                                                isDirectory: &isDir1] ||
           [[NSFileManager defaultManager] isUbiquitousItemAtURL:fileUrl]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return fileUrl;
    
}

+ (instancetype)newURLUniqueURLForURL:(NSURL *)url {
    NSURL *rurl;
    rurl = [self newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                          withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                               andExtension: url.lastPathComponent.pathExtension];
    return rurl;
}

+ (instancetype)newURLForLocalCacheDirectoryNamed:(NSString *)handle {
    NSURL *url = [NSURL newURLForLocalCacheDirectory];
    NSURL *cachedArrayDirectories = [url URLByAppendingPathComponent: handle isDirectory: YES];
    BOOL exist, isDirectory;
    NSString *path = cachedArrayDirectories.path;
    exist = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                 isDirectory: &isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL: cachedArrayDirectories
                                 withIntermediateDirectories: YES attributes: nil error: &error];
        if (error) {
            error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:cachedArrayDirectories
                                     withIntermediateDirectories:YES attributes:nil error:&error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

+ (instancetype)newURLForLocalCachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *fileNameId;
    fileNameId = [[NSString alloc] initWithFormat:
                  @"%lu", (unsigned long)fileUrl.lastPathComponent
                                                .stringByDeletingPathExtension.hash];
    NSURL *url = [self newURLForLocalCacheDirectoryNamed:fileNameId];
    return url;
}

+ (instancetype)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                            pathComponent:(NSString *)pathComponent
                                      alternativeSelector:(SEL)alternativeSelector {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSAssert(groupIdentifier != nil, @"Need a group identifier... %s", __PRETTY_FUNCTION__);
    NSError *error;
    NSURL *groupUrl;
    groupUrl = [[NSFileManager defaultManager]
                containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    
    NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil "
                              @"for %@.  Maybe the fucking entitlment file is missing?!?!",
                              groupIdentifier);
    NSURL *cacheURL = [groupUrl URLByAppendingPathComponent: pathComponent
                                                isDirectory: YES];
    BOOL isDirectory;
    NSString *path = cacheURL.path;
    BOOL success = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                        isDirectory: &isDirectory];
    
    if (!success) {
        isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
                                               withIntermediateDirectories: YES
                                                                attributes: nil error: &error];
    }
    
    return isDirectory ? cacheURL : [self newURLForURLSelector:alternativeSelector];
}

+ (instancetype)newURLForURLSelector:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    NSURL *(*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                       fileURL:(NSURL *)fileURL {
    NSString *fileNameId;
    fileNameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash];
    return [NSURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier handle:fileNameId];
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                        handle:(NSString *)handle {
    
    NSURL *cacheDirectory = [NSURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
    
    NSURL *cacheURL = [cacheDirectory URLByAppendingPathComponent:handle isDirectory:YES];
    
    BOOL isDirectory;
    NSString *path = cacheURL.path;
    if (path != nil &&
        ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        
        NSError * __autoreleasing *error = NULL;
        isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
                                               withIntermediateDirectories: YES attributes: nil
                                                                     error: error];
        
    }
    return cacheURL;
}

+ (instancetype)newURLForLocalDocumentsDirectory {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask, YES);
    NSString *firstObject = documentsDirectories.firstObject;
    return [NSURL URLWithString:firstObject];
}

+ (instancetype)newURLLocalTemporaryDirectory {
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

+ (instancetype)newURLForLocalCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *firstObject = paths.firstObject;
    id url = [[NSURL alloc] initFileURLWithPath:firstObject isDirectory:YES];
    return url;
}

+ (instancetype)newURLForLocalDataDirectory {
    NSString *homeDirectory = NSHomeDirectory();
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:MADPathComponentData isDirectory:YES];
}

+ (instancetype)newURLForLocalApplicationSupportDirectory {
    NSArray <NSURL *> *possibleUrls;
    possibleUrls = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
                                                          inDomains: NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    NSURL *appSupportDirectoryForApp = nil;
    
    if (possibleUrls.count >= 1) {
        appSupportDirectory = possibleUrls[0];
        
        BOOL isDirectory;
        NSString *path = appSupportDirectory.path;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                              isDirectory: &isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectory
                                     withIntermediateDirectories: YES attributes: nil
                                                           error: &error];
        }
        
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier.copy;
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:bundleIdentifier];
        path = appSupportDirectoryForApp.path;
        fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory];
        
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectoryForApp
                                     withIntermediateDirectories: YES attributes: nil
                                                           error: &error];
        }
        
    }
    return appSupportDirectoryForApp;
}

+ (instancetype)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID {
    NSURL *cloudDirectory, *documentsDirectory;
    cloudDirectory = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:ubiquityID];
    documentsDirectory = [cloudDirectory URLByAppendingPathComponent:MADPathComponentDocuments];
    return documentsDirectory;
}

+ (instancetype)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalDocumentsDirectory);
    NSURL *url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                                   pathComponent: MADPathComponentDocuments
                                             alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalDataDirectory);
    NSURL *url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                                   pathComponent: MADPathComponentData
                                             alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalCacheDirectory);
    NSURL *url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                                   pathComponent: MADPathComponentCache
                                             alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLLocalApplicationSupportDirectoryForGroupID:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalApplicationSupportDirectory);
    NSURL *url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                                   pathComponent: MADPathComponentAppSupport
                                             alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newUrlForLocalTemporaryDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLLocalTemporaryDirectory);
    NSURL *url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                                   pathComponent: MADPathComponentTemporary
                                             alternativeSelector: altSelector];
    return url;
}

@end
