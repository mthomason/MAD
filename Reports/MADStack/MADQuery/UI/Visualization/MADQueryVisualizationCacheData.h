//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreGraphics/CGGeometry.h>

@class MADQueryVisualizationTableDefination;

@interface MADQueryVisualizationCacheData : NSObject
    <NSCoding>

    @property (nonatomic, strong) MADQueryVisualizationCacheData *cacheData;
    @property (nonatomic, strong) NSOperationQueue *operationQueueCache;

    @property (nonatomic, assign) CGPoint scrollViewContentOffset;
    @property (nonatomic, assign) CGFloat scrollViewZoomScale;

    @property (nonatomic, strong, readonly) NSMutableDictionary *tableDefinations;

    - (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDefination forObjectID:(NSManagedObjectID *)objectID;
    - (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID;

    + (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end
