//
//  NSLayoutConstraint+QueryVisualization.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (QueryVisualization)

+ (instancetype)LayoutConstraintHeightForView:(UIView *)view andHeight:(CGFloat)height;
+ (instancetype)LayoutConstraintWidthForView:(UIView *)view andWidth:(CGFloat)width;
+ (instancetype)LayoutConstraintSchemaViewWidthForView:(UIView *)view andWidth:(CGFloat)width;
+ (instancetype)LayoutConstraintSchemaViewHeightForView:(UIView *)view andHeight:(CGFloat)height;

@end
