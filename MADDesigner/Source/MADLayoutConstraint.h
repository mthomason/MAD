//
//  MADLayoutConstraint.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_NSLayoutConstraint_Designer_h
#define Reports_NSLayoutConstraint_Designer_h

#import <UIKit/NSLayoutConstraint.h>

@class UIView, MADRulerView, UIScrollView;

@interface MADLayoutConstraint : NSObject

+ (NSArray <NSLayoutConstraint *> *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
											 marginTop:(CGFloat)marginTop heigh:(CGFloat)height scaleFactor:(CGFloat)scaleFactor;

+ (NSArray <NSLayoutConstraint *> *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
											sideMargin:(CGFloat)sideMargin scaleFactor:(CGFloat)scaleFactor;

+ (NSLayoutConstraint *)LayoutConstraintViewScrollerTop:(id)item view:(id)item;
+ (NSLayoutConstraint *)LayoutConstraintViewLeft:(UIView *)section content:(UIView *)content
										 padding:(CGFloat)padding;
+ (NSLayoutConstraint *)LayoutConstraintViewRight:(UIView *)section content:(UIView *)content
										  padding:(CGFloat)padding;
+ (NSLayoutConstraint *)LayoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height;
+ (NSLayoutConstraint *)LayoutConstraintLabelBottom:(UIView *)label container:(UIView *)section
											padding:(CGFloat)padding;
+ (NSLayoutConstraint *)LayoutConstraintLabelRight:(UIView *)label container:(UIView *)section
										   padding:(CGFloat)padding;
+ (NSLayoutConstraint *)LayoutConstraintViewTop:(UIView *)item viewBottom:(UIView *)section
										padding:(CGFloat)padding;
+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerBottom:(UIView *)scroller;
+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view height:(CGFloat)height;
+ (NSLayoutConstraint *)LayoutConstraintViewBottom:(id)item container:(id)toItem;
+ (NSLayoutConstraint *)LayoutConstraintToolBoxBottom:(id)item container:(id)toItem;
+ (NSLayoutConstraint *)LayoutConstraintToolboxHeightHidden:(id)item;
+ (NSLayoutConstraint *)LayoutConstraintView:(id)view containerLeft:(id)container;
+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerRight:(id)container;
+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerTop:(id)container;
+ (NSLayoutConstraint *)LayoutConstraintScroller:(id)scroller bottom:(id)bottom;
+ (NSLayoutConstraint *)LayoutConstraintToolbarHeightHidden:(id)toolbar;
+ (NSLayoutConstraint *)newLayoutConstraintContent:(id)container width:(CGFloat)width;

+ (NSLayoutConstraint *)LayoutConstraint:(id)view height:(CGFloat)height;
+ (NSLayoutConstraint *)LayoutConstraint:(id)view width:(CGFloat)width;
+ (NSLayoutConstraint *)LayoutConstraint:(id)view toView:(id)view2 centerX:(CGFloat)centerX;
+ (NSLayoutConstraint *)LayoutConstraint:(id)view toView:(id)view2 centerY:(CGFloat)centerY;

@end

#endif
