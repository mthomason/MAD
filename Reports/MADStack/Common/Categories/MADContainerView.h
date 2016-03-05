//
//  UIView+Extras.h
//  MAD
//
//  Created by Michael Thomason on 8/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADContainerView : UIView

- (CGRect)popoverRectForSelectedViews:(NSSet *)views;
- (CGPoint)locationInMainWindow:(UIGestureRecognizer *)gestureRecognizer;

+ (CGFloat)borderWidthThin;

@end
