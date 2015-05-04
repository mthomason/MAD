//
//  MADFileLocationManager.m
//  MAD
//
//  Created by Michael Thomason on 9/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADMetadataQueryManager.h"
#import "MADMetaData.h"

NSString * const MADKeyDisplayNameShort                 = @"d";
NSString * const MADKeyPathShort                        = @"p";
NSString * const MADKeyMetadataShort                    = @"m";

NSString * const MADUtiType                             = @"com.everydayapps.productivity.mad";
NSString * const MADUtiPublicData                       = @"public.data";
NSString * const MADPredicateFormatDocument             = @"%K.pathExtension == %@ && %K == %@";

NSString * const MADNotificationCloudActivityStarted    = @"MADNotificationCloudActivityStarted";
NSString * const MADNotificationCloudActivityCompleted  = @"MADNotificationCloudActivityCompleted";

@interface MADMetadataQueryManager ()

@property (nonatomic, strong, readwrite) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong, readwrite) NSURL *documentsDirectory;

@property (nonatomic, strong, readwrite) NSMutableDictionary *results;

@property (nonatomic, strong, readwrite) NSArray *metadata;

@end

@implementation MADMetadataQueryManager

#pragma mark - Static Functions

+ (NSString *)keyDisplayName {
    return NSStringFromSelector(@selector(displayName));
}

+ (NSString *)keyResults {
    return NSStringFromSelector(@selector(results));
}

#pragma mark - NSObject

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(metadataQuery)), self.metadataQuery];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(documentsDirectory)), self.documentsDirectory.path];
    [debuggingString appendFormat:@"%@:\t%@\n", [MADMetadataQueryManager keyResults], self.results];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(metadata)), self.metadata];
    
    return debuggingString;
}

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
    
    NSString *keyResults = [MADMetadataQueryManager keyResults];
    [_metadataQuery removeObserver:self forKeyPath:keyResults];

}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    
    if (self = [super init]) {
        
        NSArray *metadata = @[];
        self.metadata = metadata;
        
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: @"kMDItemDisplayName"//NSMetadataItemFSNameKey
                                                               ascending: NO];
        NSArray *sorts = [NSArray arrayWithObject:sort];
        metadataQuery.sortDescriptors = sorts;

        metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDataScope,
                                       NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope,
                                       NSMetadataQueryUbiquitousDocumentsScope];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                                  NSMetadataItemContentTypeKey, MADUtiType];
        metadataQuery.predicate = predicate;
        metadataQuery.notificationBatchingInterval = 0.5000;

        NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
        self.results = results;
        
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
        NSString *keyResults = [MADMetadataQueryManager keyResults];
        [self.metadataQuery addObserver:self
                             forKeyPath:keyResults
                                options:(NSKeyValueObservingOptionNew |
                                         NSKeyValueObservingOptionOld |
                                         NSKeyValueObservingOptionPrior)
                                context:NULL];

    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    NSKeyValueChange changeType = ((NSNumber *)change[NSKeyValueChangeKindKey]).unsignedIntegerValue;
    NSArray *changeValueNew = change[NSKeyValueChangeNewKey];
    NSArray *changeValueOld = change[NSKeyValueChangeOldKey];
    NSIndexSet *changeIndexes = change[NSKeyValueChangeIndexesKey];
    BOOL changePrior = ((NSNumber *)change[NSKeyValueChangeNotificationIsPriorKey]).boolValue;

    switch (changeType) {
        case NSKeyValueChangeInsertion:
            break;
        case NSKeyValueChangeRemoval:
            break;
        case NSKeyValueChangeReplacement:
            break;
        case NSKeyValueChangeSetting:
            break;
        default:
            break;
    }
}

#pragma mark - MADFileLocationManager

- (BOOL)startQuery {
    BOOL success = YES;
    [self.metadataQuery enableUpdates];
    if (self.metadataQuery.started == NO) {
        success = [self.metadataQuery startQuery];
        NSAssert(success, @"%s\n\tFailed to start query.", __PRETTY_FUNCTION__);
    }
    return success;
}

- (void)stopQuery { }

#pragma mark - NSMetadataQuery Notifications

+ (NSSortDescriptor *)sortDisplayName {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: MADKeyDisplayNameShort
                                                                   ascending: YES
                                                                    selector: @selector(caseInsensitiveCompare:)];
    return sortDescriptor;
}

- (void)handleMetadataQueryDidStartGatheringNotification:(NSNotification *)notification {
    //NSMetadataQuery *query = notification.object;
    //NSLog(@"\n%@\n\t%@\nnumberResults%d", NSMetadataQueryDidStartGatheringNotification, query, query.resultCount);
    [self.results removeAllObjects];
    
    NSArray *metadata = @[];
    self.metadata = metadata;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityStarted
                                                        object: nil];


}

- (void)handleMetadataQueryGatheringProgressNotification:(NSNotification *)notification {
    //NSMetadataQuery *query = notification.object;
    //NSLog(@"\n%@\n\t%@\nnumberResults%d", NSMetadataQueryGatheringProgressNotification, query, query.resultCount);
}

