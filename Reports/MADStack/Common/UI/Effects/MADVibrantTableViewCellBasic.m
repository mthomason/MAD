//
//  MADVibrantTableViewCellBasic.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellBasic.h"

@implementation MADVibrantTableViewCellBasic

- (void)updateConstraints {
    
    NSLayoutConstraint *minHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                 attribute: NSLayoutAttributeHeight
                                                                 relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                    toItem: nil
                                                                 attribute: NSLayoutAttributeNotAnAttribute
                                                                multiplier: 1.0
                                                                  constant: 44.0];
    [self.contentView addConstraint:minHeight];
    
        
    [super updateConstraints];
    
}

@end
