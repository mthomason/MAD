//
//  MADDesignerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerNavigationItem.h"
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <UIKit/UIAccessibility.h>

@implementation MADDesignerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"MAD Designer", @"Title for the store... list program features. ");
		titleView.accessibilityHint = NSLocalizedString(@"Design the layout for your report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"MAD Designer", @"Title for the store... list program features. ");
		self.leftItemsSupplementBackButton = YES;
		
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																					target: nil
																					action: @selector(done:)];
		self.leftBarButtonItem = doneButton;
	}
	return self;
}

- (void)done:(nullable id)sender {
	@throw NSInternalInconsistencyException;
}

@end
