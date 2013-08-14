//
//  CloudManager.m
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "CloudManager.h"

NSString * const ICloudStateUpdatedNotification                     = @"ICloudStateUpdatedNotification";
NSString * const UbiquitousContainerFetchingWillBeginNotification   = @"UbiquitousContainerFetchingWillBeginNotification";
NSString * const UbiquitousContainerFetchingDidEndNotification      = @"UbiquitousContainerFetchingDidEndNotification";

static CloudManager *__sharedManager;

@interface CloudManager ()

@property (nonatomic, retain, readwrite) NSURL *dataDirectoryURL;
@property (nonatomic, retain, readwrite) NSURL *documentsDirectoryURL;

@end

@implementation CloudManager

+ (id)allocWithZone:(NSZone *)zone {
    //Do not release... this is a singleton yo.
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release { }

- (id)autorelease {
    return self;
}

+ (CloudManager*)sharedManager {
    return __sharedManager;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedManager = [[super allocWithZone:NULL] init];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(updateICloudEnabled:)
                                                     name: NSUbiquityIdentityDidChangeNotification
                                                   object: nil];
        [__sharedManager updateFileStorageContainerURL:nil];
    });
}

- (void)setIsCloudEnabled:(BOOL)isCloudEnabled {

    // Asynchronously update our data directory URL and documents directory URL
    // If we're enabling cloud storage, we move any local documents into the cloud container after the URLs are updated.
    
    if (isCloudEnabled != _isCloudEnabled) {
        _isCloudEnabled = isCloudEnabled;
        NSURL *oldDataDirectoryURL = [self dataDirectoryURL];
        NSURL *oldDocumentsDirectoryURL = [self documentsDirectoryURL];
        
        [self updateFileStorageContainerURL:^(void) {
            if (isCloudEnabled) {
                // Now move any existing local documents into iCloud.
                NSDirectoryEnumerationOptions enumerationOptions = NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
                
                NSError *readDocumentsError = nil;
                NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDocumentsDirectoryURL
                                                                        includingPropertiesForKeys:nil
                                                                                           options:enumerationOptions
                                                                                             error:&readDocumentsError];
                NSError *readPreviewsError = nil;
                NSArray *localPreviews = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDataDirectoryURL
                                                                       includingPropertiesForKeys:nil
                                                                                          options:enumerationOptions
                                                                                            error:&readPreviewsError];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    NSFileManager* fileManager = [[NSFileManager alloc] init];
                    NSURL *newDataDirectoryURL = [self dataDirectoryURL];
                    NSURL *newDocumentsDirectoryURL = [self documentsDirectoryURL];
                    
                    for (NSURL *documentURL in localDocuments) {
                        if ([[documentURL pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
                            NSURL *destinationURL = [newDocumentsDirectoryURL URLByAppendingPathComponent:[documentURL lastPathComponent]];
                            [fileManager setUbiquitous:YES itemAtURL:documentURL destinationURL:destinationURL error:nil];
                        }
                    }
                    
                    for (NSURL *previewURL in localPreviews) {
                        if ([[previewURL pathExtension] isEqualToString:@"preview"]) {
                            NSURL* destinationURL = [newDataDirectoryURL URLByAppendingPathComponent:[previewURL lastPathComponent]];
                            [fileManager setUbiquitous:YES itemAtURL:previewURL destinationURL:destinationURL error:nil];
                        }
                    }
                });
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:ICloudStateUpdatedNotification object:nil];
    }
}

- (NSURL *)documentsDirectoryURL {
    return [[self dataDirectoryURL] URLByAppendingPathComponent:@"Documents"];
}

- (void)updateFileStorageContainerURL:(void (^)(void))completionHandler {

    @synchronized (self) {
        [self setDataDirectoryURL:nil];
        if ([self isCloudEnabled]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:UbiquitousContainerFetchingWillBeginNotification object:nil];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSURL *url = [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MTDocumentTypeUtiMad] retain];
                [self setDataDirectoryURL:url];
                [url release];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:UbiquitousContainerFetchingDidEndNotification object:nil];
                    
                    if (completionHandler) {
                        completionHandler();
                    }
                });
            });
        } else {
            [self setDataDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES]];
        }
    }
}

- (void)updateICloudEnabled:(NSNotification *)notification {
    
    if ([[NSFileManager defaultManager] ubiquityIdentityToken]) {
        if ([self isCloudEnabled]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ICloudStateUpdatedNotification object:nil];
        }
    }
    else {
        [self setIsCloudEnabled: NO];
    }
}

@end
