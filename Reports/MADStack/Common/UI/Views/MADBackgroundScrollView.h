//
//  MADBackgroundScrollView.h
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADBackgroundScrollView_h
#define Reports_MADBackgroundScrollView_h

#import <UIKit/UIScrollView.h>
#import <UIKit/UITapGestureRecognizer.h>

@class MADContainerView;

@interface MADBackgroundScrollView : UIScrollView

@property (nonatomic, strong) MADContainerView *backgroundContainer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapToZoom;

- (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest withPresentedRect:(CGRect)presentedRect containerSize:(CGSize)containerSize adjustment:(CGFloat)adjustment;

@end

#endif
