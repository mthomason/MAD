//
//  MADQueryVisualizationCacheManager.h
//  MAD Designer
//
//  Created by Michael on 3/8/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADQueryVisualizationCacheManager_h
#define MAD_MADQueryVisualizationCacheManager_h

#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGGeometry.h>
#import <Foundation/NSObject.h>

@class MADModelQuery, MADHierarchicalDisplayModel;

@interface MADQueryVisualizationCacheManager : NSObject

    @property (readonly, nonatomic, strong) MADHierarchicalDisplayModel *cacheData;

    - (instancetype)initWithURL:(NSURL *)url;

    - (void)updateCacheWithQuery:(MADModelQuery *)query
                   contentOffset:(CGPoint)contentOffset
                       zoomScale:(CGFloat)zoomScale
                          center:(CGPoint (^)(NSNumber *))center;
    - (void)archiveCache;
    - (MADHierarchicalDisplayModel *)loadCache;

@end

#endif
