//
//  MADSelectFieldNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSelectFieldNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADSelectFieldNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Select Field", @"Title for the select field screen. ");
		titleView.accessibilityHint = NSLocalizedString(@"Select a field.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Select Field", @"Title for the select field screen. ");
		self.leftItemsSupplementBackButton = YES;
	}
	return self;
}

@end
