//
//  MADBackgroundScrollView.m
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundScrollView.h"

static const float MADBackgroundScrollViewZoomScales[] = {0.5000, 0.7500, 1.0000, 2.0000, 3.0000};

@interface MADBackgroundScrollView ()
    <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *availableZoomScales;

@end

@implementation MADBackgroundScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

        self.bouncesZoom = YES;
        self.scrollsToTop = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.scrollEnabled = YES;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.indicatorStyle = UIScrollViewIndicatorStyleDefault;
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
        container.userInteractionEnabled = YES;
        container.backgroundColor = [UIColor clearColor];
        container.translatesAutoresizingMaskIntoConstraints = NO;
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
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapZoom:)];
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
    if ([sender state] == UIGestureRecognizerStateEnded) {
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
