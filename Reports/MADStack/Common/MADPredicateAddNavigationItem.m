//
//  MADPredicateAddNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPredicateAddNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADPredicateAddNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Add Predicate", @"Title for the add predicate screen. ");
		titleView.accessibilityHint = NSLocalizedString(@"Add a condition to your report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Add Predicate", @"Title for the add predicate screen. ");
		self.leftItemsSupplementBackButton = YES;
		
	}
	return self;
}

@end
