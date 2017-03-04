//
//  NSURL+CommonURLs.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADURL.h"
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>

#import "UIScreen+Properties.h"
#import "MADFilename.h"

static NSString * const MADPathComponentData       = @"Data";
static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";

@implementation MADURL

+ (instancetype)newURLLocalDocumentWithName:(NSString *)name
                                  extention:(NSString *)extention
                                  fileGroup:(NSString *)fileGroup {
    id url = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
    id documentURLWithoutExtension = [url URLByAppendingPathComponent:name];
    id result = [documentURLWithoutExtension URLByAppendingPathExtension:extention];
    return result;
}

+ (instancetype)newURLCacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [MADFilename newFilenameId:filename.hash];
    return [MADURL newURLForLocalCacheDirectoryNamed:filenameId];
}

+ (instancetype)newURLDocumentArchiveForFileURL:(NSURL *)madUrl extension:(NSString *)extension {
    NSString *name = madUrl.lastPathComponent.stringByDeletingPathExtension.copy;
    NSString *destinationName;
    destinationName = [name stringByAppendingPathExtension: extension];
    NSURL *destinationDirectoryUrl = [MADURL newURLLocalTemporaryDirectory];
    id url = [destinationDirectoryUrl URLByAppendingPathComponent: destinationName
                                                      isDirectory: YES];
    return url;
}

+ (instancetype)newURLThumbnailForURL:(NSURL *)madUrl {
    NSString *handle = madUrl.lastPathComponent.stringByDeletingPathExtension.copy;
    return [self newURLThumbnailForHandle: handle andRetinaDisplay: [UIScreen mainScreen].isRetnaDisplay];
    
}

+ (instancetype)newURLThumbnailForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *name = [UIScreen mainScreen].isRetnaDisplay ? [handle stringByAppendingString:@"@2x"] : handle;
    NSString *filename = [name stringByAppendingPathExtension:@"png"];
    NSString *fileNameId = [MADFilename newFilenameId:handle.hash];
    NSURL *cacheDirectory = [MADURL newURLForLocalCacheDirectoryNamed:fileNameId];
    id cachedPathFull = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
    return cachedPathFull;
}

+ (instancetype)newURLWithUniqueFilenameForURL:(NSURL *)origionalURL {
    
    NSInteger ctr = 0;
    NSURL *result;
    MADURL *unqiueURL;
    NSString *pathExtension, *name, *path, *maybe;
    
    pathExtension = origionalURL.pathExtension.copy;
    name = origionalURL.lastPathComponent.stringByDeletingPathExtension.copy;
    unqiueURL = origionalURL.copy;
    path = unqiueURL.path.copy;
    
    do {
        maybe = [name stringByAppendingFormat:@" %ld", (long)ctr];
        [maybe stringByAppendingPathExtension: pathExtension];
        
        result = [origionalURL.baseURL URLByAppendingPathComponent:maybe isDirectory:NO];
        unqiueURL = result.copy;
        
        ctr++;
        
        path = unqiueURL.path.copy;
    } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
    
    return unqiueURL;
}


+ (instancetype)newURLSharedApplicationGroupContainer:(NSString *)groupIdentifier {
    id url;
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
    id fileUrl = extension.length > 0 ?
    [baseUrl URLByAppendingPathExtension: extension] :
    baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    NSString *path = ((NSURL *)fileUrl).path;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath: path
                                                  isDirectory: &isDir1] ||
             [[NSFileManager defaultManager] isUbiquitousItemAtURL:fileUrl]) {
        
            NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
            NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
            fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
            path = ((NSURL *)fileUrl).path;
            ctr++;
    }
    return fileUrl;
    
}

+ (instancetype)newURLUniqueURLForURL:(NSURL *)url {
    id rurl;
    rurl = [self newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                          withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                               andExtension: url.lastPathComponent.pathExtension];
    return rurl;
}

+ (instancetype)newURLForLocalCacheDirectoryNamed:(NSString *)handle {
    NSURL *url = [MADURL newURLForLocalCacheDirectory];
    id cachedArrayDirectories = [url URLByAppendingPathComponent: handle isDirectory: YES];
    BOOL exist, isDirectory;
    NSString *path = ((NSURL *)cachedArrayDirectories).path;
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
    id url = [self newURLForLocalCacheDirectoryNamed:fileNameId];
    return url;
}

