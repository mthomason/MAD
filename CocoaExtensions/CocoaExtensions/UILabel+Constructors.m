//
//  UILabel+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UILabel+Constructors.h"

@implementation UILabel (Constructors)

+ (instancetype)documentCaption:(CGRect)frame width:(CGFloat)width {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.clipsToBounds = NO;
    label.numberOfLines = 0;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: label
                                                                  attribute: NSLayoutAttributeWidth
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: nil
                                                                  attribute: NSLayoutAttributeNotAnAttribute
                                                                 multiplier: 1.0000f
                                                                   constant: width];
    [label addConstraint:constraint];
    return label;
}

@end
