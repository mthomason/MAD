//
//  NSLayoutConstraint+QueryVisulization.m
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSLayoutConstraint+QueryVisualization.h"

@implementation NSLayoutConstraint (QueryVisualization)

+ (instancetype)schemaViewHeightForView:(UIView *)view andHeight:(CGFloat)height {
    NSLayoutConstraint *constraint = [self heightForView:view andHeight:height];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

+ (instancetype)schemaViewWidthForView:(UIView *)view andWidth:(CGFloat)width {
    NSLayoutConstraint *constraint = [self widthForView:view andWidth:width];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

+ (instancetype)heightForView:(UIView *)view andHeight:(CGFloat)height {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0000f
                                                                   constant:height];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

+ (instancetype)widthForView:(UIView *)view andWidth:(CGFloat)width {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0000f
                                                                   constant:width];
    constraint.priority = UILayoutPriorityDefaultHigh;
    return constraint;
}

@end
