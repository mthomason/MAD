//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSliderPageVertical.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "UIImage+ImageEffects.h"

@interface MADSliderPageVertical ()

@end

@implementation MADSliderPageVertical

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        UIImage *thumbImage = [MADSliderPageVertical sliderImageEnabled];
        UIImage *blank = [UIImage new];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        [self setMinimumTrackImage:blank forState:UIControlStateNormal];
        [self setMaximumTrackImage:blank forState:UIControlStateNormal];
        
        self.maximumValue = 0.0000f;
        self.minimumValue = 0.0000f;
        self.continuous = YES;
        self.tintColor = [UIColor tintColorRed];
        self.value = 0.0000f;
        self.backgroundColor = [UIColor clearColor];
        
        
    }
    return self;
}

+ (UIImage *)sliderImageEnabled {
    return [UIImage imageNamed:@"MTSliderThumbRotate"];
}

+ (UIImage *)sliderImageDisabled {
    return [UIImage imageNamed:@"MTSliderThumbRotateDisabled"];
}

@end
