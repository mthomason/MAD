//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileUtilities.h"
#import <UIKit/UIKit.h>
#import "NSURL+CommonURLs.h"

static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";
static NSString * const MADPathComponentData       = @"Data";

@implementation MADFileUtilities

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url {
    
    NSString *path = url.path;
    if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO) {
        
        NSError *error = nil;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL: url
                                        options: (NSFileCoordinatorWritingOptions)0 error: &error
                                     byAccessor: ^(NSURL *newURL) {
            
            NSError *errorCreateNew = nil;
            NSString *path = newURL.path;

            [[NSFileManager defaultManager] createDirectoryAtPath: path
                                      withIntermediateDirectories: YES attributes: nil
                                                            error: &errorCreateNew];
            
            NSAssert(errorCreateNew == nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
        }];
        
        NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
    }
}

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId {
    NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension: fileExtension
                                                                       subdirectory: @""];
    
    for (NSURL *url in defaultListURLs) {
        [self copyURLToDocumentsDirectory:url groupId:groupId];
    }
}

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID
                extension:(NSString *)extension {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
        NSURL *documentsDirectoryURL, *documentsDirectoryLocal;
        NSArray <NSURL *> *localDocumentURLs;
        documentsDirectoryURL = [NSURL newURLForCloudDocumentsDirectoryForUbiquityID:ubiquityID],
        documentsDirectoryLocal = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupID];
        
        localDocumentURLs = [fileManager contentsOfDirectoryAtURL: documentsDirectoryLocal
                                       includingPropertiesForKeys: nil
                                                          options: (NSDirectoryEnumerationOptions)0
                                                            error: nil];
        
        for (NSURL *URL in localDocumentURLs) {
            if ([URL.pathExtension isEqualToString:extension]) {
                [self makeItemUbiquitousAtURL: URL
                        documentsDirectoryURL: documentsDirectoryURL];
            }
        }
    });
}

+ (void)makeItemUbiquitousAtURL:(NSURL *)sourceURL
            documentsDirectoryURL:(NSURL *)documentsDirectoryURL {
    
    NSString *destinationFileName = sourceURL.lastPathComponent;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *destinationURL = [documentsDirectoryURL URLByAppendingPathComponent:destinationFileName];
    
    NSString *path = destinationURL.path;
    if ([fileManager isUbiquitousItemAtURL:destinationURL] ||
        (path != nil && [fileManager fileExistsAtPath:path])) {

        destinationURL = [NSURL newURLUniqueURLForURL:destinationURL];
        
    }
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
    });
}

