//
//  MTActivityIndicator.m
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTActivityIndicator.h"
#import "UIColor+EverydayApps.h"

@implementation MTActivityIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        UIViewAutoresizing maskView = UIViewAutoresizingFlexibleLeftMargin |
                                      UIViewAutoresizingFlexibleRightMargin |
                                      UIViewAutoresizingFlexibleTopMargin |
                                      UIViewAutoresizingFlexibleBottomMargin;
        UIViewAutoresizing maskIndicatorView = UIViewAutoresizingFlexibleLeftMargin |
                                               UIViewAutoresizingFlexibleRightMargin |
                                               UIViewAutoresizingFlexibleTopMargin;
        UIViewAutoresizing maskLabelView = UIViewAutoresizingFlexibleBottomMargin |
                                           UIViewAutoresizingFlexibleWidth;
        [self.layer setCornerRadius:5.0000f];
        UIColor *bgColor = [UIColor edaBlueLightBackground];
        [self setBackgroundColor:bgColor];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        [self setAutoresizingMask:maskView];
        [activityIndicator setAutoresizingMask:maskIndicatorView];
        
        
        [self addSubview:activityIndicator];
        CGPoint indicatorCenter = CGPointMake(self.bounds.size.width / 2.0000f, self.bounds.size.height / 2.0000f);
        activityIndicator.center = indicatorCenter;
        [activityIndicator startAnimating];
        
        CGRect labelFrame = CGRectMake(CGPointZero.x, frame.size.height - 44.0000f, frame.size.width, 44.0000f);
        UILabel *status = [[UILabel alloc] initWithFrame:labelFrame];
        [status setTextColor:[UIColor lightTextColor]];
        UIFont *font = [UIFont fontWithName:@"Helvetica-Light" size:11.0000f];
        
        [status setFont:font];
        [status setText:@"Formatting report."];
        [status setAutoresizingMask:maskLabelView];
        [status setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:status];
        [self setStatus:status];
        
    }
    return self;
}

@end
