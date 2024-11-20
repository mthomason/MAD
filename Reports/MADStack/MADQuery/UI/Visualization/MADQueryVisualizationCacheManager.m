//
//  MADQueryVisualizationCacheManager.m
//  MAD Designer
//
//  Created by Michael on 3/8/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationCacheManager.h"

#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>

#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTPair.h>

#import "MADHierarchicalDisplayModel.h"
#import "MADQueryVisualizationModel.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADHierarchicalGroupingNodeProtocol.h"
#import "MADHierarchicalChildViewDefination.h"
#import "MADOperationArchiveData.h"
#import "MADCacheManager.h"


@interface MADQueryVisualizationCacheManager ()

    @property (readwrite, nonatomic, strong) NSURL *url;
    @property (readwrite, nonatomic, strong) MADHierarchicalDisplayModel *cacheData;

@end

@implementation MADQueryVisualizationCacheManager

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url.copy;
    }
    return self;
}

#pragma mark -
#pragma mark Cache Operations

- (void)updateCacheWithQuery:(MADModelQuery *)query contentOffset:(CGPoint)contentOffset
                   zoomScale:(CGFloat)zoomScale center:(CGPoint (^)(NSNumber *))center {
    MADQueryVisualizationModel *queryDef;
    MTLinkedList *topologicallySortedTables;
    MADHierarchicalDisplayModel *cacheData;
    
    NSNumber *tableID;
    MADHierarchicalChildViewDefination *tableModel;
    NSArray <NSNumber *> *startingPoints;

    MTVertex *tableIDVertext;
    
    queryDef= [[MADQueryVisualizationModel alloc] initWithQuery:query];
    topologicallySortedTables = queryDef.topologicallySortedTables;
    
    cacheData = [[MADHierarchicalDisplayModel alloc] initWithNumberOfTables:[topologicallySortedTables count]];
    cacheData.scrollViewContentOffset = contentOffset;
    cacheData.scrollViewZoomScale = zoomScale;
    
    for (MTPair *pair in queryDef.topologicallySortedTables) {
        
        tableIDVertext = (MTVertex *)pair.former;
        if (tableIDVertext.object != nil) {
            
            tableID = (NSNumber *)tableIDVertext.object;
            
            tableModel = [[MADHierarchicalChildViewDefination alloc] init];
            tableModel.center = center(tableID);
            
            startingPoints = queryDef.startingPoints;
            tableModel.root = [startingPoints containsObject: tableID];
            [cacheData addTableDefination:tableModel forObjectID: tableID.longLongValue];
        }
    }
    self.cacheData = cacheData;
}

- (void)archiveCache {
    MADOperationArchiveData *operation;
    operation = [[MADOperationArchiveData alloc] initWithURL: self.url
                                                   andObject: self.cacheData];
    [[MADCacheManager sharedManager] addOperation:operation];
}

- (MADHierarchicalDisplayModel *)loadCache {
    
    MADHierarchicalDisplayModel *result;
    NSError * _Nullable __autoreleasing error = nil;
    NSData *data;
    data = [[NSData alloc] initWithContentsOfURL: self.url
                                         options: NSDataReadingUncached
                                           error: &error];
    if (error != nil) {
    
        [[NSFileManager defaultManager] removeItemAtURL: self.url
                                                  error: &error];
        result = nil;

    } else {
        
        id resultFromTryBlock = nil;
        @try {
        
            resultFromTryBlock = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        } @catch (NSException *exception) {

            NSError *cleanup = nil;
            [[NSFileManager defaultManager] removeItemAtURL: self.url
                                                      error: &cleanup];
        
        } @finally {
            
            if ([resultFromTryBlock isKindOfClass:[MADHierarchicalDisplayModel class]]) {
                result = resultFromTryBlock;
            } else {
                [[NSFileManager defaultManager] removeItemAtURL:self.url error:&error];
                result = nil;
            }
            
        }
    }
    return result;
}

@end
