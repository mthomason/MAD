//
//  MADStoreNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStoreNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADStoreNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"MAD Features", @"Title for the store... list program features. ");
		titleView.accessibilityHint = NSLocalizedString(@"Choose a feature to purchase.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		self.titleView = titleView;
		self.title = NSLocalizedString(@"MAD Features", @"Title for the store... list program features. ");
		self.leftItemsSupplementBackButton = YES;
	}
	return self;
}

@end
