//
//  MADViewDetailSmall.m
//  MAD
//
//  Created by Michael Thomason on 9/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerStatusLabel.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <UIKit/UILabel.h>
#import <QuartzCore/CALayer.h>

const CGFloat MADViewDetailSmallCornerRadius        =  3.0000f;
const CGFloat MADViewDetailSmallAnimationDuration   =  0.3333f;
const CGFloat MADAlphaHidden                        =  0.0000f;
const CGFloat MADAlphaVisible                       =  1.0000f;
const CGFloat MADViewDetailSmallAnimationDelay      =  0.6666f;

@interface MADDesignerStatusLabel ()

@property (nonatomic, weak) UILabel *label;

@end

@implementation MADDesignerStatusLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = MADViewDetailSmallCornerRadius;
        self.backgroundColor = [MADColorEverydayApps newColorBlackSeventyFivePercent];
        self.alpha = MADAlphaHidden;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, frame.size.width, frame.size.height)];
        label.textColor = [UIColor lightTextColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:8.0000f];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = MADViewAutoresizingFlexable();
        label.translatesAutoresizingMaskIntoConstraints = YES;
        [self addSubview:label];
        self.label = label;

    }
    return self;
}

- (void)setText:(NSString *)text {
    self.label.text = text;
}

- (void)show {
    [UIView animateWithDuration:MADViewDetailSmallAnimationDuration animations:^{
        self.alpha = MADAlphaVisible;
    }];
}

- (void)hide {
    [UIView animateWithDuration:MADViewDetailSmallAnimationDuration
                          delay:MADViewDetailSmallAnimationDelay
                        options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = MADAlphaHidden;
    } completion:nil];
}

- (BOOL)isAccessibilityElement {
    return NO;
}

@end
