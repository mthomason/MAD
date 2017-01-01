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

@property (nonatomic, strong) UIImage *imageEnabled;
@property (nonatomic, strong) UIImage *imageDisabled;

@end

@implementation MADSliderPageVertical

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        UIImage *imageBlank;

        imageBlank = [UIImage new];
        [self setMinimumTrackImage:imageBlank forState: UIControlStateNormal];
        
        imageBlank = [UIImage new];
        [self setMaximumTrackImage:imageBlank forState: UIControlStateNormal];
        
        self.maximumValue = 0.0000f;
        self.minimumValue = 0.0000f;
        self.value = 0.0000f;
        self.continuous = YES;
        self.tintColor = [MADColorEverydayApps newColorRed];
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

- (UIImage *)imageEnabled {
    if (_imageEnabled == nil) {
        _imageEnabled = [UIImage imageNamed:@"MTSliderThumbRotate"];
    }
    return _imageEnabled;
}

- (UIImage *)imageDisabled {
    if (_imageEnabled == nil) {
        _imageEnabled = [UIImage imageNamed:@"MTSliderThumbRotateDisabled"];
    }
    return _imageEnabled;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    UIImage *image = enabled ? self.imageEnabled : self.imageDisabled;
    [self setThumbImage: image forState: UIControlStateNormal];
}

@end
