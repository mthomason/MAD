//
//  NSLayoutConstraint+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+Designer.h"

@implementation NSLayoutConstraint (Designer)

+ (NSArray *)ruler:(MTRulerView *)ruler designer:(UIView *)designer marginTop:(CGFloat)marginTop heigh:(CGFloat)height {
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

+ (NSArray *)ruler:(MTRulerView *)ruler designer:(UIView *)designer sideMargin:(CGFloat)sideMargin {
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

+ (instancetype)toolBoxView:(id)toolbox height:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: toolbox
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.000f
                                         constant: height];
}

+ (instancetype)content:(id)container width:(CGFloat)width {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeWidth
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: width];
}

+ (instancetype)viewScrollerTop:(id)item view:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)label:(UIView *)label toHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (instancetype)labelBottom:(UIView *)label container:(UIView *)section padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: -padding];
}

+ (instancetype)labelRight:(UIView *)label container:(UIView *)section padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: -padding];
}

+ (instancetype)view:(UIView *)view height:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: view
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (instancetype)viewTop:(UIView *)item viewBottom:(UIView *)section padding:(CGFloat)padding {
    return  [NSLayoutConstraint constraintWithItem: item
                                         attribute: NSLayoutAttributeBottom
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: section
                                         attribute: NSLayoutAttributeTop
                                        multiplier: 1.0000f
                                          constant: -padding];
}


+ (instancetype)viewLeft:(UIView *)section content:(UIView *)content padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: section
                                        attribute: NSLayoutAttributeLeft
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: content
                                        attribute: NSLayoutAttributeLeft
                                       multiplier: 1.0000f
                                         constant: padding];
}

+ (instancetype)viewRight:(UIView *)section content:(UIView *)content padding:(CGFloat)padding {
    return [NSLayoutConstraint constraintWithItem: section
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: content
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: -padding];
}

+ (instancetype)view:(UIView *)view containerBottom:(UIScrollView *)scroller {
    return [NSLayoutConstraint constraintWithItem: scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)viewBottom:(id)item container:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)toolBoxBottom:(id)item container:(id)toItem {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: toItem
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)toolboxHeightHidden:(id)item {
    return [NSLayoutConstraint constraintWithItem: item
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 0.0000f
                                         constant: 0.0000f];
}

+ (instancetype)view:(id)view containerLeft:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeLeft
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeLeft
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)view:(UIView *)view containerRight:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)view:(UIView *)view containerTop:(id)container {
    return [NSLayoutConstraint constraintWithItem: container
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)scroller:(id)scroller bottom:(id)bottom {
    return [NSLayoutConstraint constraintWithItem: scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: bottom
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (instancetype)toolbarHeightHidden:(id)toolbar {
    return [NSLayoutConstraint constraintWithItem: toolbar
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

@end