+ (void)readFileAtURL:(NSURL *)url
            withCompletionHandler:(void (^)(MADFile *list, NSError *error))completionHandler {
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *readingIntent;
    readingIntent = [NSFileAccessIntent readingIntentWithURL:url
                                                     options:NSFileCoordinatorReadingWithoutChanges];
    NSArray *intents = [[NSArray alloc] initWithObjects: readingIntent, nil];
    [fileCoordinator coordinateAccessWithIntents: intents
                                           queue: [self queue]
                                      byAccessor: ^(NSError *accessError) {
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
        
        NSData *contents = [[NSData alloc] initWithContentsOfURL:readingIntent.URL
                                                         options:NSDataReadingUncached
                                                           error:&readError];
        
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

+ (void)createFile:(MADFile *)list atURL:(NSURL *)url
                   withCompletionHandler:(void (^)(NSError *))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    NSFileAccessIntent *writing;
    writing = [NSFileAccessIntent writingIntentWithURL:url
                                               options:NSFileCoordinatorWritingForReplacing];
    NSArray <NSFileAccessIntent *> *intents = [[NSArray alloc] initWithObjects:writing, nil];
    [fileCoordinator coordinateAccessWithIntents: intents
                                           queue: [self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        NSError *error;
        
        NSData *serializedListData = [NSKeyedArchiver archivedDataWithRootObject:list];
        
        BOOL success = [serializedListData writeToURL:writing.URL
                                              options:NSDataWritingAtomic error:&error];
        
        if (success) {
            NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
            NSString *path = writing.URL.path;
            [[NSFileManager defaultManager] setAttributes: fileAttributes
                                             ofItemAtPath: path error: nil];
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name
  withCompletionHandler:(void (^)(NSURL *sourceURL, NSURL *newURL,
                                  NSError *error))completionHandler {
    
    NSString *pathExtension = source.lastPathComponent.pathExtension;
    NSString *filename = [name stringByAppendingPathExtension: pathExtension];
    NSURL *desired = [source.URLByDeletingLastPathComponent URLByAppendingPathComponent: filename
                                                                            isDirectory: NO];
    NSURL *destination = [NSURL newURLUniqueURLForURL:desired];

    NSString *status;
    NSError *errorGettingAttributes = nil;
    if ([source getResourceValue:&status forKey:NSURLUbiquitousItemDownloadingStatusKey
                           error:&errorGettingAttributes] &&
        [status isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        [self moveFileAtURL:source toUrl:destination
                   withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(source, result, error);
        }];
    } else {
        [self moveRemoveFileAtURL:source toUrl:destination
            withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(source, result, error);
        }];
    }
}

+ (void)moveRemoveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
      withCompletionHandler:(void (^)(NSURL *, NSError *))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self moveFileAtURL:source toUrl:destination
                   withCompletionHandler:^(NSURL *result, NSError *error) {
            completionHandler(destination, error);
        }];
        
    });
}

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
                      withCompletionHandler:(void (^)(NSURL *result,
                                                      NSError *error))completionHandler {
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

+ (void)duplicateFileAtURL:(NSURL *)url
     withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler {
    
    NSURL *uniqueUrl;
    uniqueUrl = [NSURL newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
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
    
    NSFileAccessIntent *writing;
    writing = [NSFileAccessIntent writingIntentWithURL: url
                                               options: NSFileCoordinatorWritingForDeleting];
    NSArray *intents = [[NSArray alloc] initWithObjects:writing, nil];
    [fileCoordinator coordinateAccessWithIntents:intents
                                           queue:[self queue]
                                      byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSError *error;
        
        [fileManager removeItemAtURL:writing.URL error:&error];
        
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
    NSURL *localDocumentsDirectory = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupId];
    NSString *lastPathComponent = url.lastPathComponent;
    NSURL *toURL = [localDocumentsDirectory URLByAppendingPathComponent:lastPathComponent];
    
    // If the file already exists, don't attempt to copy the version from the bundle.
    NSString *path = toURL.path;
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block NSError *error;
    
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *moving, *replacing;
    moving    = [NSFileAccessIntent writingIntentWithURL: url
                                                 options: NSFileCoordinatorWritingForMoving];
    replacing = [NSFileAccessIntent writingIntentWithURL: toURL
                                                 options: NSFileCoordinatorWritingForReplacing];
    NSArray *intents = [[NSArray alloc] initWithObjects:moving, replacing, nil];
    [fileCoordinator coordinateAccessWithIntents: intents
                                           queue: [self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            // An error occured when trying to coordinate moving URL to toURL.
            //  In your app, handle this gracefully.
            NSLog(@"Couldn't move file: %@ to: %@ error: %@.", url.absoluteString,
                    toURL.absoluteString, accessError.localizedDescription);
            
            return;
        }
        
        BOOL success = NO;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        success = [fileManager copyItemAtURL:moving.URL toURL:replacing.URL error:&error];
        
        if (success) {
            NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
            NSString *path = replacing.URL.path;
            if (path) {
                [fileManager setAttributes:fileAttributes ofItemAtPath:path error:nil];
            }
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

+ (NSArray <__kindof NSURL *> *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                                   andExtention: (NSString *)extenstion {
    NSURL *direcotry = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupIdentifier];
    return [self contentsOfDirectory:direcotry withPathExtension:extenstion];
}

- (NSArray <__kindof NSURL *> *)contentOfDirectory:(NSURL *)directory withExtention:(NSString *)extenstion {
    
    NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSString *path = directory.path;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path
                                                                                     error: &error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        path = fileURL.path;
        if ([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory]) {
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
    NSArray *docPaths;
    docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = docPaths.firstObject;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                                     error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [docPaths.firstObject stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        path = fileURL.path;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extenstion]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (NSArray <__kindof NSURL *> *)contentsOfDirectory:(NSURL *)directory
                                  withPathExtension:(NSString *)extension {
    NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSString *path = directory.path;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                                     error:&error];
    for (NSString *filename in directoryContents) {
        NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        BOOL isDirectory;
        path = fileURL.path;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
            if ([fileURL.pathExtension isEqualToString:extension]) {
                [result addObject:fileURL];
            }
        }
    }
    return result;
}

+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url {
    NSError *error = nil;
    NSString *path;
    if ((path = url.path) == nil) return NO;
    BOOL directoryGood = [[NSFileManager defaultManager] createDirectoryAtPath: path
                                                   withIntermediateDirectories: YES
                                                                    attributes: nil
                                                                         error: &error];
    if (error != nil) {
        directoryGood = NO;
        NSAssert(error, @"Error creating directory!  %@", error);
    }
    return directoryGood;
}

+ (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSLog(@"Remove cached files for document url: %@\n(%s)", documentUrl, __PRETTY_FUNCTION__);

   NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [NSURL newURLForLocalCachedDirectoryForFileUrl: documentUrl];
    NSArray <NSURL *> *cachedFiles;
    cachedFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: cachedDirectory
                                                includingPropertiesForKeys: nil
                                                                   options: (NSDirectoryEnumerationOptions)0
                                                                     error: &error];
    NSURL *cachedFile;
    for (cachedFile in cachedFiles) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

+ (BOOL)removeCachedFileForDocumentUrl:(NSURL *)documentUrl
                       groupIdentifier:(NSString *)groupIdentifier {
    NSLog(@"Remove cached files for document url: %@\n(%s)", documentUrl, __PRETTY_FUNCTION__);

    NSURL *cachedDirectory = [NSURL newURLForLocalCacheDirectoryForGroupIdentifier: groupIdentifier
                                                                           fileURL: documentUrl];
    return [MADFileUtilities removeContentsOfDirectory:cachedDirectory];
}

+ (BOOL)removeContentsOfDirectory:(NSURL *)directory {
    NSError *error = nil;
    NSArray <NSURL *> *files;
    files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: directory
                                          includingPropertiesForKeys: nil
                                                             options: (NSDirectoryEnumerationOptions)0
                                                               error: &error];
    for (NSURL *file in files) {
        [[NSFileManager defaultManager] removeItemAtURL: file error: &error];
    }
    [[NSFileManager defaultManager] removeItemAtURL: directory error: &error];
    return YES;
}

@end
