//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryVisualizationCacheData_h
#define MAD_MADQueryVisualizationCacheData_h

#import <CoreData/CoreData.h>
#import <CoreGraphics/CGGeometry.h>

@class MADQueryVisualizationTableDefination;
@class MADOperation;

@interface MADQueryVisualizationCacheData : NSObject
    <NSCoding>

    @property (nonatomic, strong) MADQueryVisualizationCacheData *cacheData;
    @property (nonatomic, strong) MADOperation *operationQueueCache;

    @property (nonatomic, assign) CGPoint scrollViewContentOffset;
    @property (nonatomic, assign) CGFloat scrollViewZoomScale;

    - (instancetype)initWithNumberOfTables:(NSUInteger)countTables;
    - (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDefination forObjectID:(NSManagedObjectID *)objectID;
    - (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID;
    - (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID;

    + (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end

#endif
