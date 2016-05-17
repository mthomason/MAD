//
//  MTAutoLayoutTableViewCell.m
//  Reports
//
//  Created by Michael Thomason on 2/21/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAutoLayoutTableViewCell.h"
#import <UIKit/UINibLoading.h>

@implementation MTAutoLayoutTableViewCell

- (void)awakeFromNib {
    
    NSLayoutConstraint *contentViewConstraint;
     NSArray<__kindof NSLayoutConstraint *> *constraints = self.constraints;

    for (__kindof NSLayoutConstraint *constraint in constraints) {

        @autoreleasepool {

            [self removeConstraint:constraint];
            
            id firstItem = constraint.firstItem == self ?
                                self.contentView : constraint.firstItem;
            id seccondItem = constraint.secondItem == self ?
                                self.contentView : constraint.secondItem;
            
            contentViewConstraint = [NSLayoutConstraint constraintWithItem: firstItem
                                                                 attribute: constraint.firstAttribute
                                                                 relatedBy: constraint.relation
                                                                    toItem: seccondItem
                                                                 attribute: constraint.secondAttribute
                                                                multiplier: constraint.multiplier
                                                                  constant: constraint.constant];
            
            [self.contentView addConstraint:contentViewConstraint];
        }

    }

    [super awakeFromNib];
}

@end
