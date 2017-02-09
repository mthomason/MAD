//
//  MADReportFormatterCache.h
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportFormatterCache_h
#define MAD_MADReportFormatterCache_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@interface MADReportFormatterCache : NSObject

    - (instancetype)init;
    - (void)setLayout:(id)layout andIndexes:(id)indexes forSize:(CGSize)size;
    - (id)layoutForSize:(CGSize)size;
    - (id)indexesForSize:(CGSize)size;
    - (void)dumpCache;

@end

#endif
