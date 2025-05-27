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
		self.backgroundColor = [[MADColorEverydayApps newColorBlue] colorWithAlphaComponent:0.7];
		self.clipsToBounds = YES;
		self.layer.cornerRadius = 5.0;
	}
	return self;
}

@end
