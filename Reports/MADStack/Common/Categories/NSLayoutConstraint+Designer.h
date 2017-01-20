//
//  NSLayoutConstraint+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSLayoutConstraint_Designer_h
#define Reports_NSLayoutConstraint_Designer_h

#import <UIKit/NSLayoutConstraint.h>

@class UIView;
@class MTRulerView;
@class UIScrollView;

@interface MADLayoutConstraint : NSLayoutConstraint

    + (NSArray *)constraintForRuler:(MTRulerView *)ruler designer:(UIView *)designer
                          marginTop:(CGFloat)marginTop heigh:(CGFloat)height;
                          
    + (NSArray *)constraintForRuler:(MTRulerView *)ruler designer:(UIView *)designer
                         sideMargin:(CGFloat)sideMargin;

    + (instancetype)newLayoutConstraintViewScrollerTop:(id)item view:(id)item;
    + (instancetype)newLayoutConstraintViewLeft:(UIView *)section content:(UIView *)content
                                        padding:(CGFloat)padding;
    + (instancetype)newLayoutConstraintViewRight:(UIView *)section content:(UIView *)content
                                         padding:(CGFloat)padding;
    + (instancetype)newLayoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height;
    + (instancetype)newLayoutConstraintLabelBottom:(UIView *)label container:(UIView *)section
                                           padding:(CGFloat)padding;
    + (instancetype)newLayoutConstraintLabelRight:(UIView *)label container:(UIView *)section
                                          padding:(CGFloat)padding;
    + (instancetype)newLayoutConstraintViewTop:(UIView *)item viewBottom:(UIView *)section
                                       padding:(CGFloat)padding;
    + (instancetype)newLayoutConstraintView:(UIView *)view containerBottom:(UIScrollView *)scroller;
    + (instancetype)newLayoutConstraintView:(UIView *)view height:(CGFloat)height;
    + (instancetype)newLayoutConstraintViewBottom:(id)item container:(id)toItem;
    + (instancetype)newLayoutConstraintToolBoxBottom:(id)item container:(id)toItem;
    + (instancetype)newLayoutConstraintToolBoxView:(id)toolbox height:(CGFloat)height;
    + (instancetype)newLayoutConstraintToolboxHeightHidden:(id)item;
    + (instancetype)newLayoutConstraintView:(id)view containerLeft:(id)container;
    + (instancetype)newLayoutConstraintView:(UIView *)view containerRight:(id)container;
    + (instancetype)newLayoutConstraintView:(UIView *)view containerTop:(id)container;
    + (instancetype)newLayoutConstraintScroller:(id)scroller bottom:(id)bottom;
    + (instancetype)newLayoutConstraintToolbarHeightHidden:(id)toolbar;
    + (instancetype)newLayoutConstraintContent:(id)container width:(CGFloat)width;

@end

#endif
