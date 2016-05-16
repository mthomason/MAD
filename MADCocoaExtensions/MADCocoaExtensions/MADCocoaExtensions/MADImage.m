//
//  UIImage+Border.m
//  Reports
//
//  Created by Michael Thomason on 7/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADImage.h"
#import <UIKit/UIGraphics.h>

@implementation MADImage

+ (instancetype)imageMadeSquare:(UIImage *)source NS_RETURNS_NOT_RETAINED {
    CGSize size = CGSizeMake(MAX(source.size.width, source.size.height),
                             MAX(source.size.width, source.size.height));
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(CGPointZero.x + ((size.width - source.size.width) / 2.0000f),
                             CGPointZero.x + ((size.height - source.size.height) / 2.0000f),
                             source.size.width, source.size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0000f];
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *clearColor = [UIColor clearColor];
    CGContextSetStrokeColorWithColor(context, clearColor.CGColor);
    CGContextStrokeRectWithWidth(context, rect, 1.0000f);
    id result =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end
