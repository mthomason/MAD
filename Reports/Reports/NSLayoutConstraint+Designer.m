//
//  NSLayoutConstraint+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+Designer.h"

@implementation NSLayoutConstraint (Designer)

+ (NSLayoutConstraint *)layoutConstraintViewScrollerTop:(id)item toItem:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSArray *)layoutConstraintsRuler:(MTRulerView *)ruler inDesigner:(UIView *)designer marginTop:(CGFloat)marginTop heigh:(CGFloat)height {
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeHeight
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: nil
                                                                   attribute: NSLayoutAttributeNotAnAttribute
                                                                  multiplier: 1.0000f
                                                                    constant: height];
    
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeTop
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeTop
                                                                  multiplier: 1.0000f
                                                                    constant: marginTop];
    
    return @[constraint1, constraint2];
}

+ (NSArray *)layoutConstraintsRulerSide:(MTRulerView *)ruler inDesigner:(UIView *)designer sideMargin:(CGFloat)sideMargin {
    NSLayoutConstraint *constraint3 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeLeft
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeLeft
                                                                  multiplier: 1.0000f
                                                                    constant: sideMargin];
    
    NSLayoutConstraint *constraint4 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeRight
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeRight
                                                                  multiplier: 1.0000f
                                                                    constant: -sideMargin];
    return @[constraint3, constraint4];
}

+ (NSLayoutConstraint *)layoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelBottom:(UIView *)label padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: -padding];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelRight:(UIView *)label padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: -padding];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: section
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toItemBottom:(UIView *)item padding:(CGFloat)padding {
    return  [NSLayoutConstraint constraintWithItem: item
                                         attribute: NSLayoutAttributeBottom
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: section
                                         attribute: NSLayoutAttributeTop
                                        multiplier: 1.0000f
                                          constant: -padding];
}

+ (NSArray *)layoutConstraintsForSection:(UIView *)section content:(UIView *)content padding:(CGFloat)padding {
    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem: section
                                                           attribute: NSLayoutAttributeLeft
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: content
                                                           attribute: NSLayoutAttributeLeft
                                                          multiplier: 1.0000f
                                                            constant: padding];
    
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem: section
                                                           attribute: NSLayoutAttributeRight
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: content
                                                           attribute: NSLayoutAttributeRight
                                                          multiplier: 1.0000f
                                                            constant: -padding];
    
    return @[lc1, lc2];
}

+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view toScrollerBottom:(UIScrollView *)scroller {
    return [NSLayoutConstraint constraintWithItem: scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view height:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: view
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (NSLayoutConstraint *)layoutConstraintToolbarBottomToToolboxView:(id)item toItem:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}
+ (NSLayoutConstraint *)layoutConstraintToolBoxViewBottom:(id)item toItem:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintToolBoxViewHeight:(id)toolbox height:(CGFloat)height {
    return toolbox != nil ? [NSLayoutConstraint constraintWithItem: toolbox
                                                         attribute: NSLayoutAttributeHeight
                                                         relatedBy: NSLayoutRelationEqual
                                                            toItem: nil
                                                         attribute: NSLayoutAttributeNotAnAttribute
                                                        multiplier: 1.000f
                                                          constant: height] : nil;
}

+ (NSLayoutConstraint *)layoutConstraintToolboxHeightHidden:(id)item {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 0.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintView:(id)view contentLeft:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeLeft
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeLeft
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintView:(UIView *)view contentRight:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintView:(UIView *)view contentTop:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintViewScroller:(id)scroller bottom:(id)bottom {
    return [NSLayoutConstraint constraintWithItem: scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: bottom
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintViewToolbarHeightHidden:(id)toolbar {
    return [NSLayoutConstraint constraintWithItem: toolbar
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

@end
