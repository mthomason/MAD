//
//  NSLayoutConstraint+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTRulerView;

@interface NSLayoutConstraint (Designer)

+ (NSLayoutConstraint *)layoutConstraintViewScrollerTop:(id)item toItem:(id)item;
+ (NSArray *)layoutConstraintsRuler:(MTRulerView *)ruler inDesigner:(UIView *)designer marginTop:(CGFloat)marginTop heigh:(CGFloat)height;
+ (NSArray *)layoutConstraintsRulerSide:(MTRulerView *)ruler inDesigner:(UIView *)designer sideMargin:(CGFloat)sideMargin;
+ (NSLayoutConstraint *)layoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height;
+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelBottom:(UIView *)label padding:(CGFloat)padding;
+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelRight:(UIView *)label padding:(CGFloat)padding;
+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toHeight:(CGFloat)height;
+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toItemBottom:(UIView *)item  padding:(CGFloat)padding;
+ (NSArray *)layoutConstraintsForSection:(UIView *)section content:(UIView *)content padding:(CGFloat)padding;
+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view toScrollerBottom:(UIScrollView *)scroller;
+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view height:(CGFloat)height;
+ (NSLayoutConstraint *)layoutConstraintToolbarBottomToToolboxView:(id)item toItem:(id)toItem;
+ (NSLayoutConstraint *)layoutConstraintToolBoxViewBottom:(id)item toItem:(id)toItem;
+ (NSLayoutConstraint *)layoutConstraintToolBoxViewHeight:(id)toolbox height:(CGFloat)height;
+ (NSLayoutConstraint *)layoutConstraintToolboxHeightHidden:(id)item;
+ (NSLayoutConstraint *)layoutConstraintView:(id)view contentLeft:(id)container;
+ (NSLayoutConstraint *)layoutConstraintView:(UIView *)view contentRight:(id)container;
+ (NSLayoutConstraint *)layoutConstraintView:(UIView *)view contentTop:(id)container;
+ (NSLayoutConstraint *)layoutConstraintViewScroller:(id)scroller bottom:(id)bottom;
+ (NSLayoutConstraint *)layoutConstraintViewToolbarHeightHidden:(id)toolbar;

@end
