//
//  UIImage+Border.h
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIImage_Border_h
#define Reports_UIImage_Border_h

#import <UIKit/UIKit.h>

@interface MADImage : UIImage

+ (instancetype)imageWithBorder:(UIImage *)source NS_RETURNS_NOT_RETAINED;
+ (instancetype)imageWithBorder:(UIImage *)source usingColor:(UIColor *)color NS_RETURNS_NOT_RETAINED;
+ (instancetype)imageMadeSquare:(UIImage *)source NS_RETURNS_NOT_RETAINED;

@end

#endif