- (void)handleMetadataQueryDidFinishGatheringNotification:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationCloudActivityCompleted
                                                        object: nil];
    
    [self.metadataQuery disableUpdates];
    [self.results removeAllObjects];
    
    NSArray *metadata = @[];
    
    
    self.metadata = metadata;
    
    for (NSMetadataItem *metadataItem in self.metadataQuery.results) {
        MADMetaData *metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        NSNumber *key = @(metadataItem.hash);
        [self.results setObject:metaData forKey:key];
    }
    
    NSUInteger i = 0;
    NSMetadataItem *metadataItem;
    MADMetaData *metaData;
    NSDictionary *metaDataDictionary;
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:self.metadataQuery.resultCount];
    for (i=0; i<self.metadataQuery.resultCount; i++) {
        metadataItem = [self.metadataQuery resultAtIndex:i];
        metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        metaDataDictionary = @{
                               MADKeyDisplayNameShort : metaData.displayName,
                               MADKeyMetadataShort : metaData,
                               MADKeyPathShort : metaData.path
                               };
        [results addObject:metaDataDictionary];
    }
    
    NSSortDescriptor *sortFileName = [MADMetadataQueryManager sortDisplayName];
    NSArray *sortDescriptors = @[sortFileName];
    NSArray *resultsSorted = [results sortedArrayUsingDescriptors:sortDescriptors];
    self.metadata = resultsSorted;
    
    NSRange range = NSMakeRange(0, self.metadataQuery.resultCount);
    NSIndexSet *inserted = [NSIndexSet indexSetWithIndexesInRange:range],
               *removed  = [NSIndexSet indexSet],
               *updated  = [NSIndexSet indexSet];
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedItems: inserted
                                                        removedItems: removed
                                                        updatedItems: updated];
    
    [self.metadataQuery enableUpdates];

}

- (void)handleMetadataQueryDidUpdateNotification:(NSNotification *)notification {
    
    [self.metadataQuery disableUpdates];

    NSMutableArray *metadataResults = [[NSMutableArray alloc] initWithCapacity:self.metadataQuery.resultCount];
    NSMetadataItem *metadataItem;
    MADMetaData *metaData;
    for (NSUInteger i=0; i<self.metadataQuery.resultCount; i++) {
        metadataItem = [self.metadataQuery resultAtIndex:i];
        metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        if (metaData) {
            NSDictionary *newItem = @{
                                      MADKeyDisplayNameShort : metaData.displayName,
                                      MADKeyMetadataShort : metaData,
                                      MADKeyPathShort : metaData.path
                                      };
            [metadataResults addObject:newItem];
        }
    }
    NSSortDescriptor *sortFileName = [MADMetadataQueryManager sortDisplayName];
    NSArray *sortDescriptors = @[sortFileName];
    NSArray *resultsSorted = [metadataResults sortedArrayUsingDescriptors:sortDescriptors];
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];

    // Handle's updating old results metadata with new metadata
    NSMutableIndexSet *updatedItems = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *removedItems = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *insertedItems = [[NSMutableIndexSet alloc] init];

    NSPredicate *findObjectByPath;
    NSUInteger indexOfMetadata;
    
    for (NSMetadataItem *metadataItem in updatedMetadataItemsOrNil) {

        metaData = [[MADMetaData alloc] initWithMetadataItem:metadataItem];
        if (metaData) {
            findObjectByPath = [NSPredicate predicateWithFormat:@"(%@ == %@)", MADKeyPathShort, metaData.path];
            
            indexOfMetadata = [resultsSorted indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [obj[MADKeyPathShort] isEqualToString:metaData.path];
            }];
            
            if (indexOfMetadata != NSNotFound) {
                [updatedItems addIndex:indexOfMetadata];
            }
            
            NSNumber *key = @(metadataItem.hash);
            [self.results setObject:metaData forKey:key];
        }
    }
    
    // Remove existing meta data
    NSUInteger indexRemoved;
    for (NSMetadataItem *metadataItem in removedMetadataItemsOrNil) {
        NSString *path = [metadataItem valueForAttribute:NSMetadataItemPathKey];
        indexRemoved = [self.metadata indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj[MADKeyPathShort] isEqualToString:path];
        }];
        if (indexRemoved != NSNotFound) {
            [removedItems addIndex:indexRemoved];
        }
        
        NSNumber *key = @(metadataItem.hash);
        [self.results removeObjectForKey:key];
        
    }
    

    NSUInteger indexAdded;
    for (NSMetadataItem *metadataItem in insertedMetadataItemsOrNil) {
        NSString *path = [metadataItem valueForAttribute:NSMetadataItemPathKey];
        indexAdded = [resultsSorted indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj[MADKeyPathShort] isEqualToString:path];
        }];
        if (indexAdded != NSNotFound) {
            [insertedItems addIndex:indexAdded];
        }
    }

    self.metadata = resultsSorted;
    
    
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedItems:insertedItems
                                                        removedItems:removedItems
                                                        updatedItems:updatedItems];
    
    [self.metadataQuery enableUpdates];
}

@end
