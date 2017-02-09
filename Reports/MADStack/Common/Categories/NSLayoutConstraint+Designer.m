//
//  NSLayoutConstraint+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+Designer.h"

@implementation MADLayoutConstraint

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
                      marginTop:(CGFloat)marginTop heigh:(CGFloat)height {
    NSLayoutConstraint *constraint1,
                       *constraint2;
    constraint1 = [NSLayoutConstraint constraintWithItem: ruler
                                               attribute: NSLayoutAttributeHeight
                                               relatedBy: NSLayoutRelationEqual
                                                  toItem: nil
                                               attribute: NSLayoutAttributeNotAnAttribute
                                              multiplier: 1.0000f
                                                constant: height];
    
    constraint2 = [NSLayoutConstraint constraintWithItem: ruler
                                               attribute: NSLayoutAttributeTop
                                               relatedBy: NSLayoutRelationEqual
                                                  toItem: designer
                                               attribute: NSLayoutAttributeTop
                                              multiplier: 1.0000f
                                                constant: marginTop];
    
    return @[constraint1, constraint2];
}

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
                     sideMargin:(CGFloat)sideMargin {

    NSArray *constraints;
    NSLayoutConstraint *constraint3,
                       *constraint4;
    constraint3 = [NSLayoutConstraint constraintWithItem: ruler
                                               attribute: NSLayoutAttributeLeft
                                               relatedBy: NSLayoutRelationEqual
                                                  toItem: designer
                                               attribute: NSLayoutAttributeLeft
                                              multiplier: 1.0000f
                                                constant: sideMargin];
    
    constraint4 = [NSLayoutConstraint constraintWithItem: ruler
                                               attribute: NSLayoutAttributeRight
                                               relatedBy: NSLayoutRelationEqual
                                                  toItem: designer
                                               attribute: NSLayoutAttributeRight
                                              multiplier: 1.0000f
                                                constant: -sideMargin];
    constraints = [[NSArray alloc] initWithObjects:constraint3, constraint4, nil];
    return constraints;
}

+ (instancetype)newLayoutConstraintToolBoxView:(id)toolbox height:(CGFloat)height {
    id constraint = [NSLayoutConstraint constraintWithItem: toolbox
                                                 attribute: NSLayoutAttributeHeight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 1.000f
                                                  constant: height];
    return constraint;
}

+ (instancetype)newLayoutConstraintContent:(id)container width:(CGFloat)width {
    id constraint = [NSLayoutConstraint constraintWithItem: container
                                                 attribute: NSLayoutAttributeWidth
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 1.0000f
                                                  constant: width];
    return constraint;
}

+ (instancetype)newLayoutConstraintViewScrollerTop:(id)item view:(id)toItem {
    id constraint = [NSLayoutConstraint constraintWithItem: item
                                                 attribute: NSLayoutAttributeTop
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: toItem
                                                 attribute: NSLayoutAttributeTop
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height {
    id constraint = [NSLayoutConstraint constraintWithItem: label
                                                 attribute: NSLayoutAttributeHeight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 1.0000f
                                                  constant: height];
    return constraint;
}

+ (instancetype)newLayoutConstraintLabelBottom:(UIView *)label container:(UIView *)section
                                       padding:(CGFloat)padding {
    id constraint = [NSLayoutConstraint constraintWithItem: label
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: section
                                                 attribute: NSLayoutAttributeBottom
                                                multiplier: 1.0000f
                                                  constant: -padding];
    return constraint;
}

+ (instancetype)newLayoutConstraintLabelRight:(UIView *)label container:(UIView *)section
                                      padding:(CGFloat)padding {
    id constraint = [NSLayoutConstraint constraintWithItem: label
                                                 attribute: NSLayoutAttributeRight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: section
                                                 attribute: NSLayoutAttributeRight
                                                multiplier: 1.0000f
                                                  constant: -padding];
    return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view height:(CGFloat)height {
    id constraint = [NSLayoutConstraint constraintWithItem: view
                                                 attribute: NSLayoutAttributeHeight
                                                 relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 1.0000f
                                                  constant: height];
    return constraint;
}

+ (instancetype)newLayoutConstraintViewTop:(UIView *)item viewBottom:(UIView *)section
                                   padding:(CGFloat)padding {
    id constraint = [NSLayoutConstraint constraintWithItem: item
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: section
                                                 attribute: NSLayoutAttributeTop
                                                multiplier: 1.0000f
                                                  constant: -padding];
    return constraint;
}


+ (instancetype)newLayoutConstraintViewLeft:(UIView *)section content:(UIView *)content
                                    padding:(CGFloat)padding {
    id constraint = [NSLayoutConstraint constraintWithItem: section
                                                 attribute: NSLayoutAttributeLeft
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: content
                                                 attribute: NSLayoutAttributeLeft
                                                multiplier: 1.0000f
                                                  constant: padding];
    return constraint;
}

+ (instancetype)newLayoutConstraintViewRight:(UIView *)section content:(UIView *)content
                                     padding:(CGFloat)padding {
    id constraint = [NSLayoutConstraint constraintWithItem: section
                                                 attribute: NSLayoutAttributeRight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: content
                                                 attribute: NSLayoutAttributeRight
                                                multiplier: 1.0000f
                                                  constant: -padding];
    return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerBottom:(UIScrollView *)scroller {
    id constraint = [NSLayoutConstraint constraintWithItem: scroller
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: view
                                                 attribute: NSLayoutAttributeBottom
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintViewBottom:(id)item container:(id)toItem {
    id constraint = [NSLayoutConstraint constraintWithItem: item
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: toItem
                                                 attribute: NSLayoutAttributeTop
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintToolBoxBottom:(id)item container:(id)toItem {
    id constraint = [NSLayoutConstraint constraintWithItem: item
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: toItem
                                                 attribute: NSLayoutAttributeBottom
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintToolboxHeightHidden:(id)item {
    id constraint = [NSLayoutConstraint constraintWithItem: item
                                                 attribute: NSLayoutAttributeHeight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 0.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintView:(id)view containerLeft:(id)container {
    id constraint = [NSLayoutConstraint constraintWithItem: container
                                                 attribute: NSLayoutAttributeLeft
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: view
                                                 attribute: NSLayoutAttributeLeft
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerRight:(id)container {
    id constraint = [NSLayoutConstraint constraintWithItem: container
                                                 attribute: NSLayoutAttributeRight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: view
                                                 attribute: NSLayoutAttributeRight
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerTop:(id)container {
    id constraint = [NSLayoutConstraint constraintWithItem: container
                                                 attribute: NSLayoutAttributeTop
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: view
                                                 attribute: NSLayoutAttributeTop
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintScroller:(id)scroller bottom:(id)bottom {
    id constraint = [NSLayoutConstraint constraintWithItem: scroller
                                                 attribute: NSLayoutAttributeBottom
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: bottom
                                                 attribute: NSLayoutAttributeBottom
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

+ (instancetype)newLayoutConstraintToolbarHeightHidden:(id)toolbar {
    id constraint = [NSLayoutConstraint constraintWithItem: toolbar
                                                 attribute: NSLayoutAttributeHeight
                                                 relatedBy: NSLayoutRelationEqual
                                                    toItem: nil
                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                multiplier: 1.0000f
                                                  constant: 0.0000f];
    return constraint;
}

@end
