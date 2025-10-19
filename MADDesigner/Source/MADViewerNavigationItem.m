//
//  MADViewerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADViewerNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADViewerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"MAD Viewer", @"Title for the store... list program features. ");
		titleView.accessibilityHint = NSLocalizedString(@"View your report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = NSLocalizedString(@"MAD Viewer", @"Title for the store... list program features. ");
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
