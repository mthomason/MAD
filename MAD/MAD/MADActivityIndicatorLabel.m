//
//  MADActivityIndicatorLabel.m
//  MAD
//
//  Created by Michael on 1/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADActivityIndicatorLabel.h"

@implementation MADActivityIndicatorLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame: frame]) {

        UIFont *font = [UIFont fontWithName: @"Helvetica-Light" size: 11.0000f];
        UIViewAutoresizing maskLabelView = UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleWidth;

        self.font = font;
        self.textColor = [UIColor lightTextColor];
        self.text = NSLocalizedString(@"Formatting report.", @"Formatting report.");
        self.autoresizingMask = maskLabelView;
        self.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

@end