+ (instancetype)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                            pathComponent:(NSString *)pathComponent
                                      alternativeSelector:(SEL)alternativeSelector {
    
    BOOL success = NO, isDirectory = NO;
    NSString *groupID, *pathPart, *cachePath;
    NSURL *groupUrl, *cacheURL;

    groupID = groupIdentifier.copy;
    pathPart = pathComponent.copy;
    
    groupUrl = [[NSFileManager defaultManager]
                       containerURLForSecurityApplicationGroupIdentifier: groupID];
    
    NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil "
                              @"for %@.  Maybe the fucking entitlment file is missing?!?!",
                              groupIdentifier);
    
    cacheURL = [groupUrl URLByAppendingPathComponent: pathPart
                                         isDirectory: YES];
    cachePath = cacheURL.path.copy;
    success = [[NSFileManager defaultManager] fileExistsAtPath: cachePath
                                                   isDirectory: &isDirectory];
    
    if (!success) {
        NSError *error;
        success = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
                                               withIntermediateDirectories: YES
                                                                attributes: nil
                                                                     error: &error];
    }
    
    return success ? cacheURL : [self newURLForURLSelector:alternativeSelector];
}

+ (instancetype)newURLForURLSelector:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                       fileURL:(NSURL *)fileURL {
    NSString *fileNameId;
    fileNameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash];
    return [MADURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier handle:fileNameId];
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                        handle:(NSString *)handle {
    
    NSURL *cacheDirectory = [MADURL newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
    
    id cacheURL = [cacheDirectory URLByAppendingPathComponent:handle isDirectory:YES];
    
    BOOL isDirectory;
    NSString *path = ((NSURL *)cacheURL).path;
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
    id result = [NSURL URLWithString:firstObject];
    return result;
}

+ (instancetype)newURLLocalTemporaryDirectory {
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    id result = [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
    return  result;
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
    id result = [fileUrlWithPath URLByAppendingPathComponent:MADPathComponentData isDirectory:YES];
    return result;
}

+ (instancetype)newURLForLocalApplicationSupportDirectory {
    NSArray <NSURL *> *possibleUrls;
    possibleUrls = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
                                                          inDomains: NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    id appSupportDirectoryForApp = nil;
    
    if (possibleUrls.count >= 1) {
        appSupportDirectory = possibleUrls[0];
        
        BOOL isDirectory;
        NSString *path = appSupportDirectory.path;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                              isDirectory: &isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectory
                                     withIntermediateDirectories: YES
                                                      attributes: nil
                                                           error: &error];
        }
        
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier.copy;
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:bundleIdentifier];
        path = ((NSURL *)appSupportDirectoryForApp).path;
        fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory];
        
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectoryForApp
                                     withIntermediateDirectories: YES
                                                      attributes: nil
                                                           error: &error];
        }
        
    }
    return appSupportDirectoryForApp;
}

+ (instancetype)newURLApplicationSupportFile:(NSString *)filename extension:(NSString *)extension {
    id result;
    NSURL *appSupportDirectory;
    NSString *groupIdentifier, *fileHandle;
    MADAppDelegate appDelegate = [MADApplication AppDelegate];
    
    groupIdentifier = [appDelegate groupIdentifier].copy;
    appSupportDirectory = [MADURL newURLLocalApplicationSupportDirectoryForGroupID: groupIdentifier];
    fileHandle = [[NSString alloc] initWithFormat: @"%@.%@", filename, extension];
    result = [appSupportDirectory URLByAppendingPathComponent:fileHandle isDirectory:NO];
    return result;
}

+ (instancetype)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID {
    id documentsDirectory;
    NSURL *cloudDirectory;
    cloudDirectory = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:ubiquityID];
    documentsDirectory = [cloudDirectory URLByAppendingPathComponent:MADPathComponentDocuments];
    return documentsDirectory;
}

+ (instancetype)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalDocumentsDirectory);
    id url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                               pathComponent: MADPathComponentDocuments
                                         alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalDataDirectory);
    id url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                               pathComponent: MADPathComponentData
                                         alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalCacheDirectory);
    id url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                               pathComponent: MADPathComponentCache
                                         alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLLocalApplicationSupportDirectoryForGroupID:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLForLocalApplicationSupportDirectory);
    id url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                               pathComponent: MADPathComponentAppSupport
                                         alternativeSelector: altSelector];
    return url;
}

+ (instancetype)newURLForLocalTemporaryDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    SEL altSelector = @selector(newURLLocalTemporaryDirectory);
    id url = [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
                                               pathComponent: MADPathComponentTemporary
                                         alternativeSelector: altSelector];
    return url;
}

@end
