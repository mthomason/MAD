//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileUtilities.h"
#import "MTApplicationInstance.h"

@implementation MADFileUtilities

+ (NSURL *)localDocumentsDirectory:(NSString *)groupIdentifier {
    NSURL *documentsURL = [[self sharedApplicationGroupContainer:groupIdentifier] URLByAppendingPathComponent:@"Documents" isDirectory:YES];
    
    NSError *error;
    // This will return `YES` for success if the directory is successfully created, or already exists.
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:documentsURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (success) {
        return documentsURL;
    }
    else {
        NSLog(@"The shared application group documents directory doesn't exist and could not be created. Error: %@", error.localizedDescription);
        abort();
    }
}

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

+ (void)migrateLocalListsToCloud:(NSString *)groupIdentifier extension:(NSString *)extension {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
        NSURL *cloudDirectoryURL = [fileManager URLForUbiquityContainerIdentifier:nil];
        
        NSURL *documentsDirectoryURL = [cloudDirectoryURL URLByAppendingPathComponent:@"Documents"];
        
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL: [self localDocumentsDirectory:groupIdentifier]
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
        // If the file already exists in the cloud, remove the local version and return.
        [self removeListAtURL:sourceURL withCompletionHandler:nil];
        return;
    }
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
    });
}

+ (void)readListAtURL:(NSURL *)url withCompletionHandler:(void (^)(MADList *list, NSError *error))completionHandler {
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
        MADList *deserializedList;
        
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

+ (void)createList:(MADList *)list atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *))completionHandler {
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

+ (void)removeListAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler {
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
    NSURL *toURL = [[MADFileUtilities localDocumentsDirectory:groupId] URLByAppendingPathComponent:url.lastPathComponent];
    
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
