//
//  MTActivityIndicator.m
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTActivityIndicator.h"
#import <MADCocoaExtensions/MADColor.h>

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
        self.layer.cornerRadius = 5.0000f;
        UIColor *bgColor = [MADColor edaBlueLightBackground];
        self.backgroundColor = bgColor;
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        self.autoresizingMask = maskView;
        activityIndicator.autoresizingMask = maskIndicatorView;
        
        
        [self addSubview:activityIndicator];
        CGPoint indicatorCenter = CGPointMake(self.bounds.size.width / 2.0000f,
                                              self.bounds.size.height / 2.0000f);
        activityIndicator.center = indicatorCenter;
        [activityIndicator startAnimating];
        
        CGRect labelFrame = CGRectMake(CGPointZero.x,
                                       frame.size.height - 44.0000f,
                                       frame.size.width,
                                       44.0000f);
        UILabel *status = [[UILabel alloc] initWithFrame:labelFrame];
        [status setTextColor:[UIColor lightTextColor]];
        UIFont *font = [UIFont fontWithName: @"Helvetica-Light"
                                       size: 11.0000f];
        
        status.font = font;
        status.text = @"Formatting report.";
        status.autoresizingMask = maskLabelView;
        status.textAlignment = NSTextAlignmentCenter;
        [self addSubview:status];
        self.status = status;
        
    }
    return self;
}

@end
