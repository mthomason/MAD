//
//  MADSelectOperatorNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADSelectOperatorNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADSelectOperatorNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Select Operator",
										   @"Title for the select operator screen. This is to "
										   @"select a mathmatical operator... like equal or greater "
										   @"than.");
		titleView.accessibilityHint = NSLocalizedString(@"Add a condition to your report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Select Operator",
									   @"Title for the select operator screen. This is to "
									   @"select a mathmatical operator... like equal or greater "
									   @"than.");
		self.leftItemsSupplementBackButton = YES;
		
	}
	return self;
}

@end
