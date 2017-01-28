//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryVisualizationCacheData_h
#define MAD_MADQueryVisualizationCacheData_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADHierarchicalChildViewDefination;
@class MADOperation;
@class NSManagedObjectID;

@interface MADHierarchicalDisplayModel : NSObject
    <NSCoding>

    @property (nonatomic, assign) CGPoint scrollViewContentOffset;
    @property (nonatomic, assign) CGFloat scrollViewZoomScale;

    - (instancetype)initWithNumberOfTables:(NSUInteger)countTables;

    - (void)addTableDefination:(MADHierarchicalChildViewDefination *)tableDefination
                   forObjectID:(NSManagedObjectID *)objectID;

    - (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID;

    - (MADHierarchicalChildViewDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID;

    + (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end

#endif
