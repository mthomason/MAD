//
//  MADPageViewAttributes.h
//  MAD Designer
//
//  Created by Michael Thomason on 2/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADPageViewAttributes_h
#define Reports_MADPageViewAttributes_h

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@interface MADPageViewAttributes : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (nonatomic, assign, readwrite) NSUInteger numberOfPages;
@property (nonatomic, assign, readwrite) CGPoint contentOffsetInital;
@property (nonatomic, assign, readwrite) CGSize contentSizeInital;
@property (nonatomic, assign, readwrite) double zoomScaleInital;
@property (nonatomic, assign, readwrite) double contentScaleFactor;
@property (nonatomic, copy) NSDate *reportLastCacheDate;

- (instancetype)initWithPosition:(MADReportPosition)position
							size:(CGSize)size;
- (instancetype)initWithCurrentPage:(NSUInteger)currentPageNumber
							  total:(NSUInteger)numberOfPages
							   size:(CGSize)size;

@end

#endif
