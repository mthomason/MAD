//
//  MADCloudFileCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCloudFileCoordinator.h"
#import "MADFileCoordinatorDelegate.h"
#import "MADFileCoordinatorProtocol.h"

#import <Foundation/NSMetadata.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationQueue.h>

#import <dispatch/dispatch.h>

#import "MADFileUtilities.h"
#import "MADMetaData.h"

#import <MADFoundation/MADURL.h>

NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADCloudFileCoordinator ()

    @property (nonatomic, strong) NSMetadataQuery *metadataQuery;
    @property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;
    @property (nonatomic, copy) void (^firstQueryUpdateHandler)(void);

@end

@implementation MADCloudFileCoordinator

@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate identifier:(NSString *)ubiquityIdentifier
          firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    if (self = [super init]) {
        
        self.firstQueryUpdateHandler = firstQueryUpdateHandler;
        
        const char *queue_name = "com.everydayapps.mad.cloudfilecoordinator.documentsDirectory";
        dispatch_queue_t documentsDirectoryQueue;
        documentsDirectoryQueue = dispatch_queue_create(queue_name,
                                                        DISPATCH_QUEUE_SERIAL);
        self.documentsDirectoryQueue = documentsDirectoryQueue;
        
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        metadataQuery.searchScopes = @[//NSMetadataQueryUbiquitousDataScope,
                                       //NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                       NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                       NSMetadataQueryUbiquitousDocumentsScope];
        metadataQuery.notificationBatchingInterval = 0.5000;
        metadataQuery.predicate = predicate.copy;

        [self addObserversToQuery:metadataQuery];
        self.metadataQuery = metadataQuery;
        
        MADCloudFileCoordinator __unsafe_unretained * wself = self;
        dispatch_barrier_async(self.documentsDirectoryQueue, ^{
            wself->_documentsDirectory =
                [MADURL newURLForCloudDocumentsDirectoryForUbiquityID:ubiquityIdentifier];
        });
    }
    
    return self;
}

- (void)addObserversToQuery:(NSMetadataQuery *)metadataQuery {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self
                           selector: @selector(metadataQueryDidFinishGathering:)
                               name: NSMetadataQueryDidFinishGatheringNotification
                             object: metadataQuery];
    
    [notificationCenter addObserver: self
                           selector: @selector(metadataQueryDidUpdate:)
                               name: NSMetadataQueryDidUpdateNotification
                             object: metadataQuery];
    
    [notificationCenter addObserver: self
                           selector: @selector(handleMetadataQueryDidStartGatheringNotification:)
                               name: NSMetadataQueryDidStartGatheringNotification
                             object: metadataQuery];
    
    [notificationCenter addObserver: self
                           selector: @selector(handleMetadataQueryGatheringProgressNotification:)
                               name: NSMetadataQueryGatheringProgressNotification
                             object: metadataQuery];
}

- (void)removeObservers {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification
                                object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification
                                object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidStartGatheringNotification
                                object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryGatheringProgressNotification
                                object:_metadataQuery];

}

- (instancetype)initWithPathExtension:(NSString *)pathExtension
                           identifier:(NSString *)ubiquityIdentifier
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)",
                              NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate identifier:ubiquityIdentifier
           firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) { }

    predicate = nil;
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
                               identifier:(NSString *)ubiquityIdentifier
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)",
                              NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate identifier:ubiquityIdentifier
           firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) { }
    
    predicate = nil;
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc {
    [self removeObservers];
}

#pragma mark - Property Overrides

- (NSURL *)documentsDirectory {
    __block NSURL *documentsDirectory;
    
    MADCloudFileCoordinator __unsafe_unretained * wself = self;
    dispatch_sync(self.documentsDirectoryQueue, ^{
        documentsDirectory = wself->_documentsDirectory;
    });
    
    return documentsDirectory;
}

#pragma mark - MADFileCoordinator

- (void)startQuery {
    NSMetadataQuery *__weak metadataQuery = self.metadataQuery;
    dispatch_async(dispatch_get_main_queue(), ^{
        [metadataQuery startQuery];
    });
}

- (void)stopQuery {
    NSMetadataQuery *__weak metadataQuery = self.metadataQuery;
    dispatch_async(dispatch_get_main_queue(), ^{
        [metadataQuery stopQuery];
    });
}

- (void)createURLForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention
               fileGroup:(NSString *)fileGroup {
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    
    typeof(_delegate) wdelegate = _delegate;
    
    void (^handleUrlCreated)(NSError *);
    handleUrlCreated = ^(NSError *error) {
        
        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            
            NSURL *errorUrl = documentURL.copy;
            [delegate fileCoordinatorDidFailCreatingFileAtURL: errorUrl
                                                    withError: error];
            
        } else {
            
            NSURL *insertedURL = documentURL.copy;
            NSArray *inserted = [[NSArray alloc] initWithObjects:insertedURL, nil];
            NSArray *removed = [[NSArray alloc] init];
            NSArray *updated = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserted
                                                           removedURLs: updated
                                                           updatedURLs: removed];
            
        }
    };
    [MADFileUtilities createFile:list atURL:documentURL completion:handleUrlCreated];
}

