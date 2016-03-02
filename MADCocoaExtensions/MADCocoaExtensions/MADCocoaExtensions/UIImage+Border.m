//
//  UIImage+Border.m
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIImage+Border.h"
#import "UIDevice+Hack.h"

@implementation MADImage

+ (instancetype)imageWithBorder:(UIImage *)source NS_RETURNS_NOT_RETAINED {
    return [MADImage imageWithBorder:source usingColor:[UIColor blackColor]];
}

+ (instancetype)imageWithBorder:(UIImage *)source usingColor:(UIColor *)color NS_RETURNS_NOT_RETAINED {
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
    id result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (instancetype)imageMadeSquare:(UIImage *)source NS_RETURNS_NOT_RETAINED {
    CGSize size = CGSizeMake(MAX(source.size.width, source.size.height),
                             MAX(source.size.width, source.size.height));
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(CGPointZero.x + ((size.width - source.size.width) / 2.0000f),
                             CGPointZero.x + ((size.height - source.size.height) / 2.0000f),
                             source.size.width, source.size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0000f];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextStrokeRectWithWidth(context, rect, 1.0000f);
    id result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end

