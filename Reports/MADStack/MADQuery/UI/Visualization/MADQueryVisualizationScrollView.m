//
//  MADQueryVisualizationScrollView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationScrollView.h"
#import "MADQueryVisualizationContentView.h"
#import "NSLayoutConstraint+QueryVisualization.h"

static const CGFloat contentViewWidth = 1024.0;
static const CGFloat contentViewHeight = 1024.0;

@interface MADQueryVisualizationScrollView ()
	<UIScrollViewDelegate>

	@property (nonatomic, strong, readwrite) MADQueryVisualizationContentView *contentView;

@end

@implementation MADQueryVisualizationScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit {
	self.showsHorizontalScrollIndicator = YES;
	self.showsVerticalScrollIndicator = YES;
	self.contentOffset = CGPointZero;
	self.maximumZoomScale = 1.0;
	self.minimumZoomScale = 1.0;
	self.zoomScale = 1.0;
	self.scrollEnabled = YES;
	self.bounces = YES;
	self.alwaysBounceHorizontal = YES;
	self.alwaysBounceVertical = YES;
	self.bouncesZoom = NO;
	self.delaysContentTouches = YES;
	self.translatesAutoresizingMaskIntoConstraints = NO;
	self.autoresizesSubviews = NO;
	self.delegate = self;
	self.backgroundColor = [[UIColor systemGroupedBackgroundColor] colorWithAlphaComponent: 0.02];
	self.opaque = NO;
	
	self.contentSize = CGSizeMake(contentViewWidth, contentViewHeight);

	MADQueryVisualizationContentView *contentView = [[MADQueryVisualizationContentView alloc] initWithFrame:CGRectZero];

	[self addSubview:contentView];
	
	NSLayoutConstraint *layoutConstraintSizeHeight = [NSLayoutConstraint newLayoutConstraintHeightForView:contentView
																								andHeight:contentViewHeight];
	NSLayoutConstraint *layoutConstraintSizeWidth = [NSLayoutConstraint newLayoutConstraintWidthForView:contentView
																							   andWidth:contentViewWidth];
	
	NSDictionary *viewDictionary;
	viewDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:contentView, @"cv", nil];
	NSArray <NSLayoutConstraint *> *layoutConstraintCenterX;
	layoutConstraintCenterX = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[cv]|"
																	  options: NSLayoutFormatAlignAllCenterX
																	  metrics: 0
																		views: viewDictionary];
	NSArray <NSLayoutConstraint *> *layoutConstraintCenterY;
	layoutConstraintCenterY = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[cv]|"
																	  options: NSLayoutFormatAlignAllCenterY
																	  metrics: 0
																		views: viewDictionary];
	
	NSArray <NSLayoutConstraint *> *containerViewConstraints;
	containerViewConstraints = [[NSArray alloc] initWithObjects: layoutConstraintSizeHeight,
																 layoutConstraintSizeWidth, nil];
	containerViewConstraints = [containerViewConstraints arrayByAddingObjectsFromArray:layoutConstraintCenterX];
	containerViewConstraints = [containerViewConstraints arrayByAddingObjectsFromArray:layoutConstraintCenterY];
	
	[self addConstraints:containerViewConstraints];
	contentView.autoresizesSubviews = NO;
	self.contentView = contentView;
	
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	//[self updateCache];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView { }

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view
						atScale:(CGFloat)scale { }

- (void)scrollViewDidScroll:(UIScrollView *)scrollView { }

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView { }

- (void)scrollViewDidZoom:(UIScrollView *)scrollView { }

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView { return NO; }

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { }

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view { }

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
					 withVelocity:(CGPoint)velocity
			  targetContentOffset:(inout CGPoint *)targetContentOffset { }

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.contentView;
}

@end
