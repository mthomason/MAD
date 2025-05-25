//
//  MADQueryNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIApplication.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import "MADQueryNavigationProtocol.h"

@implementation MADQueryNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = NSLocalizedString(@"MAD Query", @"Title for the store... list program features. ");
		titleView.accessibilityHint = NSLocalizedString(@"Design the query for your report.", @"Hint");
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		self.titleView = titleView;
		self.title = NSLocalizedString(@"MAD Query", @"Title for the store... list program features. ");
		self.leftItemsSupplementBackButton = YES;
		
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																					target: nil
																					action: @selector(done:)];
		UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
																					target: self
																					action: @selector(actionEdit:)];
		self.leftBarButtonItem = doneButton;
		self.rightBarButtonItem = editButton;
	}
	return self;
}

- (void)done:(nullable id)sender {
	@throw NSInternalInconsistencyException;
}

- (void)actionEdit:(nullable id)sender {
	UIBarButtonItem *editButton;
	editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
															   target: self
															   action: @selector(actionFinishEdit:)];
	[self setLeftBarButtonItem: nil animated: YES];
	[self setRightBarButtonItem: editButton animated: YES];
	[self.delegate edit:self];
}

- (void)actionFinishEdit:(nullable id)sender {
	UIBarButtonItem *editButton, *doneButton;
	doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
															   target: nil
															   action: @selector(done:)];
	editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
															   target: self
															   action: @selector(actionEdit:)];
	[self setLeftBarButtonItem: doneButton animated: YES];
	[self setRightBarButtonItem: editButton animated: YES];
	[self.delegate edit:self];
}

@end
