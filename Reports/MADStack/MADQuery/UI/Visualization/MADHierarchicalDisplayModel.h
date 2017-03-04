//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryVisualizationCacheData_h
#define MAD_MADQueryVisualizationCacheData_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADHierarchicalChildViewDefination, MADOperation, NSManagedObjectID;

@interface MADHierarchicalDisplayModel : NSObject
    <NSCoding>

    @property (nonatomic, assign) CGPoint scrollViewContentOffset;
    @property (nonatomic, assign) CGFloat scrollViewZoomScale;

    - (instancetype)initWithNumberOfTables:(NSUInteger)countTables;

    - (void)addTableDefination:(MADHierarchicalChildViewDefination *)tableDefination
                   forObjectID:(int64_t)objectID;

    - (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID;

    - (MADHierarchicalChildViewDefination *)tableDefinationForObjectID:(int64_t)objectID;

    + (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end

#endif
