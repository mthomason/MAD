//
//  UIButton+FollowTwitter.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIButton+FollowTwitter.h"
#import "NSAttributedString+Common.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UIAccessibility.h>

@implementation UIButton (FollowTwitter)

+ (instancetype)FolllowTwitterWithTarget:(id)target action:(SEL)action {
    return [self FolllowTwitterWithTarget:target action:action size:medium];
}

+ (instancetype)FolllowTwitterWithTarget:(id)target action:(SEL)action size:(MADSizeGeneral)size {
    NSAttributedString *followOnTwitter = [NSAttributedString FollowUsOnTwitter];
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.backgroundColor = [UIColor edaBlackTwentyFivePercent];
    b.layer.cornerRadius = 5.0000f;
    b.clipsToBounds = YES;
    switch (size) {
        case small:
            b.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 66.0000f, 28.0000f);
            break;
        case medium:
            b.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 32.0000f);
            break;
        case large:
            b.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 120.0000f, 44.0000f);
            break;
        default:
            b.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 32.0000f);
            break;
    }
    b.accessibilityLabel = NSLocalizedString(@"Twitter Follow", @"Twitter Follow");
    b.accessibilityHint = NSLocalizedString(@"Follow us on Twitter.", @"Follow us on Twitter.");
    b.isAccessibilityElement = YES;
    b.accessibilityTraits = UIAccessibilityTraitButton;
    [b addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [b setAttributedTitle:followOnTwitter forState:UIControlStateNormal];
    return b;
}

@end
