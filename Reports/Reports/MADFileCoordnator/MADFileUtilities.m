//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileUtilities.h"
#import <UIKit/UIKit.h>
#import "MTApplicationInstance.h"
#import "NSFileManager+Common.h"
#import "MACloudManager.h"
#import "MADocument.h"

@implementation MADFileUtilities

+ (NSURL *)sharedApplicationGroupContainer:(NSString *)groupIdentifier {
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    
    NSAssert(containerURL != nil, @"The shared application group container is unavailable. Check your entitlements and provisioning profiles for this target. Details on proper setup can be found in the PDFs referenced from the README.");
    
    return containerURL;
}

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId {
    NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension: fileExtension
                                                                       subdirectory: @""];
    
    for (NSURL *url in defaultListURLs) {
        [self copyURLToDocumentsDirectory:url groupId:groupId];
    }
}

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID extension:(NSString *)extension {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] cloudDocumentsDirectoryForUbiquityID:ubiquityID];
        NSURL *documentsDirectoryLocal = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupID];
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

        destinationURL = [MACloudManager uniqueURLForURL:destinationURL];
        
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
    NSURL *desired = [source.URLByDeletingLastPathComponent URLByAppendingPathComponent:name isDirectory:NO];
    desired = [desired URLByAppendingPathExtension:source.lastPathComponent.pathExtension];
    NSURL *destination = [MACloudManager uniqueUrlInDirectory: desired.URLByDeletingLastPathComponent
                                            withDesiredHandle: desired.lastPathComponent.stringByDeletingPathExtension
                                                 andExtension: source.lastPathComponent.pathExtension];
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
    UIDocument * doc = [[MADocument alloc] initWithFileURL:source];
    [doc openWithCompletionHandler:^(BOOL success) {
        [doc closeWithCompletionHandler:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    [self moveFileAtURL:source toUrl:destination withCompletionHandler:^(NSURL *result, NSError *error) {
                        completionHandler(destination, error);
                    }];
                    
                });
            } else {
                completionHandler(source, nil);
            }
        }];
    }];
}

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler {
    NSError *coordinatorError = nil;
    
    BOOL successfulSecurityScopedResourceAccess = [source startAccessingSecurityScopedResource];
    __block NSError *moveError = nil;
    __block BOOL success = NO;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL: source
                                    options: NSFileCoordinatorWritingForMoving
                           writingItemAtURL: destination
                                    options: NSFileCoordinatorWritingForReplacing
                                      error: &coordinatorError
                                 byAccessor: ^(NSURL *accessorSource, NSURL *accessorDestination) {
                                     
                                     success = [[NSFileManager defaultManager] moveItemAtURL: accessorSource
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

+ (void)duplicateFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler {
    
    NSURL *uniqueUrl = [MACloudManager uniqueUrlInDirectory: url.URLByDeletingLastPathComponent
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
    NSURL *localDocumentsDirectory = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupId];
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

@end
