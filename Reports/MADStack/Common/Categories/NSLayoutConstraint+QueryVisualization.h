//
//  NSLayoutConstraint+QueryVisualization.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_NSLayoutConstraint_QueryVisualization_h
#define MAD_Designer_NSLayoutConstraint_QueryVisualization_h

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (QueryVisualization)

    + (instancetype)heightForView:(UIView *)view andHeight:(CGFloat)height;
    + (instancetype)widthForView:(UIView *)view andWidth:(CGFloat)width;
    + (instancetype)schemaViewWidthForView:(UIView *)view andWidth:(CGFloat)width;
    + (instancetype)schemaViewHeightForView:(UIView *)view andHeight:(CGFloat)height;

@end

#endif
