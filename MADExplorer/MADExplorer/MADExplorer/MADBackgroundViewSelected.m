//
//  MADBackgroundViewSelected.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBackgroundViewSelected.h"
#import <QuartzCore/CALayer.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADBackgroundViewSelected

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *colorTextNormal = [MADColorEverydayApps newColorBlue];
        UIColor *bgColor = [colorTextNormal colorWithAlphaComponent:0.70000f];
        self.backgroundColor = bgColor;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5.0000f;
    }
    return self;
}

@end
