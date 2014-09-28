//
//  MADFileLocationManager.m
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFileLocationManager.h"

@interface MADFileLocationManager ()

@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) NSURL *documentsDirectory;

@end

@implementation MADFileLocationManager

- (void)dealloc {
    // Stop observing the query.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
}

- (instancetype)initWithPredicate:(NSPredicate *)predicate {
    self = [super init];
    
    if (self) {
    
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope, NSMetadataQueryUbiquitousDataScope];
        metadataQuery.predicate = predicate;
        
        // Observe the query.
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self
                               selector: @selector(metadataQueryDidFinishGathering:)
                                   name: NSMetadataQueryDidFinishGatheringNotification
                                 object: metadataQuery];
        [notificationCenter addObserver: self
                               selector: @selector(metadataQueryDidUpdate:)
                                   name: NSMetadataQueryDidUpdateNotification
                                 object: metadataQuery];
        self.metadataQuery = metadataQuery;
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - MADFileLocationManager

- (void)startQuery {
    [self.metadataQuery startQuery];
}

- (void)stopQuery {
    [self.metadataQuery stopQuery];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSMutableArray *insertedURLs = [NSMutableArray arrayWithCapacity:self.metadataQuery.results.count];
    for (NSMetadataItem *metadataItem in self.metadataQuery.results) {
        NSURL *insertedURL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [insertedURLs addObject:insertedURL];
    }
    
    NSArray *removedUrls = @[];
    NSArray *updatedUrls = @[];
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs: insertedURLs
                                                        removedURLs: removedUrls
                                                        updatedURLs: updatedUrls];
    
    [self.metadataQuery enableUpdates];
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedURLs;
    NSArray *removedURLs;
    NSArray *updatedURLs;
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    if (insertedMetadataItemsOrNil) {
        insertedURLs = [self URLsByMappingMetadataItems:insertedMetadataItemsOrNil];
    }
    
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    if (removedMetadataItemsOrNil) {
        removedURLs = [self URLsByMappingMetadataItems:removedMetadataItemsOrNil];
    }
    
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    if (updatedMetadataItemsOrNil) {
        NSIndexSet *indexesOfCompletelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil indexesOfObjectsPassingTest:^BOOL(NSMetadataItem *updatedMetadataItem, NSUInteger idx, BOOL *stop) {
            NSString *downloadStatus = [updatedMetadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
            
            return [downloadStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent];
        }];
        
        NSArray *completelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil objectsAtIndexes:indexesOfCompletelyDownloadedUpdatedMetadataItems];
        
        updatedURLs = [self URLsByMappingMetadataItems:completelyDownloadedUpdatedMetadataItems];
    }
    
    // Make sure that the arrays are all initialized before calling the didUpdateContents method.
    insertedURLs = insertedURLs ?: @[];
    removedURLs = removedURLs ?: @[];
    updatedURLs = updatedURLs ?: @[];
    
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];
    
    [self.metadataQuery enableUpdates];
}

#pragma mark - Convenience

- (NSArray *)URLsByMappingMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:metadataItems.count];
    
    for (NSMetadataItem *metadataItem in metadataItems) {
        NSURL *URL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [URLs addObject:URL];
    }
    
    return URLs;
}

@end
