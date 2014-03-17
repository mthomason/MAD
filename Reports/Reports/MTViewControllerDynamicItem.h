//
//  MTViewControllerDynamicItem.h
//  MAD
//
//  Created by Michael Thomason on 11/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTViewControllerDynamicItem : UIViewController
    <UIDynamicItem>

- (void)setCenter:(CGPoint)center;
- (void)setBounds:(CGRect)bounds;
- (void)setTransform:(CGAffineTransform)transform;
- (CGPoint)center;
- (CGRect)bounds;
- (CGAffineTransform)transform;

@end
