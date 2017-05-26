//
//  MADBackgroundScrollView.h
//  MAD
//
//  Created by Michael Thomason on 9/10/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerScrollView_h
#define Reports_MADDesignerScrollView_h

#import <UIKit/UIScrollView.h>

@class UITapGestureRecognizer;

@interface MADDesignerScrollView : UIScrollView

    @property (nonatomic, strong) UIView *container;
    @property (nonatomic, strong) UITapGestureRecognizer *doubleTapToZoom;

    - (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest
                      withPresentedRect:(CGRect)presentedRect
                          containerSize:(CGSize)containerSize
                             adjustment:(CGFloat)adjustment;

@end

#endif
