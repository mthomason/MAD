//
//  MTReportFormatterCache.h
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatterCache_h
#define MAD_MTReportFormatterCache_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@interface MTReportFormatterCache : NSObject

- (instancetype)init;
- (void)setLayout:(id)layout andIndexes:(id)indexes forSize:(CGSize)size;
- (id)layoutForSize:(CGSize)size;
- (id)indexesForSize:(CGSize)size;
- (void)dumpCache;

@end

#endif
