//
//  MADQueryVisualizationScrollView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationScrollView.h"
#import "MADQueryVisualizationContentView.h"
#import "NSLayoutConstraint+QueryVisualization.h"

static const CGFloat contentViewWidth = 1024.0000f;
static const CGFloat contentViewHeight = 1024.0000f;

@interface MADQueryVisualizationScrollView ()

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
    self.maximumZoomScale = 1.0000f;
    self.minimumZoomScale = 1.0000f;
    self.zoomScale = 1.0000f;
    self.scrollEnabled = YES;
    self.bounces = YES;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    self.bouncesZoom = NO;
    self.delaysContentTouches = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.backgroundColor = [UIColor blueColor];
    self.alpha = 0.3000f;
    
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

@end
