//
//  MADBackgroundScrollView.m
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerScrollView.h"
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UIView.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADDesignerLayoutDesignView.h"

static inline CGRect displayBoundsRect(CGPoint offset, CGSize size, CGRect presentedRect);
static inline CGRect displayBoundsRect(CGPoint offset, CGSize size, CGRect presentedRect) {
    CGRect r = CGRectMake(offset.x, offset.y,
                                    size.width, size.height - presentedRect.size.height);
    return r;
}

static inline CGRect displayBoundsToScale(CGFloat zoomScale, CGRect rectOfInterest);
static inline CGRect displayBoundsToScale(CGFloat zoomScale, CGRect rectOfInterest) {
    CGRect r = zoomScale >= 1 ? rectOfInterest :
                                                CGRectAdjustForScale(rectOfInterest, zoomScale);
    return r;
}

static inline CGRect displayBoundsScaled(CGFloat adjustment, CGRect rect);
static inline CGRect displayBoundsScaled(CGFloat adjustment, CGRect rect) {
    CGRect r = CGRectMake(CGPointZero.x - (CGFLOAT_MAX / 2.0000f), rect.origin.y + adjustment,
                                    CGFLOAT_MAX, rect.size.height - adjustment);
    return r;
}

@interface MADDesignerScrollView ()
    <UIGestureRecognizerDelegate>

    @property (nonatomic, strong) NSArray *availableZoomScales;

    - (instancetype)initWithCoder:(NSCoder *)aDecoder;
    - (void)doubleTapZoom:(UITapGestureRecognizer *)sender;
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
        
        NSArray *horizontalConstrains, *verticalConstrains, *constraints;
        horizontalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[container]|"
                                                                       options: NSLayoutFormatAlignAllCenterX
                                                                       metrics: metrics
                                                                         views: views];
        
        verticalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[container]|"
                                                                     options: NSLayoutFormatAlignAllCenterY
                                                                     metrics: metrics
                                                                       views: views];

        constraints = [horizontalConstrains arrayByAddingObjectsFromArray:verticalConstrains];
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                              action: @selector(doubleTapZoom:)];
        tap.numberOfTapsRequired = 2;
        tap.numberOfTouchesRequired = 1;
        
        [self addConstraints:constraints];
        [self addGestureRecognizer:tap];
        self.container = container;
        self.doubleTapToZoom = tap;
        
    }
    return self;
}

- (void)doubleTapZoom:(UITapGestureRecognizer *)sender {
    static const float MADBackgroundScrollViewZoomScales[] = {0.5000, 0.7500, 1.0000, 2.0000, 3.0000};
    if (sender.state == UIGestureRecognizerStateEnded) {
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
    NSArray<__kindof UIView *> *subviews = self.subviews;
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view setNeedsDisplay];
    }];
}

- (void)setNeedsUpdateConstraints {
    [super setNeedsUpdateConstraints];
    [self.container setNeedsUpdateConstraints];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self.container setNeedsLayout];
}

@end
