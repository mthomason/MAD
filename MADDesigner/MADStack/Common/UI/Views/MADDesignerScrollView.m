//
//  MADBackgroundScrollView.m
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerScrollView.h"
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UIView.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADDesignerLayoutDesignView.h"

static inline CGRect displayBoundsRect(CGPoint, CGSize, CGRect);
static inline CGRect displayBoundsToScale(CGFloat, CGRect);
static inline CGRect displayBoundsScaled(CGFloat, CGRect);

static inline CGRect displayBoundsRect(CGPoint offset, CGSize size, CGRect presentedRect) {
	CGRect r = CGRectMake(offset.x, offset.y,
									size.width, size.height - presentedRect.size.height);
	return r;
}

static inline CGRect displayBoundsToScale(CGFloat zoomScale, CGRect rectOfInterest) {
	CGRect r = zoomScale >= 1 ? rectOfInterest :
												CGRectAdjustForScale(rectOfInterest, zoomScale);
	return r;
}

static inline CGRect displayBoundsScaled(CGFloat adjustment, CGRect rect) {
	CGRect r = CGRectMake(CGPointZero.x - (CGFLOAT_MAX / 2.0000f), rect.origin.y + adjustment,
									CGFLOAT_MAX, rect.size.height - adjustment);
	return r;
}

@interface MADDesignerScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *availableZoomScales;

- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)handleTapDoubleGesture:(UITapGestureRecognizer *)sender;
- (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest withPresentedRect:(CGRect)presentedRect
					  containerSize:(CGSize)containerSize adjustment:(CGFloat)adjustment;
- (void)setNeedsDisplay;
- (void)setNeedsUpdateConstraints;
- (void)setNeedsLayout;

@end

@implementation MADDesignerScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		
		self.showsHorizontalScrollIndicator = YES;
		self.showsVerticalScrollIndicator = YES;
		self.scrollsToTop = YES;
		self.scrollEnabled = YES;
		self.userInteractionEnabled = YES;
		self.contentOffset = CGPointZero;
		self.indicatorStyle            = UIScrollViewIndicatorStyleDefault;
		self.maximumZoomScale          = 4.0000f;
		self.minimumZoomScale          = 0.3000f;
		self.zoomScale = 1.0000f;
		self.bounces = YES;
		self.alwaysBounceHorizontal = YES;
		self.alwaysBounceVertical = YES;
		self.bouncesZoom = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];

		self.delaysContentTouches = YES;
		self.translatesAutoresizingMaskIntoConstraints = NO;
		
		MADDesignerLayoutDesignView *container = [[MADDesignerLayoutDesignView alloc] initWithFrame:CGRectZero];
		container.userInteractionEnabled = YES;
		container.opaque = NO;
		container.translatesAutoresizingMaskIntoConstraints = NO;
		container.backgroundColor = [UIColor clearColor];
		

		[self addSubview:container];
		
		NSDictionary *metrics = [[NSDictionary alloc] init];
		NSDictionary *views = NSDictionaryOfVariableBindings(container);
		
		NSArray<NSLayoutConstraint *> *horizontalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[container]|"
																	   options: NSLayoutFormatAlignAllCenterX
																	   metrics: metrics
																		 views: views];
		
		NSArray<NSLayoutConstraint *> *verticalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[container]|"
																	 options: NSLayoutFormatAlignAllCenterY
																	 metrics: metrics
																	   views: views];

		NSArray<NSLayoutConstraint *> *constraints = [horizontalConstrains arrayByAddingObjectsFromArray:verticalConstrains];
		[self addConstraints:constraints];

		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
																			  action: @selector(handleTapDoubleGesture:)];
		tap.numberOfTapsRequired = 2;
		tap.numberOfTouchesRequired = 1;
		[self addGestureRecognizer:tap];

		self.container = container;
		self.doubleTapToZoom = tap;
		
	}
	return self;
}

- (void)handleTapDoubleGesture:(UITapGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateEnded) {
	static const float MADBackgroundScrollViewZoomScales[] = {0.50000000f, 0.75000000f,
															  1.00000000f, 2.00000000f,
															  3.00000000f};
		CGFloat initalZoomScale = self.zoomScale;
		CGFloat zoomScale = MADBackgroundScrollViewZoomScales[0];
		for (int i=0; i<5; i++) {
			if (initalZoomScale < MADBackgroundScrollViewZoomScales[i]) {
				zoomScale = MADBackgroundScrollViewZoomScales[i];
				break;
			}
		}
		[self setZoomScale:zoomScale animated:YES];
		[self.delegate scrollViewDidEndZooming: self
									  withView: self.container
									   atScale: zoomScale];
	}
}

- (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest withPresentedRect:(CGRect)presentedRect
					  containerSize:(CGSize)containerSize adjustment:(CGFloat)adjustment {
	
	if (presentedRect.origin.y > CGPointZero.y) {
		
		if (self.zoomScale <= 1.0000f) {
			[self setZoomScale: 1.0000f animated: YES];
		}
		
		CGRect visibleRect = CGRectAdjustForScale(displayBoundsRect(self.contentOffset, containerSize, presentedRect), self.zoomScale);
		CGRect rectOfInterestAdjusted = displayBoundsToScale(self.zoomScale, rectOfInterest);
		CGRect visibleRectAdjusted = displayBoundsScaled(adjustment, visibleRect);

		if (CGRectContainsRect(visibleRectAdjusted, rectOfInterestAdjusted) == NO) {
			
			CGPoint contentOffset = CGPointContentOffsetBottomOfRect(rectOfInterest, visibleRect);
			if (self.zoomScale > 1) {
				contentOffset = CGPointMake(contentOffset.x, contentOffset.y * self.zoomScale);
			}
			[self setContentOffset: contentOffset animated: YES];
			
		}
	}
	return presentedRect;
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	for (__kindof UIView *subview in self.subviews) {
		[subview setNeedsDisplay];
	}
}

- (void)setNeedsUpdateConstraints {
	[super setNeedsUpdateConstraints];
	[self.container setNeedsUpdateConstraints];
}

- (void)setNeedsLayout {
	[super setNeedsLayout];
	[self.container setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	//self.container.bounds = CGRectMake(self.container.bounds.origin.x, self.container.bounds.origin.y, [self container].bounds.size.width, self.contentSize.height);
}

@end
