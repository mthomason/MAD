//
//  MADPageViewAttributes.h
//  MAD Designer
//
//  Created by Michael Thomason on 2/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSCoder.h>
#import <UIKit/UIGeometry.h>
#import <CoreGraphics/CGGeometry.h>

@interface MADPageViewAttributes : NSObject
    <NSCopying, NSCoding>

@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (nonatomic, assign, readwrite) NSUInteger numberOfPages;
@property (nonatomic, assign, readwrite) CGPoint contentOffsetInital;
@property (nonatomic, assign, readwrite) CGSize contentSizeInital;
@property (nonatomic, assign, readwrite) CGFloat zoomScaleInital;
@property (nonatomic, assign, readwrite) CGFloat contentScaleFactor;
@property (nonatomic, strong) NSDate *reportLastCacheDate;

@end
