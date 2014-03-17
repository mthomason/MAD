//
//  UIImage+Border.h
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Border)

+ (UIImage*)imageWithBorder:(UIImage *)source;
+ (UIImage*)imageWithBorder:(UIImage *)source usingColor:(UIColor *)color;

@end
