//
//  MADPopoverBackgroundView.m
//  MAD
//
//  Created by Michael Thomason on 10/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADPopoverBackgroundView.h"
#import <QuartzCore/CALayer.h>

@interface MADPopoverBackgroundView ()

@property (atomic, assign) CGFloat arrowOffsetHolder;
@property (atomic, assign) CGFloat arrowDirectionHolder;

@end

@implementation MADPopoverBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        UIColor *shadowColor = [UIColor clearColor];
        self.arrowOffsetHolder = 50.0000f;
        self.arrowDirectionHolder = UIPopoverArrowDirectionAny;
        self.layer.shadowColor = shadowColor.CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = CGSizeZero.width;
        self.opaque = NO;
        
    }
    return self;
}


+ (CGFloat)arrowBase {
    return 32.0000f;
}

+ (UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsMake(5.0000f, 10.0000f, 5.0000f, 10.0000f);
}

+ (CGFloat)arrowHeight {
    return 5.0000f;
}

+ (BOOL)wantsDefaultContentAppearance {
    return YES;
}

- (CGFloat)arrowOffset {
    return self.arrowDirectionHolder;
}

- (void)setArrowOffset:(CGFloat)arrowOffset {
    self.arrowOffsetHolder = arrowOffset;
}

- (UIPopoverArrowDirection)arrowDirection {
    return self.arrowDirectionHolder;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    self.arrowDirectionHolder = arrowDirection;
}

@end
