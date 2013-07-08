//
//  UIImage+Border.m
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "UIImage+Border.h"

@implementation UIImage (Border)

+ (UIImage*)imageWithBorder:(UIImage *)source {
    return [UIImage imageWithBorder:source usingColor:[UIColor blackColor]];
}

+ (UIImage*)imageWithBorder:(UIImage *)source usingColor:(UIColor *)color {
    CGSize size = [source size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0000f];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextStrokeRect(context, rect);
    UIImage *result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}


@end
