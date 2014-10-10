//
//  MADFileLocationManager.m
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFileLocationManager.h"
#import "MADMetaData.h"

NSString * const MADUtiType                             = @"com.everydayapps.productivity.mad";
NSString * const MADUtiPublicData                       = @"public.data";
NSString * const MADPredicateFormatDocument             = @"%K.pathExtension == %@ && %K == %@";

NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADFileLocationManager ()

@property (nonatomic, strong, readwrite) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong, readwrite) NSURL *documentsDirectory;

@property (nonatomic, strong, readwrite) NSMutableDictionary *results;

@end

@implementation MADFileLocationManager

- (void)dealloc {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver: self
                                  name: NSMetadataQueryDidFinishGatheringNotification
                                object: _metadataQuery];
    
    [notificationCenter removeObserver: self
                                  name: NSMetadataQueryDidUpdateNotification
                                object: _metadataQuery];
    
    [notificationCenter removeObserver: self
                                  name: NSMetadataQueryDidStartGatheringNotification
                                object: _metadataQuery];
    [notificationCenter removeObserver: self
                                  name: NSMetadataQueryGatheringProgressNotification
                                object: _metadataQuery];

}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    
    if (self = [super init]) {
        
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDataScope,
                                       NSMetadataQueryUbiquitousDocumentsScope];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K.pathExtension == %@ && %K == %@",
                                  NSMetadataItemURLKey, pathExtension,
                                  NSMetadataItemContentTypeKey, MADUtiType];
        metadataQuery.predicate = predicate;
        
        NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
        self.results = results;
        
        //NSMutableArray *resultsArray = [[NSMutableArray alloc] init];
        //self.resultsArray = resultsArray;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self
                               selector: @selector(handleMetadataQueryDidUpdateNotification:)
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
        
        [notificationCenter addObserver: self
                               selector: @selector(handleMetadataQueryDidFinishGatheringNotification:)
                                   name: NSMetadataQueryDidFinishGatheringNotification
                                 object: metadataQuery];

        self.metadataQuery = metadataQuery;

    }

    return self;
}

#pragma mark - MADFileLocationManager

- (BOOL)startQuery { return YES; }

- (void)stopQuery { }

#pragma mark - NSMetadataQuery Notifications

- (void)handleMetadataQueryDidStartGatheringNotification:(NSNotification *)notification {
    NSLog(@"\n%@\n", NSMetadataQueryDidStartGatheringNotification);
    
    [self.results removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityStarted
                                                        object: nil];


}

- (void)handleMetadataQueryGatheringProgressNotification:(NSNotification *)notification {
    NSLog(@"\n%@ %@\n", NSMetadataQueryGatheringProgressNotification, notification);
}

- (void)handleMetadataQueryDidFinishGatheringNotification:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityCompleted
                                                        object: nil];

    NSLog(@"\n%@\n", NSMetadataQueryDidFinishGatheringNotification);
    
    [self.metadataQuery disableUpdates];
    [self.results removeAllObjects];
    
    for (NSMetadataItem *metadataItem in self.metadataQuery.results) {
        
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        NSNumber *key = @(metadataItem.hash);
        [self.results setObject:metaData forKey:key];
    }
    
    
    NSRange range = NSMakeRange(0, self.metadataQuery.resultCount);
    NSIndexSet *inserted = [NSIndexSet indexSetWithIndexesInRange:range];
    NSIndexSet *removed = [NSIndexSet indexSet];
    NSIndexSet *updated = [NSIndexSet indexSet];
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedItems: inserted
                                                        removedItems: removed
                                                        updatedItems: updated];
    
    [self.metadataQuery enableUpdates];
}

- (NSMutableArray *)calculatedUrls {
    NSMutableArray *calculatedUrls = [[NSMutableArray alloc] initWithCapacity:self.results.count];
    for (MADMetaData *metadata in self.results) {
        [calculatedUrls addObject: metadata.url];
    }
    return calculatedUrls;
}

- (void)handleMetadataQueryDidUpdateNotification:(NSNotification *)notification {
    
    NSLog(@"\n%@\n", NSMetadataQueryDidUpdateNotification);
    
    [self.metadataQuery disableUpdates];
    
    //NSArray *updatedURLs;
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];

    //NSMutableArray *insertedURLs = [NSMutableArray arrayWithCapacity:insertedMetadataItemsOrNil.count + updatedMetadataItemsOrNil.count];
    //NSMutableArray *removedURLs = [NSMutableArray arrayWithCapacity:removedMetadataItemsOrNil.count + updatedMetadataItemsOrNil.count];

    // Handle's updating old results metadata with new metadata
    NSMutableIndexSet *updatedItems = [[NSMutableIndexSet alloc] init];
    for (NSMetadataItem *metadataItem in updatedMetadataItemsOrNil) {
        
        NSUInteger index = [self.metadataQuery.results indexOfObjectIdenticalTo:metadataItem];
        NSAssert(index!=NSNotFound, @"%s Not found.", __PRETTY_FUNCTION__);
        if (index != NSNotFound) {
            [updatedItems addIndex:index];
        }
        
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        NSNumber *key = @(metadataItem.hash);
        [self.results setObject:metaData forKey:key];
    }
    
    // Get metadata for new items
    NSMutableIndexSet *insertedItems = [[NSMutableIndexSet alloc] init];
    for (NSMetadataItem *metadataItem in insertedMetadataItemsOrNil) {
        
        NSUInteger index = [self.metadataQuery.results indexOfObjectIdenticalTo:metadataItem];
        NSAssert(index!=NSNotFound, @"%s Not found.", __PRETTY_FUNCTION__);
        if (index != NSNotFound) {
            [insertedItems addIndex:index];
        }
        
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        NSNumber *key = @(metadataItem.hash);
        [self.results setObject:metaData forKey:key];
        
    }
    
    // Remove existing meta data
    NSIndexSet *removedItems = [[NSIndexSet alloc] init];
    for (NSMetadataItem *metadataItem in removedMetadataItemsOrNil) {
        
        NSNumber *key = @(metadataItem.hash);
        [self.results removeObjectForKey:key];
        
    }
    
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedItems:insertedItems
                                                        removedItems:removedItems
                                                        updatedItems:updatedItems];
    
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
