//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileUtilities.h"
#import <UIKit/UIKit.h>

static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";
static NSString * const MADPathComponentData       = @"Data";

@implementation MADFileUtilities

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path] == NO) {
        
        NSError *error = nil;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL: url options: 0 error: &error byAccessor: ^(NSURL *newURL) {
            
            NSError *errorCreateNew = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath: newURL.path withIntermediateDirectories: YES attributes: nil error: &errorCreateNew];
            
            NSAssert(errorCreateNew == nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
        }];
        
        NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}

+ (NSURL *)sharedApplicationGroupContainer:(NSString *)groupIdentifier {
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSAssert(containerURL != nil, @"The shared application group container is unavailable. Check your entitlements and provisioning profiles for this target. Details on proper setup can be found in the PDFs referenced from the README.");
    return containerURL;
}

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId {
    NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension: fileExtension subdirectory: @""];
    
    for (NSURL *url in defaultListURLs) {
        [self copyURLToDocumentsDirectory:url groupId:groupId];
    }
}

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID extension:(NSString *)extension {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
        NSURL *documentsDirectoryURL = [self cloudDocumentsDirectoryForUbiquityID:ubiquityID];
        NSURL *documentsDirectoryLocal = [self localDocumentsDirectoryForGroupIdentifier:groupID];
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL: documentsDirectoryLocal
                                                includingPropertiesForKeys: nil
                                                                   options: 0
                                                                     error: nil];
        
        for (NSURL *URL in localDocumentURLs) {
            if ([URL.pathExtension isEqualToString:extension]) {
                [self makeItemUbiquitousAtURL: URL
                        documentsDirectoryURL: documentsDirectoryURL];
            }
        }
    });
}

+ (void)makeItemUbiquitousAtURL:(NSURL *)sourceURL documentsDirectoryURL:(NSURL *)documentsDirectoryURL {
    NSString *destinationFileName = sourceURL.lastPathComponent;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *destinationURL = [documentsDirectoryURL URLByAppendingPathComponent:destinationFileName];
    
    if ([fileManager isUbiquitousItemAtURL:destinationURL] ||
        [fileManager fileExistsAtPath:destinationURL.path]) {

        destinationURL = [MADFileUtilities uniqueURLForURL:destinationURL];
        
    }
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
    });
}

+ (void)readFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(MADFile *list, NSError *error))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *readingIntent = [NSFileAccessIntent readingIntentWithURL:url options:NSFileCoordinatorReadingWithoutChanges];
    [fileCoordinator coordinateAccessWithIntents:@[readingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (successfulSecurityScopedResourceAccess) {
                [url stopAccessingSecurityScopedResource];
            }
            
            if (completionHandler) {
                completionHandler(nil, accessError);
            }
            
            return;
        }
        
        // Local variables that will be used as parameters to `completionHandler`.
        NSError *readError;
        MADFile *deserializedList;
        
        NSData *contents = [NSData dataWithContentsOfURL:readingIntent.URL options:NSDataReadingUncached error:&readError];
        
        if (contents) {
            deserializedList = [NSKeyedUnarchiver unarchiveObjectWithData:contents];
            
            NSAssert(deserializedList != nil, @"The provided URL must correspond to an AAPLList object.");
        }
        
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        
        if (completionHandler) {
            completionHandler(deserializedList, readError);
        }
    }];
}

