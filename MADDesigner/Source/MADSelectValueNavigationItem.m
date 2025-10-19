//
//  MADSelectValueNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADSelectValueNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADSelectValueNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Select Value", @"Title for the select value screen. This is to static value to use to filter the report.");
		titleView.accessibilityHint = NSLocalizedString(@"Select a filter value.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Select Value", @"Title for the select value screen. This is to static value to use to filter the report.");
		self.leftItemsSupplementBackButton = YES;
		
	}
	return self;
}

@end
