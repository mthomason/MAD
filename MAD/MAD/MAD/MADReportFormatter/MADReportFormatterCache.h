//
//  MADReportFormatterCache.h
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