+ (void)createFile:(MADFile *)list atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    NSFileAccessIntent *writingIntent = [NSFileAccessIntent writingIntentWithURL:url options:NSFileCoordinatorWritingForReplacing];
    [fileCoordinator coordinateAccessWithIntents:@[writingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        NSError *error;
        
        NSData *serializedListData = [NSKeyedArchiver archivedDataWithRootObject:list];
        
        BOOL success = [serializedListData writeToURL:writingIntent.URL options:NSDataWritingAtomic error:&error];
        
        if (success) {
            NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
            
            [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:writingIntent.URL.path error:nil];
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name withCompletionHandler:(void (^)(NSURL *sourceURL, NSURL *newURL, NSError *error))completionHandler {
    NSString *filename = [name stringByAppendingPathExtension:source.lastPathComponent.pathExtension];
    NSURL *desired = [source.URLByDeletingLastPathComponent URLByAppendingPathComponent:filename isDirectory:NO];
    NSURL *destination = [MADFileUtilities uniqueURLForURL:desired];

    NSString *status;
    NSError *errorGettingAttributes = nil;
    if ([source getResourceValue:&status forKey:NSURLUbiquitousItemDownloadingStatusKey error:&errorGettingAttributes] &&
        [status isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        [self moveFileAtURL:source toUrl:destination withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(source, result, error);
        }];
    } else {
        [self moveRemoveFileAtURL:source toUrl:destination withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(source, result, error);
        }];
    }
}

+ (void)moveRemoveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination withCompletionHandler:(void (^)(NSURL *, NSError *))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self moveFileAtURL:source toUrl:destination withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(destination, error);
        }];
        
    });
}

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler {
    NSError *coordinatorError = nil;
    
    BOOL successfulSecurityScopedResourceAccess = [source startAccessingSecurityScopedResource];
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL: source
                                    options: NSFileCoordinatorWritingForMoving
                           writingItemAtURL: destination
                                    options: NSFileCoordinatorWritingForReplacing
                                      error: &coordinatorError
                                 byAccessor: ^(NSURL *accessorSource, NSURL *accessorDestination) {
                                     
                                     __block NSError *moveError = nil;
                                     BOOL success = [[NSFileManager defaultManager] moveItemAtURL: accessorSource
                                                                                       toURL: accessorDestination
                                                                                       error: &moveError];
                                     if (success) {
                                         [coordinator itemAtURL:accessorSource didMoveToURL:accessorDestination];
                                     }
                                     if (successfulSecurityScopedResourceAccess) {
                                         [source stopAccessingSecurityScopedResource];
                                     }
                                     
                                     completionHandler(accessorDestination, moveError);

                                 }];

}

+ (NSURL *)uniqueURLForURL:(NSURL *)url {
    return [self uniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                    withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                         andExtension: url.lastPathComponent.pathExtension];
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory withDesiredHandle:(NSString *)desiredFileHandle andExtension:(NSString *)extension {
    
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *fileUrl = extension.length > 0 ?
    [baseUrl URLByAppendingPathExtension: extension] :
    baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path isDirectory:&isDir1] ||
           [[NSFileManager defaultManager] isUbiquitousItemAtURL:fileUrl]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return fileUrl;
    
}

+ (void)duplicateFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler {
    
    NSURL *uniqueUrl = [self uniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                                          withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                                               andExtension: url.lastPathComponent.pathExtension];

    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];

    NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    [coordinator coordinateReadingItemAtURL: url
                                    options: NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL: uniqueUrl                              // FIXME: Try copying url to url, and have it auto unique.
                                    options: NSFileCoordinatorWritingForMoving
                                      error: &error
                                 byAccessor: ^(NSURL *source, NSURL *destinaion) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *errorCopy = nil;

        BOOL success = [fileManager copyItemAtURL: source
                                            toURL: destinaion
                                            error: &errorCopy];
                                     
        if (success) {
            [coordinator itemAtURL:source didMoveToURL:destinaion];
        }
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        if (completionHandler) {
            completionHandler(destinaion, errorCopy);
        }

    }];
}

