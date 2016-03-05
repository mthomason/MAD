//
//  MADQueryVisualizationScrollView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
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
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
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
    self.contentSize = CGSizeMake(contentViewWidth, contentViewHeight);

    MADQueryVisualizationContentView *contentView = [[MADQueryVisualizationContentView alloc] initWithFrame:CGRectZero];
    [self addSubview:contentView];

    NSLayoutConstraint *layoutConstraintSizeHeight = [NSLayoutConstraint LayoutConstraintHeightForView:contentView andHeight:contentViewHeight];
    NSLayoutConstraint *layoutConstraintSizeWidth = [NSLayoutConstraint LayoutConstraintWidthForView:contentView andWidth:contentViewWidth];
    
    NSDictionary *viewDictionary = @{@"cv" : contentView};
    NSArray *layoutConstraintCenterX = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cv]|" options:NSLayoutFormatAlignAllCenterX metrics:0 views:viewDictionary];
    NSArray *layoutConstraintCenterY = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cv]|" options:NSLayoutFormatAlignAllCenterY metrics:0 views:viewDictionary];
    
    NSArray *containerViewConstraints = @[layoutConstraintSizeHeight, layoutConstraintSizeWidth];
    containerViewConstraints = [containerViewConstraints arrayByAddingObjectsFromArray:layoutConstraintCenterX];
    containerViewConstraints = [containerViewConstraints arrayByAddingObjectsFromArray:layoutConstraintCenterY];
    
    [self addConstraints:containerViewConstraints];
    self.contentView = contentView;
    
    
}

@end
