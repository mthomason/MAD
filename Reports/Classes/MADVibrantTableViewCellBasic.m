//
//  MADVibrantTableViewCellBasic.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellBasic.h"

@implementation MADVibrantTableViewCellBasic

- (void)updateConstraints {
    
    NSLayoutConstraint *minHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                 attribute: NSLayoutAttributeHeight
                                                                 relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                    toItem: nil
                                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                                multiplier: 1.0000f
                                                                  constant: 44.0000f];
    [self.contentView addConstraint:minHeight];
    
        
    [super updateConstraints];
    
}

@end
