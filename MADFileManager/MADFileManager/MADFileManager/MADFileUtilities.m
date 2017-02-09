//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileUtilities.h"
#import <MADFoundation/MADURL.h>
#import <MADFoundation/NSURL+Document.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileCoordinator.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSData.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSFileWrapper.h>

static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";
static NSString * const MADPathComponentData       = @"Data";

@implementation MADFileUtilities

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
    BOOL isDirectory;
    
    NSString *destinationPath = destinationUrl.path.copy;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
                                                       isDirectory: &isDirectory];
    if (exists) {
        if (isDirectory) {
            
            BOOL(^ErrorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *url, NSError *error) {
                NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
                return YES;
            };
            
            NSArray *requestedKeys = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: destinationUrl
                                                                     includingPropertiesForKeys: requestedKeys
                                                                                        options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                                   errorHandler: ErrorHandler];
            
            //dispatch_queue_t queueHigh = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
            //dispatch_group_t group = dispatch_group_create();
            //dispatch_group_enter(group);
            
            for (NSURL *fileURL in enumerator) {
                NSURL *file = fileURL.copy;
                //dispatch_group_async(group, queueHigh, ^{
                    //@autoreleasepool {
                    [MADFileUtilities removeFileAtURL:file];
                    //}
                //});
            }
            
            NSURL *file = destinationUrl.copy;
            //dispatch_group_async(group, queueHigh, ^{
                //@autoreleasepool {
                [MADFileUtilities removeFileAtURL:file];
                //}
            //});
            //dispatch_group_leave(group);
            //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            
        }
    }
}

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
        documentsDirectoryURL = [MADURL newURLForCloudDocumentsDirectoryForUbiquityID:ubiquityID],
        documentsDirectoryLocal = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupID];
        
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

        destinationURL = [MADURL newURLUniqueURLForURL:destinationURL];
        
    }
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
    });
}

+ (void)readFileAtURL:(NSURL *)url
            completion:(void (^)(MADFile *list, NSError *error))completion {
    
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
            
            if (completion) {
                completion(nil, accessError);
            }
            
            return;
        }
        
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
        
        if (completion) {
            completion(deserializedList, readError);
        }
    }];
}

+ (void)createFile:(MADFile *)list atURL:(NSURL *)url
                              completion:(void (^)(NSError *))completion {
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    NSFileAccessIntent *writing;
    writing = [NSFileAccessIntent writingIntentWithURL:url
                                               options:NSFileCoordinatorWritingForReplacing];
    NSArray <NSFileAccessIntent *> *intents = [[NSArray alloc] initWithObjects:writing, nil];
    [fileCoordinator coordinateAccessWithIntents: intents
                                           queue: [self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completion) {
                completion(accessError);
            }
            
            return;
        }
        
        NSError *error;
        
        NSData *serializedListData = [NSKeyedArchiver archivedDataWithRootObject:list];
        
        BOOL success = [serializedListData writeToURL:writing.URL
                                              options:NSDataWritingAtomic error:&error];
        
        if (success) {
            NSDictionary <NSString *, NSNumber *> *fileAttributes;
            fileAttributes = @{ NSFileExtensionHidden : @YES };
            NSString *path = writing.URL.path;
            [[NSFileManager defaultManager] setAttributes: fileAttributes
                                             ofItemAtPath: path
                                                    error: nil];
        }
        
        if (completion) {
            completion(error);
        }
    }];
}

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name
             completion:(void (^)(NSURL *sourceURL, NSURL *newURL,
                                  NSError *error))completion {
    
    NSString *pathExtension = source.lastPathComponent.pathExtension;
    NSString *filename = [name stringByAppendingPathExtension: pathExtension];
    NSURL *desired = [source.URLByDeletingLastPathComponent URLByAppendingPathComponent: filename
                                                                            isDirectory: NO];
    NSURL *destination = [MADURL newURLUniqueURLForURL:desired];

    NSString *status;
    NSError *errorGettingAttributes = nil;
    if ([source getResourceValue:&status forKey:NSURLUbiquitousItemDownloadingStatusKey
                           error:&errorGettingAttributes] &&
        [status isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        [self moveFileAtURL:source toUrl:destination
                   completion:^(NSURL *result, NSError *error) {
            completion(source, result, error);
        }];
    } else {
        [self moveRemoveFileAtURL:source toUrl:destination
            completion:^(NSURL *result, NSError *error) {
            completion(source, result, error);
        }];
    }
}

+ (void)moveRemoveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
      completion:(void (^)(NSURL *, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self moveFileAtURL:source toUrl:destination
                   completion:^(NSURL *result, NSError *error) {
            completion(destination, error);
        }];
        
    });
}

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
                                 completion:(void (^)(NSURL *result,
                                                      NSError *error))completion {
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
                                     
        completion(accessorDestination, moveError);

    }];

}

