//
//  NSLayoutConstraint+QueryVisulization.m
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+QueryVisualization.h"

@implementation NSLayoutConstraint (QueryVisualization)

+ (instancetype)newLayoutConstraintHeightForView:(UIView *)view andHeight:(CGFloat)height {
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem: view
                                              attribute: NSLayoutAttributeHeight
                                              relatedBy: NSLayoutRelationEqual
                                                 toItem: nil
                                              attribute: NSLayoutAttributeNotAnAttribute
                                             multiplier: 1.0000f
                                               constant: height];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

+ (instancetype)newLayoutConstraintWidthForView:(UIView *)view andWidth:(CGFloat)width {
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem: view
                                              attribute: NSLayoutAttributeWidth
                                              relatedBy: NSLayoutRelationEqual
                                                 toItem: nil
                                              attribute: NSLayoutAttributeNotAnAttribute
                                             multiplier: 1.0000f
                                               constant: width];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

@end
