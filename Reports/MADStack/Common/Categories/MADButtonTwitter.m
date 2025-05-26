//
//  MADButtonTwitter.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADButtonTwitter.h"
#import "MADAttributedStringCommon.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <UIKit/UIAccessibility.h>
#import <QuartzCore/CALayer.h>

@implementation MADButtonTwitter

+ (instancetype)newButtonTwitterFolllowTwitterWithTarget:(id)target action:(SEL)action {
	return [self newButtonTwitterFolllowTwitterWithTarget:target action:action size:medium];
}

+ (instancetype)newButtonTwitterFolllowTwitterWithTarget:(id)target action:(SEL)action
													size:(MADSizeGeneral)size {

	void(^formatButton)(MADButtonTwitter *) = ^(MADButtonTwitter *b){
		id followOnTwitter;
		b.backgroundColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];
		b.layer.cornerRadius = 5.0;
		b.clipsToBounds = YES;
		switch (size) {
			case small:
				b.frame = MADRectOfSize(CGSizeMake(66.0, 28.0));
				break;
			case medium:
				b.frame = MADRectOfSize(CGSizeMake(100.0, 32.0));
				break;
			case large:
				b.frame = MADRectOfSize(CGSizeMake(120.0, 44.0));
				break;
			default:
				b.frame = MADRectOfSize(CGSizeMake(100.0, 32.0));
				break;
		}
		b.accessibilityLabel = NSLocalizedString(@"Twitter Follow", @"Twitter Follow");
		b.accessibilityHint = NSLocalizedString(@"Follow us on Twitter.", @"Follow us on Twitter.");
		b.isAccessibilityElement = YES;
		b.accessibilityTraits = UIAccessibilityTraitButton;
		[b addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
		followOnTwitter = [MADAttributedStringCommon newAttributedStringFollowOnTwitter];
		[b setAttributedTitle:followOnTwitter forState:UIControlStateNormal];
	};

	id result = [self buttonWithType:UIButtonTypeSystem];
	
	formatButton(result);

	
	return result;
}

@end
