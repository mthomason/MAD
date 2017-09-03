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

@class UITapGestureRecognizer, MADDesignerLayoutDesignView, MADDesignerSectionView, MADDesignerSectionLabel;

@interface MADDesignerScrollView : UIScrollView

    @property (nonatomic, strong) MADDesignerLayoutDesignView *container;
    @property (nonatomic, strong) UITapGestureRecognizer *doubleTapToZoom;

    - (CGRect)positionForRectOfInterest:(CGRect)rectOfInterest
                      withPresentedRect:(CGRect)presentedRect
                          containerSize:(CGSize)containerSize
                             adjustment:(CGFloat)adjustment;

    @property (nonatomic, readonly) NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViews;
    @property (nonatomic, readonly) NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionLabels;

@end

#endif
