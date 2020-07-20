//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
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
        
        self.maximumValue = 0.0;
        self.minimumValue = 0.0;
        self.value = 0.0;
        self.continuous = YES;
        self.tintColor = [MADColorEverydayApps newColorRed];
        self.backgroundColor = [UIColor clearColor];
        UIImage *image = [self imageEnabled];
        [self setThumbImage: image forState: UIControlStateNormal];
        
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
    if (_imageDisabled == nil) {
        _imageDisabled = [UIImage imageNamed:@"MTSliderThumbRotateDisabled"];
    }
    return _imageDisabled;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    UIImage *image = enabled ? self.imageEnabled : self.imageDisabled;
    [self setThumbImage: image forState: UIControlStateNormal];
}

@end