+ (void)duplicateFileAtURL:(NSURL *)url
                completion:(void (^)(NSURL *result, NSError *error))completion {
    
    NSURL *uniqueUrl;
    uniqueUrl = [MADURL newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
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
            if (completion) {
                completion(nil, error);
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
        if (completion) {
            completion(destinaion, errorCopy);
        }

    }];
}

+ (void)removeFileAndArchiveAtURL:(NSURL *)url {
    BOOL (^errorHandler)(NSURL *, NSError *);
    errorHandler = ^BOOL(NSURL *errorUrl, NSError *error) {
        //NSLog(@"Error %@", error);
        return YES;
    };
    NSArray *propertyKeys = [[NSArray alloc] initWithObjects: NSURLIsDirectoryKey, nil];
    NSDirectoryEnumerator *enumerator;
    enumerator = [[NSFileManager defaultManager] enumeratorAtURL: url
                                      includingPropertiesForKeys: propertyKeys
                                                         options: NSNotFound
                                                    errorHandler: errorHandler];
    for (NSURL *fileURL in enumerator) {
        [MADFileUtilities removeFileAtURL:fileURL];
    }
    [MADFileUtilities removeFileAtURL:url];
    
}

+ (void)removeFileAtURL:(NSURL *)url {
    [self removeFileAtURL:url completion:NULL];
}

+ (void)removeFileAtURL:(NSURL *)url completion:(void (^)(NSError *error))completion {
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
            if (completion) {
                completion(accessError);
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSError *error;
        
        [fileManager removeItemAtURL:writing.URL error:&error];
        
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - Convenience

+ (void)copyURLToDocumentsDirectory:(NSURL *)url groupId:(NSString *)groupId {
    NSURL *localDocumentsDirectory = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupId];
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
            //NSLog(@"Couldn't move file: %@ to: %@ error: %@.", url.absoluteString,
            //        toURL.absoluteString, accessError.localizedDescription);
            
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
            //NSLog(@"Couldn't move file: %@ to: %@.", url.absoluteString, toURL.absoluteString);
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

+ (NSArray <NSURL *> *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                          andExtention: (NSString *)extenstion {
    NSURL *direcotry = [MADURL newURLLocalDocumentsDirectoryForGroupIdentifier:groupIdentifier];
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

+ (NSArray <NSURL *> *)contentsOfDirectory:(NSURL *)directory
                         withPathExtension:(NSString *)extension {
    NSMutableArray <NSURL *> *result = [[NSMutableArray alloc] init];
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
    //NSLog(@"Remove cached files for document url: %@\n(%s)", documentUrl, __PRETTY_FUNCTION__);

   NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [MADURL newURLForLocalCachedDirectoryForFileUrl: documentUrl];
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
    //NSLog(@"Remove cached files for document url: %@\n(%s)", documentUrl, __PRETTY_FUNCTION__);

    NSURL *cachedDirectory = [MADURL newURLForLocalCacheDirectoryForGroupIdentifier: groupIdentifier
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

+ (BOOL)restoreFileWrapper:(NSURL *)originURL archiveURL:(NSURL *)archiveURL
                 overwrite:(BOOL)overwrite {
    BOOL success = NO;
    NSFileWrapper *fileWrapper;
    NSError *fileWrapperError = nil;
    fileWrapper = [[NSFileWrapper alloc] initWithURL: originURL
                                             options: NSFileWrapperReadingImmediate
                                               error: &fileWrapperError];
    
    NSURL *resultUrl;
    
    if (fileWrapperError == nil) {
        if (overwrite) {
            NSData *data = fileWrapper.serializedRepresentation;
            NSError *errorWriting = nil;
            success = [data writeToURL: archiveURL
                               options: NSDataWritingAtomic
                                 error: &errorWriting];
        } else {
            resultUrl = [MADURL newURLWithUniqueFilenameForURL:archiveURL];
            NSData *data = fileWrapper.serializedRepresentation;
            success = [data writeToURL:resultUrl atomically:YES];
        }
    }
    return success;
}

@end
