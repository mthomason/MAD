//
//  MADFieldSelectorNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFieldSelectorNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADFieldSelectorNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Select Field", @"Title of form that allows you to choose the name of a database field.");
		titleView.accessibilityHint = NSLocalizedString(@"Select a field.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Select Field", @"Title of form that allows you to choose the name of a database field.");
		self.leftItemsSupplementBackButton = YES;
		self.hidesBackButton = NO;
	}
	return self;
}

@end
