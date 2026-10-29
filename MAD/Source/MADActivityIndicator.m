//
//  MADActivityIndicator.m
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import "MADActivityIndicator.h"
#import "MADActivityIndicatorLabel.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIAppearance.h>
#import <QuartzCore/CALayer.h>

@interface MADActivityIndicator ()
@property(readwrite, nonatomic, weak) UIActivityIndicatorView *activityIndicator;;
@end

@implementation MADActivityIndicator

+ (void)initialize {
	[super initialize];
	if (self == [MADActivityIndicator self]) {
		@autoreleasepool {
			UIColor *bgColor = [MADColorEverydayApps newColorBlueLightBackground];
			[[MADActivityIndicator appearance] setBackgroundColor:bgColor];
		}
	}
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.layer.cornerRadius = 5.0;
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleLarge];
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
		activityIndicator.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);

		id status = [[MADActivityIndicatorLabel alloc] initWithFrame:CGRectMake(CGPointZero.x, frame.size.height - 44.0, frame.size.width, 44.0)];

		[self addSubview:activityIndicator];
		[self addSubview:status];
		
		self.activityIndicator = activityIndicator;
		self.status = status;
		
	}
	return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	id activityIndicator = self.activityIndicator;
	if (newSuperview) {
		[activityIndicator startAnimating];
	} else {
		[activityIndicator stopAnimating];
	}
}

@end
#endif