- (void)removeFileAtURL:(NSURL *)URL {

    typeof(_delegate) wdelegate = _delegate;
    void (^handleUrlRemoved)(NSError *error);
    handleUrlRemoved = ^(NSError *error) {
        
        id <MADFileCoordinatorDelegate> delegate = wdelegate;
        if (error) {
            [delegate fileCoordinatorDidFailRemovingFileAtURL:URL withError:error];
        } else {
            NSArray *inserted = [[NSArray alloc] init];
            NSURL *removedURL = URL.copy;
            NSArray *removedURLs = [[NSArray alloc] initWithObjects:removedURL, nil];
            NSArray *updated = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserted
                                                           removedURLs: removedURLs
                                                           updatedURLs: updated];
        }
    };
    [MADFileUtilities removeFileAtURL:URL completion:handleUrlRemoved];
}

- (void)duplicateFileAtURL:(NSURL *)URL {

    id <MADFileCoordinatorDelegate> __unsafe_unretained delegate = _delegate;
    void (^handleFileDuplicated)(NSURL *result, NSError *error);
    handleFileDuplicated = ^(NSURL *newURL, NSError *error) {
        if (error) {
            [delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
        } else {
            
            NSArray *inserted = [[NSArray alloc] initWithObjects:newURL, nil];
            NSArray *removed = [[NSArray alloc] init];
            NSArray *updated = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserted
                                                           removedURLs: removed
                                                           updatedURLs: updated];
        }
    };
    [MADFileUtilities duplicateFileAtURL:URL completion:handleFileDuplicated];
}

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {

    id <MADFileCoordinatorDelegate> __unsafe_unretained delegate = _delegate;
    void (^handleRenameCompletion)(NSURL *sourceURL, NSURL *newURL, NSError *error);
    handleRenameCompletion = ^(NSURL *sourceURL, NSURL *newURL, NSError *error) {
        
        if (error) {
            [delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
        } else {
            NSArray *inserted = [[NSArray alloc] initWithObjects: newURL, nil];
            NSArray *removed = [[NSArray alloc] initWithObjects: sourceURL, nil];
            NSArray *updated = [[NSArray alloc] init];
            [delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: inserted
                                                           removedURLs: removed
                                                           updatedURLs: updated];
        }
        
    };
    [MADFileUtilities renameFileAtURL:URL toName:name completion:handleRenameCompletion];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification {
    [_metadataQuery disableUpdates];

    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityCompleted
                                                        object: nil];
    
    NSArray *i = [MADMetaData newMetaDatumForMetadataItems:_metadataQuery.results];
    
    id inserted = [[NSArray alloc] initWithArray:i],
       removed = [[NSArray alloc] init],
       updated = [[NSArray alloc] init];

    NSMetadataQuery __weak *wmetadataQuery = _metadataQuery;
    
    void (^ __weak weakQueryUpdateHandler)(void) = _firstQueryUpdateHandler;
    
    void (^handleDidUpdateCompletion)(BOOL, NSError *);
    handleDidUpdateCompletion = ^(BOOL success, NSError *error) {
        [wmetadataQuery enableUpdates];
        void (^firstQueryUpdateHandler)(void) = weakQueryUpdateHandler;
        if (firstQueryUpdateHandler) {
            firstQueryUpdateHandler();
            //firstQueryUpdateHandler = nil;
        }
    };
    
    [_delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                    removedMetaDatum: removed
                                                    updatedMetaDatum: updated
                                                          completion: handleDidUpdateCompletion];
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedMetadataItemsOrNil, *removedMetadataItemsOrNil, *updatedMetadataItemsOrNil;
    insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey],
    removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey],
    updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    
    NSArray *insertedMetadata = insertedMetadataItemsOrNil ?: [[NSArray alloc] init],
            *removedMetadata  = removedMetadataItemsOrNil  ?: [[NSArray alloc] init],
            *updatedMetadata  = updatedMetadataItemsOrNil  ?: [[NSArray alloc] init];
    
    NSArray *inserted = [MADMetaData newMetaDatumForMetadataItems:insertedMetadata],
            *removed  = [MADMetaData newMetaDatumForMetadataItems:removedMetadata],
            *updated  = [MADMetaData newMetaDatumForMetadataItems:updatedMetadata];

    NSMetadataQuery * __weak metadataQuery = self.metadataQuery;
    void (^handleContentUpdated)(BOOL success, NSError *error);
    handleContentUpdated = ^(BOOL success, NSError *error) {
        [metadataQuery enableUpdates];
    };
    [self.delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                        removedMetaDatum: removed
                                                        updatedMetaDatum: updated
                                                              completion: handleContentUpdated];
}

- (void)handleMetadataQueryDidStartGatheringNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityStarted
                                                        object: nil];
}

- (void)handleMetadataQueryGatheringProgressNotification:(NSNotification *)notification { }

#pragma mark - Convenience

- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
                    fileGroup:(NSString *)fileGroup {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    NSString *path = documentURL.path;
    return path ? ![[NSFileManager defaultManager] fileExistsAtPath:path] : NO;
}

- (NSURL *)documentURLForName:(NSString *)name extention:(NSString *)extention
                    fileGroup:(NSString *)fileGroup {
    NSURL *documentURLWithoutExtension = [self.documentsDirectory URLByAppendingPathComponent:name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension:extention];
}

- (NSArray *)URLsByMappingMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:metadataItems.count];
    for (NSMetadataItem *metadataItem in metadataItems) {
        NSURL *URL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        [URLs addObject:URL];
    }
    
    return URLs;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end
