//
//  MADTableViewCellAuto.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTableViewCellAuto.h"
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>

@interface MADTableViewCellAuto ()

@property (atomic, assign) BOOL initalSetupComplete;

@end

@implementation MADTableViewCellAuto

- (void)awakeFromNib {
    self.accessoryType = UITableViewCellAccessoryNone;
    [self initialize];
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, 320.0, 320.0);
		UILabel *label = [[UILabel alloc] initWithFrame:rect];

		label.textColor = [UIColor labelColor];
		label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		[self.contentView addSubview:label];
		self.accessoryView.tintColor = [UIColor labelColor];

		[label setContentCompressionResistancePriority:500
											   forAxis:UILayoutConstraintAxisHorizontal];
		[label setContentHuggingPriority:UILayoutPriorityDefaultLow
								 forAxis:UILayoutConstraintAxisHorizontal];

		label.numberOfLines = 0;
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.userInteractionEnabled = NO;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		self.userInteractionEnabled = YES;
		self.label = label;
		self.label.translatesAutoresizingMaskIntoConstraints = NO;
		self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
		self.contentView.translatesAutoresizingMaskIntoConstraints = YES;

		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)layoutIfNeeded {
	[super layoutIfNeeded];
}

- (void)updateConstraintsIfNeeded {
	[super updateConstraintsIfNeeded];
}

- (void)initialize {
	self.initalSetupComplete = NO;
	self.updatingConstraints = NO;
}

- (void)updateConstraints {
	if (self.updatingConstraints == NO && self.label != nil) {
		self.updatingConstraints = YES;

		if (self.layoutConstraints.count > 0) {
			[self.contentView removeConstraints:self.layoutConstraints];
		}

		NSLayoutConstraint *effectsHeight = [NSLayoutConstraint constraintWithItem:self.contentView
																		 attribute:NSLayoutAttributeHeight
																		 relatedBy:NSLayoutRelationGreaterThanOrEqual
																			toItem:self.label
																		 attribute:NSLayoutAttributeHeight
																		multiplier:1.0
																		  constant:20.0];

		NSLayoutConstraint *layoutConstraintLabelLeadingMargin = [NSLayoutConstraint constraintWithItem:self.contentView
																							  attribute:NSLayoutAttributeLeading
																							  relatedBy:NSLayoutRelationEqual
																								 toItem:self.label
																							  attribute:NSLayoutAttributeLeading
																							 multiplier:1.0
																							   constant:-18.0];
		layoutConstraintLabelLeadingMargin.priority = UILayoutPriorityDefaultHigh;

		NSLayoutConstraint *layoutConstraintLabelTrailing = [NSLayoutConstraint constraintWithItem:self.contentView
																						 attribute:NSLayoutAttributeTrailing
																						 relatedBy:NSLayoutRelationEqual
																							toItem:self.label
																						 attribute:NSLayoutAttributeTrailing
																						multiplier:1.0
																						  constant:18.0];
		layoutConstraintLabelTrailing.priority = UILayoutPriorityDefaultHigh;

		NSLayoutConstraint *layoutConstraintLabelTop = [NSLayoutConstraint constraintWithItem:self.contentView
																					attribute:NSLayoutAttributeTop
																					relatedBy:NSLayoutRelationEqual
																					   toItem:self.label
																					attribute:NSLayoutAttributeTop
																				   multiplier:1.0
																					 constant:-10.0];
		layoutConstraintLabelTop.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *layoutConstraintLabelBottom = [NSLayoutConstraint constraintWithItem:self.contentView
																					   attribute:NSLayoutAttributeBottom
																					   relatedBy:NSLayoutRelationEqual
																						  toItem:self.label
																					   attribute:NSLayoutAttributeBottom
																					  multiplier:1.0
																						constant:10.0];
		layoutConstraintLabelBottom.priority = UILayoutPriorityDefaultHigh;

		NSArray *constraints = @[effectsHeight, layoutConstraintLabelTop, layoutConstraintLabelBottom, layoutConstraintLabelLeadingMargin, layoutConstraintLabelTrailing];
		self.layoutConstraints = constraints;
		[self.contentView addConstraints:constraints];
		self.initalSetupComplete = YES;
		self.updatingConstraints = NO;
	}
	[super updateConstraints];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	if (self.accessoryView != nil) {
		self.accessoryView.tintColor = [UIColor labelColor];
	}
}

@end
