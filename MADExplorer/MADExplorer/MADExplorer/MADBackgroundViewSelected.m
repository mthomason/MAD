//
//  MADBackgroundViewSelected.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundViewSelected.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADBackgroundViewSelected

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *colorTextNormal = [UIColor tintColorBlue];
        UIColor *bgColor = [colorTextNormal colorWithAlphaComponent:0.70000f];
        self.backgroundColor = bgColor;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5.0000f;
    }
    return self;
}

@end
