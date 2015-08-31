//
//  NSLayoutConstraint+QueryVisulization.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (QueryVisulization)

+ (instancetype)schemaViewWidthForView:(UIView *)view andWidth:(CGFloat)width;
+ (instancetype)schemaViewHeightForView:(UIView *)view andHeight:(CGFloat)height;

@end
