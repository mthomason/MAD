//
//  MADBackgroundScrollView.m
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundScrollView.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

static const float MADBackgroundScrollViewZoomScales[] = {0.5000, 0.7500, 1.0000, 2.0000, 3.0000};

@interface MADBackgroundScrollView ()
    <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *availableZoomScales;

@end

@implementation MADBackgroundScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
        self.contentOffset = CGPointZero;
        self.maximumZoomScale = 1.0000f;
        self.minimumZoomScale = 1.0000f;
        self.zoomScale = 1.0000f;
        self.bounces = YES;
        self.alwaysBounceHorizontal = YES;
        self.alwaysBounceVertical = YES;
        self.bouncesZoom = NO;
        self.delaysContentTouches = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
        container.userInteractionEnabled = YES;
        container.translatesAutoresizingMaskIntoConstraints = NO;
        container.backgroundColor = [UIColor clearColor];
        

        [self addSubview:container];
        
        NSString *layoutHorizontal = @"H:|[container]|";
        NSString *layoutVertical = @"V:|[container]|";
        NSDictionary *metrics = @{};
        NSDictionary *views = NSDictionaryOfVariableBindings(container);
        
        NSArray *horizontalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: layoutHorizontal
                                                                                           options: NSLayoutFormatAlignAllCenterX
                                                                                           metrics: metrics
                                                                                             views: views];
        
        NSArray *verticalConstrains = [NSLayoutConstraint constraintsWithVisualFormat: layoutVertical
                                                                                         options: NSLayoutFormatAlignAllCenterY
                                                                                         metrics: metrics
                                                                                           views: views];

        NSArray *constraints = [horizontalConstrains arrayByAddingObjectsFromArray:verticalConstrains];
        
        
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

- (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest withPresentedRect:(CGRect)presentedRect containerSize:(CGSize)containerSize adjustment:(CGFloat)adjustment {
    
    if (presentedRect.origin.y > CGPointZero.y) {
        
        if (self.zoomScale <= 1.0000f) {
            [self setZoomScale: 1.0000f animated: YES];
        }
        
        CGRect visibleRect;
        visibleRect.origin = CGPointMake(self.contentOffset.x, self.contentOffset.y);
        visibleRect.size = CGSizeMake(containerSize.width, containerSize.height - presentedRect.size.height);
        
        visibleRect = CGRectAdjustForScale(visibleRect, self.zoomScale);
        
        CGRect rectOfInterestAdjusted = self.zoomScale >= 1 ?
        rectOfInterest :
        CGRectAdjustForScale(rectOfInterest, self.zoomScale);
        
        CGRect visibleRectAdjusted = CGRectMake(CGPointZero.x - (CGFLOAT_MAX / 2.0000f), visibleRect.origin.y + adjustment, CGFLOAT_MAX, visibleRect.size.height - adjustment);
        
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

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view setNeedsDisplay];
    }];
}

@end
