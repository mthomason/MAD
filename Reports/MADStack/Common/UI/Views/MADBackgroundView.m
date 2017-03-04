//
//  MADBackgroundView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundView.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <QuartzCore/CALayer.h>

@implementation MADBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *bgColor = [[MADColorEverydayApps newColorBlackFiftyPercent] colorWithAlphaComponent:0.33333333f];
        self.backgroundColor = bgColor;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5.0000f;
    }
    return self;
}

@end
