//
//  UIView+Extras.h
//  MAD
//
//  Created by Michael Thomason on 8/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_UIView_Extras_h
#define MAD_Designer_UIView_Extras_h

#import <UIKit/UIKit.h>

@interface UIView (Extras)

    - (CGRect)popoverRectForSelectedViews:(NSSet *)views;
    - (CGPoint)locationInMainWindow:(UIGestureRecognizer *)gestureRecognizer;

    + (CGFloat)borderWidthThin;

@end

#endif
