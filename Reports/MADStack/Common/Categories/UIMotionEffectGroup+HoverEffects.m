//
//  UIMotionEffect+HoverEffects.m
//  MAD Designer
//
//  Created by Michael Thomason on 7/2/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "UIMotionEffectGroup+HoverEffects.h"

@implementation UIMotionEffectGroup (HoverEffects)

+ (UIMotionEffectGroup *)HoverEffects {
    
    NSNumber *maximumRelativeValue = @(13.0000f);
    NSNumber *minimumRelativeValue = @(-13.0000f);
    NSNumber *maxHeight = @(16);
    NSNumber *minHeight = @(-3);

    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    UIInterpolatingMotionEffect *shadowOffsetHeight = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset.height" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    UIInterpolatingMotionEffect *shadowOffsetWidth = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset.width" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];

    shadowOffsetHeight.minimumRelativeValue = minHeight;
    shadowOffsetHeight.maximumRelativeValue = maxHeight;
    shadowOffsetWidth.minimumRelativeValue = maximumRelativeValue;
    shadowOffsetWidth.maximumRelativeValue = minimumRelativeValue;
    
    xAxis.maximumRelativeValue = maximumRelativeValue;
    xAxis.minimumRelativeValue = minimumRelativeValue;

    yAxis.maximumRelativeValue = maximumRelativeValue;
    yAxis.minimumRelativeValue = minimumRelativeValue;
    
    UIMotionEffectGroup *motionGroup = [[UIMotionEffectGroup alloc] init];
    NSArray *motionEffects = @[xAxis, yAxis, shadowOffsetHeight, shadowOffsetWidth];
    motionGroup.motionEffects = motionEffects;
    return motionGroup;
}

@end
