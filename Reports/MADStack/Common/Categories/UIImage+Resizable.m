//
//  UIImage+Resizable.m
//  Reports
//
//  Created by Michael Thomason on 1/3/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIImage+Resizable.h"

@implementation UIImage (Resizable)

- (UIImage *)resizableImage {
    CGSize imageSize = [self size];
    CGFloat leftAndRight = (imageSize.width / 2.0000f) - 2.0000f;
    CGFloat topAndBottom = (imageSize.height / 2.0000f) - 2.0000f;
    UIEdgeInsets imageEdgeInsets = UIEdgeInsetsMake(topAndBottom, leftAndRight, topAndBottom, leftAndRight);
    return [self resizableImageWithCapInsets:imageEdgeInsets];
}

@end
