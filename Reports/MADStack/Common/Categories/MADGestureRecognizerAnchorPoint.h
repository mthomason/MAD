//
//  MADGestureRecognizerAnchorPoint.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_UIGestureRecognizer_AnchorPoint_h
#define Reports_UIGestureRecognizer_AnchorPoint_h

#import <UIKit/UIGestureRecognizer.h>

@interface MADGestureRecognizerAnchorPoint : NSObject

    + (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
    + (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
                                              inView:(UIView *)containerView;

@end

#endif
