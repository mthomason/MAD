//
//  MADCloudFileCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCloudFileCoordinator.h"
#import "MADFileUtilities.h"
#import "MADMetaData.h"

NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADCloudFileCoordinator ()

    @property (nonatomic, strong) NSMetadataQuery *metadataQuery;
    @property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;
    @property (nonatomic, strong) void (^firstQueryUpdateHandler)(void);

@end

@implementation MADCloudFileCoordinator

@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate identifier:(NSString *)ubiquityIdentifier firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    self = [super init];
    
    if (self) {
        
        self.firstQueryUpdateHandler = firstQueryUpdateHandler;
        
        dispatch_queue_t documentsDirectoryQueue = dispatch_queue_create("com.everydayapps.mad.cloudfilecoordinator.documentsDirectory", DISPATCH_QUEUE_SERIAL);
        self.documentsDirectoryQueue = documentsDirectoryQueue;
        
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        metadataQuery.searchScopes = @[//NSMetadataQueryUbiquitousDataScope,
                                       //NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                       NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                       NSMetadataQueryUbiquitousDocumentsScope];
        metadataQuery.notificationBatchingInterval = 0.5000;
        metadataQuery.predicate = predicate;

        [self addObserversToQuery:metadataQuery];
        self.metadataQuery = metadataQuery;
        
        dispatch_barrier_async(self.documentsDirectoryQueue, ^{
            NSURL *cloudContainerURL = [[NSFileManager defaultManager] cloudDocumentsDirectoryForUbiquityID:ubiquityIdentifier];
            _documentsDirectory = cloudContainerURL;
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
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidStartGatheringNotification object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryGatheringProgressNotification object:_metadataQuery];

}

- (instancetype)initWithPathExtension:(NSString *)pathExtension identifier:(NSString *)ubiquityIdentifier
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate identifier:ubiquityIdentifier firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) { }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent identifier:(NSString *)ubiquityIdentifier
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate identifier:ubiquityIdentifier firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) { }
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc {
    [self removeObservers];
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

- (void)createURLForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    
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
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    [self.metadataQuery disableUpdates];

    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityCompleted
                                                        object: nil];
    
    NSArray *results = [NSArray arrayWithArray:self.metadataQuery.results];
    NSArray *i = [MADMetaData madMetaDataItemsForNSMetadataItems:results];
    
    NSArray *inserted = [NSArray arrayWithArray:i];
    NSArray *removed = @[];
    NSArray *updated = @[];

    [self.delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                        removedMetaDatum: removed
                                                        updatedMetaDatum: updated
                                                              completion: ^(BOOL success, NSError *error) {
                                                                  [self.metadataQuery enableUpdates];
                                                              }];
    if (self.firstQueryUpdateHandler) {
        self.firstQueryUpdateHandler();
        self.firstQueryUpdateHandler = nil;
    }
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    
    NSArray *insertedMetadata = insertedMetadataItemsOrNil ?: @[];
    NSArray *removedMetadata = removedMetadataItemsOrNil ?: @[];
    NSArray *updatedMetadata = updatedMetadataItemsOrNil ?: @[];
    
    NSArray *inserted = [MADMetaData madMetaDataItemsForNSMetadataItems:insertedMetadata];
    NSArray *removed = [MADMetaData madMetaDataItemsForNSMetadataItems:removedMetadata];
    NSArray *updated = [MADMetaData madMetaDataItemsForNSMetadataItems:updatedMetadata];

    [self.delegate fileCoordinatorDidUpdateContentsWithInsertedMetaDatum: inserted
                                                        removedMetaDatum: removed
                                                        updatedMetaDatum: updated completion:^(BOOL success, NSError *error) {
                                                            [self.metadataQuery enableUpdates];
                                                        }];
}

- (void)handleMetadataQueryDidStartGatheringNotification:(NSNotification *)notification {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);

    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityStarted
                                                        object: nil];
}

- (void)handleMetadataQueryGatheringProgressNotification:(NSNotification *)notification {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);

}

#pragma mark - Convenience

- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

- (NSURL *)documentURLForName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
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

@end
