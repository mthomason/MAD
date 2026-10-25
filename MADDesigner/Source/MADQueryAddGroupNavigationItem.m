//
//  MADQueryAddGroupNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/6/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryAddGroupNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@interface MADQueryAddGroupNavigationItem ()

@end

@implementation MADQueryAddGroupNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Add Group", @"Title for the add group screen. ");
		titleView.accessibilityHint = NSLocalizedString(@"Define a grouping the query and report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.leftBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
		self.rightBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
		self.backBarButtonItem.tintColor = [MADColorEverydayApps newColorWhite];
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Add Group", @"Title for the add group screen. ");
		self.leftItemsSupplementBackButton = YES;
	}
	return self;
}

@end
