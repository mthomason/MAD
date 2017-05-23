//
//  MADLabel.m
//  MADCocoaExtensions
//
//  Created by Michael Thomason on 3/1/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabel.h"

@implementation MADLabel

+ (instancetype)newLabelDocumentCaption:(CGRect)frame width:(CGFloat)width {
    id label = [[self alloc] initWithFrame:frame];
    [label setClipsToBounds: NO];
    [label setNumberOfLines: 0];
    
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
