//
//  MADPredicateFormatNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 3/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPredicateFormatNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADPredicateFormatNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"Predicate Format", @"Title for the predicate format screen.");
		titleView.accessibilityHint = NSLocalizedString(@"What type of predicate would you like to use?", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"Predicate Format", @"Title for the predicate format screen.");
		self.leftItemsSupplementBackButton = YES;
		
	}
	return self;
}

@end
