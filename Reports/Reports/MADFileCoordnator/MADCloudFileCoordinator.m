//
//  MADCloudListCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCloudFileCoordinator.h"
#import "MADFileUtilities.h"
#import "MADConstants.h"
#import "MTApplicationInstance.h"
#import "NSFileManager+Common.h"
#import "MADMetaData.h"

NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADCloudFileCoordinator ()

@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;

/// Closure executed after the first update provided by the coordinator regarding tracked URLs.
@property (nonatomic, strong) void (^firstQueryUpdateHandler)(void);

@end

@implementation MADCloudFileCoordinator
@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate
          firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    self = [super init];
    
    if (self) {
        
        _firstQueryUpdateHandler = firstQueryUpdateHandler;
        _documentsDirectoryQueue = dispatch_queue_create("com.everydayapps.mad.cloudfilecoordinator.documentsDirectory", DISPATCH_QUEUE_SERIAL);
        
        _metadataQuery = [[NSMetadataQuery alloc] init];
        _metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDataScope,
                                        NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                        NSMetadataQueryUbiquitousDocumentsScope/*NSMetadataQueryUbiquitousDocumentsScope,
                                        NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope*/];
        _metadataQuery.notificationBatchingInterval = 0.5000;
        _metadataQuery.predicate = predicate;
        _metadataQuery.operationQueue = [[NSOperationQueue alloc] init];
        _metadataQuery.operationQueue.name = @"com.everydayapps.mad.cloudfilecoordinator.metadataQuery";
        
        dispatch_barrier_async(_documentsDirectoryQueue, ^{
            NSURL *cloudContainerURL = [[NSFileManager defaultManager] cloudDocumentsDirectoryForUbiquityID:MADUbiquityIdentifier];
            _documentsDirectory = cloudContainerURL;
        });
        
        // Observe the query.
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
        
        [notificationCenter addObserver: self
                               selector: @selector(handleMetadataQueryDidStartGatheringNotification:)
                                   name: NSMetadataQueryDidStartGatheringNotification
                                 object: _metadataQuery];
        
        [notificationCenter addObserver: self
                               selector: @selector(handleMetadataQueryGatheringProgressNotification:)
                                   name: NSMetadataQueryGatheringProgressNotification
                                 object: _metadataQuery];
        
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc {
    // Stop observing the query.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:self.metadataQuery];
}

#pragma mark - Property Overrides

- (NSURL *)documentsDirectory {
    __block NSURL *documentsDirectory;
    
    dispatch_sync(self.documentsDirectoryQueue, ^{
        documentsDirectory = _documentsDirectory;
    });
    
    return documentsDirectory;
}

#pragma mark - MADFileCoordinator

- (void)startQuery {
    // \c NSMetadataQuery should always be started on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.metadataQuery startQuery];
    });
}

- (void)stopQuery {
    // \c NSMetadataQuery should always be stopped on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.metadataQuery stopQuery];
    });
}

- (void)createURLForFile:(MADFile *)list withName:(NSString *)name {
    NSURL *documentURL = [self documentURLForName:name];
    
    [MADFileUtilities createFile:list atURL:documentURL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailCreatingFileAtURL:documentURL withError:error];
        }
        else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[documentURL]
                                                                removedURLs:@[]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)removeFileAtURL:(NSURL *)URL {
    [MADFileUtilities removeFileAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailRemovingFileAtURL:URL withError:error];
        }
        else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[]
                                                                removedURLs:@[URL]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)duplicateFileAtURL:(NSURL *)URL {
    [MADFileUtilities duplicateFileAtURL:URL withCompletionHandler:^(NSURL *newURL, NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
        } else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[newURL]
                                                                removedURLs:@[]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {
    [MADFileUtilities renameFileAtURL:URL toName:name withCompletionHandler:^(NSURL *sourceURL, NSURL *newURL, NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
        } else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[newURL]
                                                                removedURLs:@[sourceURL]
                                                                updatedURLs:@[]];
        }
    }];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityCompleted
                                                        object: nil];

    [self.metadataQuery disableUpdates];
    
    NSArray *inserted = [MADMetaData madMetaDataItemsForNSMetadataItems:self.metadataQuery.results];
    NSArray *removed = @[];
    NSArray *updated = @[];

    [self.delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                        removedMetaDatum: removed
                                                        updatedMetaDatum: updated
                                                              completion: ^(BOOL success, NSError *error) {
                                                        }];
    
    [self.metadataQuery enableUpdates];
    
    if (self.firstQueryUpdateHandler) {
        // Execute the `firstQueryUpdateHandler`, it will contain the closure from initialization on first update.
        self.firstQueryUpdateHandler();
        
        // Set `firstQueryUpdateHandler` to an empty closure so that the handler provided is only run on first update.
        self.firstQueryUpdateHandler = nil;
    }


}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    
    // Make sure that the arrays are all initialized before calling the didUpdateContents method.
    NSArray *insertedMetadata = insertedMetadataItemsOrNil ?: @[];
    NSArray *removedMetadata = removedMetadataItemsOrNil ?: @[];
    NSArray *updatedMetadata = updatedMetadataItemsOrNil ?: @[];
    
    NSArray *inserted = [MADMetaData madMetaDataItemsForNSMetadataItems:insertedMetadata];
    NSArray *removed = [MADMetaData madMetaDataItemsForNSMetadataItems:removedMetadata];
    NSArray *updated = [MADMetaData madMetaDataItemsForNSMetadataItems:updatedMetadata];
    for (MADMetaData *insert in inserted) {
        NSLog(@"Inserted %@", insert);
    }
    for (MADMetaData *r in removed) {
        NSLog(@"Removed %@", r);
    }
    for (MADMetaData *u in updated) {
        NSLog(@"Updated %@", u);
    }
    [self.delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                        removedMetaDatum: removed
                                                        updatedMetaDatum: updated completion:^(BOOL success, NSError *error) {
                                                            
                                                            
                                                        }];
    
    [self.metadataQuery enableUpdates];
    
}

- (void)handleMetadataQueryDidStartGatheringNotification:(NSNotification *)notification {
    //NSMetadataQuery *query = notification.object;
    //NSLog(@"\n%@\n\t%@\nnumberResults%d", NSMetadataQueryDidStartGatheringNotification, query, query.resultCount);
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityStarted
                                                        object: nil];
    
    
}

- (void)handleMetadataQueryGatheringProgressNotification:(NSNotification *)notification {
    //NSMetadataQuery *query = notification.object;
    //NSLog(@"\n%@\n\t%@\nnumberResults%d", NSMetadataQueryGatheringProgressNotification, query, query.resultCount);
}

#pragma mark - Convenience

- (BOOL)canCreateFileWithName:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

- (NSURL *)documentURLForName:(NSString *)name {
    NSURL *documentURLWithoutExtension = [self.documentsDirectory URLByAppendingPathComponent:name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
}

- (NSArray *)URLsByMappingMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:metadataItems.count];
    
    for (NSMetadataItem *metadataItem in metadataItems) {
        NSURL *URL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [URLs addObject:URL];
    }
    
    return URLs;
}

@end
