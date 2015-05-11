//
//  MADPopoverBackgroundView.m
//  MAD
//
//  Created by Michael Thomason on 10/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADPopoverBackgroundView.h"

@interface MADPopoverBackgroundView ()

@property (atomic, assign) CGFloat arrowOffsetHolder;
@property (atomic, assign) CGFloat arrowDirectionHolder;

@end

@implementation MADPopoverBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.arrowOffsetHolder = 50.0000f;
        self.arrowDirectionHolder = UIPopoverArrowDirectionAny;
        //self.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2000f];
        //self.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.layer.shadowColor = [UIColor clearColor].CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = CGSizeZero.width;
        //self.layer.borderColor = [UIColor greenColor].CGColor;
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