+ (void)removeFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *writingIntent = [NSFileAccessIntent writingIntentWithURL:url options:NSFileCoordinatorWritingForDeleting];
    [fileCoordinator coordinateAccessWithIntents:@[writingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSError *error;
        
        [fileManager removeItemAtURL:writingIntent.URL error:&error];
        
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

#pragma mark - Convenience

+ (void)copyURLToDocumentsDirectory:(NSURL *)url groupId:(NSString *)groupId {
    NSURL *localDocumentsDirectory = [self localDocumentsDirectoryForGroupIdentifier:groupId];
    NSURL *toURL = [localDocumentsDirectory URLByAppendingPathComponent:url.lastPathComponent];
    
    // If the file already exists, don't attempt to copy the version from the bundle.
    if ([[NSFileManager defaultManager] fileExistsAtPath:toURL.path]) {
        return;
    }
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block NSError *error;
    
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *movingIntent = [NSFileAccessIntent writingIntentWithURL:url options:NSFileCoordinatorWritingForMoving];
    NSFileAccessIntent *replacingIntent = [NSFileAccessIntent writingIntentWithURL:toURL options:NSFileCoordinatorWritingForReplacing];
    [fileCoordinator coordinateAccessWithIntents:@[movingIntent, replacingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            // An error occured when trying to coordinate moving URL to toURL. In your app, handle this gracefully.
            NSLog(@"Couldn't move file: %@ to: %@ error: %@.", url.absoluteString, toURL.absoluteString, accessError.localizedDescription);
            
            return;
        }
        
        BOOL success = NO;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        success = [fileManager copyItemAtURL:movingIntent.URL toURL:replacingIntent.URL error:&error];
        
        if (success) {
            NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
            
            [fileManager setAttributes:fileAttributes ofItemAtPath:replacingIntent.URL.path error:nil];
        }
        
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        
        if (!success) {
            // An error occured when moving URL to toURL. In your app, handle this gracefully.
            NSLog(@"Couldn't move file: %@ to: %@.", url.absoluteString, toURL.absoluteString);
        }
    }];
}

/// An internal queue to the \c AAPLListUtilities class that is used for \c NSFileCoordinator callbacks.
+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}


















+ (NSURL *)cloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID {
    NSURL *cloudDirectoryURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:ubiquityID];
    NSURL *documentsDirectoryURL = [cloudDirectoryURL URLByAppendingPathComponent:MADPathComponentDocuments];
    return documentsDirectoryURL;
}

+ (NSURL *)localDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier pathComponent: MADPathComponentDocuments
                              alternativeSelector: @selector(localDocumentsDirectory)];
}

+ (NSURL *)localDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier pathComponent: MADPathComponentData
                              alternativeSelector: @selector(localDataDirectory)];
}

+ (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier pathComponent: MADPathComponentCache
                              alternativeSelector: @selector(localCacheDirectory)];
}

+ (NSURL *)localApplicationSupportDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier pathComponent: MADPathComponentAppSupport
                              alternativeSelector: @selector(localApplicationSupportDirectory)];
}

+ (NSURL *)localTemporaryDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
    return [self localDirectoryForGroupIdentifier: groupIdentifier pathComponent: MADPathComponentTemporary
                              alternativeSelector: @selector(localTemporaryDirectory)];
}

+ (NSURL *)localDirectoryForGroupIdentifier:(NSString *)groupIdentifier pathComponent:(NSString *)pathComponent
                        alternativeSelector:(SEL)alternativeSelector {
    
    NSAssert(groupIdentifier != nil, @"Need a group identifier... %s", __PRETTY_FUNCTION__);
    NSError *error;
    NSURL *groupUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    
    NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil for %@.  Maybe the fucking entitlment file is missing?!?!", groupIdentifier);
    NSURL *cacheURL = [groupUrl URLByAppendingPathComponent: pathComponent isDirectory: YES];
    BOOL isDirectory;
    BOOL success = [[NSFileManager defaultManager] fileExistsAtPath: cacheURL.path isDirectory: &isDirectory];
    
    if (!success) {
        isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL withIntermediateDirectories: YES attributes: nil error: &error];
    }
    
    return isDirectory ? cacheURL : [self urlForURLSelector:alternativeSelector];
}

