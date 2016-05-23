//
//  NSLayoutConstraint+QueryVisualization.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_NSLayoutConstraint_QueryVisualization_h
#define MAD_Designer_NSLayoutConstraint_QueryVisualization_h

#import <UIKit/NSLayoutConstraint.h>

@class UIView;

@interface NSLayoutConstraint (QueryVisualization)

    + (instancetype)newLayoutConstraintHeightForView:(UIView *)view andHeight:(CGFloat)height;
    + (instancetype)newLayoutConstraintWidthForView:(UIView *)view andWidth:(CGFloat)width;
    + (instancetype)newLayoutConstraintSchemaViewWidthForView:(UIView *)view andWidth:(CGFloat)width;
    + (instancetype)newLayoutConstraintSchemaViewHeightForView:(UIView *)view andHeight:(CGFloat)height;

@end

#endif
