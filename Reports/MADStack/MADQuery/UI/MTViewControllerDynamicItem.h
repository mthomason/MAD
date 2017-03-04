//
//  MTViewControllerDynamicItem.h
//  MAD
//
//  Created by Michael Thomason on 11/25/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerDynamicItem_h
#define Reports_MTViewControllerDynamicItem_h

#import <UIKit/UIViewController.h>
#import <UIKit/UIDynamicBehavior.h>

@interface MTViewControllerDynamicItem : UIViewController
    <UIDynamicItem>

    - (void)setCenter:(CGPoint)center;
    - (void)setBounds:(CGRect)bounds;
    - (void)setTransform:(CGAffineTransform)transform;
    - (CGPoint)center;
    - (CGRect)bounds;
    - (CGAffineTransform)transform;

@end

#endif
