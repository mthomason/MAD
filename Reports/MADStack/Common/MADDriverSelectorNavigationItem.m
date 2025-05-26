//
//  MADDriverSelectorNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDriverSelectorNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADDriverSelectorNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"New Report", @"Title of form that allows you to choose the name of a database field.");
		titleView.accessibilityHint = NSLocalizedString(@"Choose the type of connection to use.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.prompt = NSLocalizedString(@"Select database type.", @"Select database type.");
		self.titleView = titleView;
		self.title = NSLocalizedString(@"New Report", @"Title of form that allows you to choose the name of a database field.");
		self.leftItemsSupplementBackButton = YES;
	}
	return self;
}

@end
