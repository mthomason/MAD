//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADSliderPageVertical.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UIImage.h>

@interface MADSliderPageVertical ()

@property (nonatomic, strong) UIImage *imageEnabled;
@property (nonatomic, strong) UIImage *imageDisabled;

@end

@implementation MADSliderPageVertical

- (instancetype)initWithFrame:(CGRect)frame {
	
	if (self = [super initWithFrame:frame]) {
		
		[self setMinimumTrackImage:[UIImage new] forState: UIControlStateNormal];
		[self setMaximumTrackImage:[UIImage new] forState: UIControlStateNormal];
		
		self.maximumValue = 0.0;
		self.minimumValue = 0.0;
		self.value = 0.0;
		self.continuous = YES;
		self.tintColor = [MADColorEverydayApps newColorRed];
		self.backgroundColor = [UIColor clearColor];
		[self setThumbImage: [UIImage imageNamed:@"MTSliderThumbRotate"] forState: UIControlStateNormal];
		
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
	[self setThumbImage: enabled ? self.imageEnabled : self.imageDisabled
			   forState: UIControlStateNormal];
}

@end
