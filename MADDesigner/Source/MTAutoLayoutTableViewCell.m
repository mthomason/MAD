//
//  MTAutoLayoutTableViewCell.m
//  Reports
//
//  Created by Michael Thomason on 2/21/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAutoLayoutTableViewCell.h"
#import <UIKit/UINibLoading.h>

@implementation MTAutoLayoutTableViewCell

- (void)awakeFromNib {
	
	for (__kindof NSLayoutConstraint *constraint in self.constraints) {
		@autoreleasepool {
			[self removeConstraint:constraint];
			id firstItem = constraint.firstItem == self ? self.contentView : constraint.firstItem;
			id seccondItem = constraint.secondItem == self ? self.contentView : constraint.secondItem;
			[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem: firstItem
																		 attribute: constraint.firstAttribute
																		 relatedBy: constraint.relation
																			toItem: seccondItem
																		 attribute: constraint.secondAttribute
																		multiplier: constraint.multiplier
																		  constant: constraint.constant]];
		}
	}
	
	[super awakeFromNib];
}

@end
