//
//  MADViewDetailSmall.m
//  MAD
//
//  Created by Michael Thomason on 9/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerStatusLabel.h"

const CGFloat MADViewDetailSmallCornerRadius        =  3.0000f;
const CGFloat MADViewDetailSmallAnimationDuration   =  0.3333f;
const CGFloat MADAlphaHidden                        =  0.0000f;
const CGFloat MADAlphaVisible                       =  1.0000f;
const CGFloat MADViewDetailSmallAnimationDelay      =  0.6666f;

@interface MADDesignerStatusLabel ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation MADDesignerStatusLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = MADViewDetailSmallCornerRadius;
        self.backgroundColor = [UIColor edaBlackSeventyFivePercent];
        self.alpha = MADAlphaHidden;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, frame.size.width, frame.size.height)];
        label.textColor = [UIColor lightTextColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:8.0000f];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    __weak MADDesignerStatusLabel *weakself = self;
    [UIView animateWithDuration:MADViewDetailSmallAnimationDuration animations:^{
        weakself.alpha = MADAlphaVisible;
    }];
}

- (void)hide {
    __weak MADDesignerStatusLabel *weakself = self;
    [UIView animateWithDuration:MADViewDetailSmallAnimationDuration
                          delay:MADViewDetailSmallAnimationDelay
                        options:UIViewAnimationOptionCurveEaseOut animations:^{
        weakself.alpha = MADAlphaHidden;
    } completion:nil];
}

@end
