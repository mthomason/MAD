//
//  MTAutoLayoutTableViewCell.m
//  Reports
//
//  Created by Michael Thomason on 2/21/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAutoLayoutTableViewCell.h"

@implementation MTAutoLayoutTableViewCell

- (void)awakeFromNib {
    
    for (NSLayoutConstraint *constraint in [self constraints]) {

        [self removeConstraint:constraint];
        
        id firstItem = constraint.firstItem == self ? self.contentView : constraint.firstItem;
        id seccondItem = constraint.secondItem == self ? self.contentView : constraint.secondItem;
        
        NSLayoutConstraint* contentViewConstraint = [NSLayoutConstraint constraintWithItem: firstItem
                                                                                 attribute: constraint.firstAttribute
                                                                                 relatedBy: constraint.relation
                                                                                    toItem: seccondItem
                                                                                 attribute: constraint.secondAttribute
                                                                                multiplier: constraint.multiplier
                                                                                  constant: constraint.constant];
        
        [self.contentView addConstraint:contentViewConstraint];
    }
    [super awakeFromNib];
}

@end
