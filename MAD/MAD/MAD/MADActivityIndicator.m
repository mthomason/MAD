//
//  MADActivityIndicator.m
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADActivityIndicator.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UILabel.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIAppearance.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "MADActivityIndicatorLabel.h"

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
		
		self.layer.cornerRadius = 5.0000f;
		
		UIActivityIndicatorView *activityIndicator;
		activityIndicator= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
														UIActivityIndicatorViewStyleWhiteLarge];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
								UIViewAutoresizingFlexibleRightMargin |
								UIViewAutoresizingFlexibleTopMargin |
								UIViewAutoresizingFlexibleBottomMargin;
		
		activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
											 UIViewAutoresizingFlexibleRightMargin |
											 UIViewAutoresizingFlexibleTopMargin;
		
		
		activityIndicator.center = CGPointMake(self.bounds.size.width / 2.0000f,
											   self.bounds.size.height / 2.0000f);

		CGRect labelFrame = CGRectMake(CGPointZero.x, frame.size.height - 44.0000f,
									   frame.size.width, 44.0000f);
		
		id status = [[MADActivityIndicatorLabel alloc] initWithFrame:labelFrame];

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
