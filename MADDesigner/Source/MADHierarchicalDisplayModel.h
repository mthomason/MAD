//
//  MADQueryVisualizationCacheData.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADQueryVisualizationCacheData_h
#define MAD_MADQueryVisualizationCacheData_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADHierarchicalChildViewDefination, MADOperation;

@interface MADHierarchicalDisplayModel : NSObject <NSSecureCoding>

@property (nonatomic, assign) CGPoint scrollViewContentOffset;
@property (nonatomic, assign) CGFloat scrollViewZoomScale;

- (instancetype)initWithNumberOfTables:(NSUInteger)countTables;
- (void)addTableDefination:(MADHierarchicalChildViewDefination *)tableDefination forObjectID:(int64_t)objectID;
- (void)removeTableDefinationForObjectID:(int64_t)objectID;
- (MADHierarchicalChildViewDefination *)tableDefinationForObjectID:(int64_t)objectID;
+ (NSString *)cacheFileNameForFileName:(NSString *)filename;

@end

#endif