+ (NSURL *)urlForURLSelector:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    NSURL *(*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

+ (NSArray <__kindof NSURL *> *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier andExtention: (NSString *)extenstion {
    NSURL *direcotry = [self localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
    return [self contentsOfDirectory:direcotry withPathExtension:extenstion];
}

+ (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier fileURL:(NSURL *)fileURL {
    NSString *fileNameId = [NSString stringWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash];
    return [MADFileUtilities localCacheDirectoryForGroupIdentifier:groupIdentifier handle:fileNameId];
}

+ (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier handle:(NSString *)handle {
    
    NSURL *cacheDirectory = [MADFileUtilities localCacheDirectoryForGroupIdentifier:groupIdentifier];
    
    NSURL *cacheURL = [cacheDirectory URLByAppendingPathComponent:handle isDirectory:YES];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheURL.path isDirectory:&isDirectory]) {
        
        NSError * __autoreleasing *error = NULL;
        isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL withIntermediateDirectories: YES attributes: nil error: error];
        
    }
    return cacheURL;
}

- (NSArray <__kindof NSURL *> *)contentOfDirectory:(NSURL *)directory withExtention:(NSString *)extenstion {
    
    NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory.path error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath: fileURL.path isDirectory: &isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}


+ (NSArray <__kindof NSURL *> *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion {
    
    NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPaths.firstObject error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [docPaths.firstObject stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (NSURL *)localCacheDirectoryNamed:(NSString *)handle {
    
    NSURL *cachedArrayDirectories = [[MADFileUtilities localCacheDirectory] URLByAppendingPathComponent: handle isDirectory: YES];
    BOOL exist, isDirectory;
    exist = [[NSFileManager defaultManager] fileExistsAtPath: cachedArrayDirectories.path isDirectory: &isDirectory];
    if (exist == NO || isDirectory == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL: cachedArrayDirectories withIntermediateDirectories: YES attributes: nil error: &error];
        if (error) {
            error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:cachedArrayDirectories withIntermediateDirectories:YES attributes:nil error:&error];
        }
        NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
    }
    return cachedArrayDirectories;
}

+ (NSArray <__kindof NSURL *> *)contentsOfDirectory:(NSURL *)directory withPathExtension:(NSString *)extension {
    NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory.path error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extension]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (NSURL *)localCachedDirectoryForFileUrl:(NSURL *)fileUrl {
    NSString *fileNameId = [NSString stringWithFormat:@"%lu", (unsigned long)fileUrl.lastPathComponent.stringByDeletingPathExtension.hash];
    return [self localCacheDirectoryNamed:fileNameId];
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
    NSURL *fileUrlWithPath = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    return  [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
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
    NSArray *possibleUrls = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask];
    NSURL *appSupportDirectory = nil;
    NSURL *appSupportDirectoryForApp = nil;
    
    if (possibleUrls.count >= 1) {
        appSupportDirectory = possibleUrls[0];
        
        BOOL isDirectory;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath: appSupportDirectory.path isDirectory: &isDirectory];
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectory withIntermediateDirectories: YES attributes: nil error: &error];
        }
        
        appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:mainBundle.bundleIdentifier];
        fileExist = [[NSFileManager defaultManager] fileExistsAtPath: appSupportDirectoryForApp.path isDirectory: &isDirectory];
        
        if (fileExist == NO) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectoryForApp withIntermediateDirectories: YES attributes: nil error: &error];
        }
        
    }
    return appSupportDirectoryForApp;
}


+ (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [MADFileUtilities localCachedDirectoryForFileUrl:documentUrl];
    NSArray *contentsOfDirectoryAtUrlCachedDirectory = [defaultManager contentsOfDirectoryAtURL: cachedDirectory
                                                                     includingPropertiesForKeys: nil
                                                                                        options: 0 error: &error];
    for (NSURL *cachedFile in contentsOfDirectoryAtUrlCachedDirectory) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

+ (BOOL)removeCachedFileForDocumentUrl:(NSURL *)documentUrl groupIdentifier:(NSString *)groupIdentifier {
    NSURL *cachedDirectory = [MADFileUtilities localCacheDirectoryForGroupIdentifier: groupIdentifier fileURL: documentUrl];
    return [MADFileUtilities removeContentsOfDirectory:cachedDirectory];
}

+ (BOOL)removeContentsOfDirectory:(NSURL *)directory {
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: directory includingPropertiesForKeys: nil
                                            options: 0 error: &error];
    for (NSURL *file in files) {
        [[NSFileManager defaultManager] removeItemAtURL: file error: &error];
    }
    [[NSFileManager defaultManager] removeItemAtURL: directory error: &error];
    return YES;
}

@end
