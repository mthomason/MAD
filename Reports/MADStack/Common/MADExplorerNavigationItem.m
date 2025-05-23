//
//  MADExplorerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADExplorerNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADExplorerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"MAD Designer", @"MAD Designer");
		titleView.accessibilityHint = NSLocalizedString(@"MAD Designer is the mobile analytics document designer.", @"MAD Designer is the mobile analytics document designer.");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"MAD Designer", @"MAD Designer");
		self.hidesBackButton = YES;
	}
	return self;
}

@end
