//
//  UIImage+Border.m
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIImage+Border.h"
#import "UIDevice+Hack.h"

@implementation UIImage (Border)

+ (UIImage *)imageWithBorder:(UIImage *)source {
    return [UIImage imageWithBorder:source usingColor:[UIColor blackColor]];
}

+ (UIImage *)imageWithBorder:(UIImage *)source usingColor:(UIColor *)color {
    CGSize size = [source size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0000f];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    if ([UIDevice isRetnaDisplay]) {
        CGContextStrokeRectWithWidth(context, rect, 0.5000f);
    } else {
        CGContextStrokeRectWithWidth(context, rect, 1.0000f);
    }
    UIImage *result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}


@end
