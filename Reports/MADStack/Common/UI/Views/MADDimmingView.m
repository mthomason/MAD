//
//  MADDimmingView.m
//  MAD
//
//  Created by Michael Thomason on 11/4/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADDimmingView.h"
#import "madlog.h"
#import "MADDesignerSectionView.h"

@implementation MADDimmingView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
		self.alpha = 0.0;
	}
	return self;
}

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
	UIView *hitview = nil;
	UIView *container = _container;
	CGPoint pointNormalized = [container convertPoint: point fromView: self];
	NSSet *passthroughViews = self.passthroughViews;

	for (UIView *foundView in passthroughViews) {
		CGRect rectNormalized = [foundView convertRect: foundView.bounds
												toView: container];
		if (CGRectContainsPoint(rectNormalized, pointNormalized)) {
			if (![foundView isKindOfClass:[MADDesignerSectionView class]]) {
				hitview = foundView;
				break;
			}
		}
	}
	
	if (hitview == nil) {
		NSSet *passthroughContainers = self.passthroughContainers;
		for (UIView *passthroughContainer in passthroughContainers) {
			CGRect rectNormalized = [passthroughContainer convertRect: passthroughContainer.bounds
															   toView: container];
			if (CGRectContainsPoint(rectNormalized, pointNormalized)) {
				hitview = passthroughContainer;
				break;
			}
		}
		if (hitview == nil && self.passthroughContainer != nil) {
			hitview = self.passthroughContainer;
		} else if (hitview == nil) {
			hitview = [super hitTest:point withEvent:event];
		}
	}
	return hitview;
}

@end
