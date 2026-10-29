//
//  MADExplorerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADExplorerNavigationItem.h"
#import <MADFoundation/MADApplication.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <UIKit/UIAccessibility.h>

@implementation MADExplorerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
#if MAD_VIEWER
		BOOL isViewer = YES;
#else
		BOOL isViewer = [MADApplication isMADViewer];
#endif
		NSString *title = isViewer
			? NSLocalizedString(@"MAD Viewer", @"MAD Viewer")
			: NSLocalizedString(@"MAD Designer", @"MAD Designer");
		NSString *hint = isViewer
			? NSLocalizedString(@"MAD Viewer is the mobile analytics document viewer.", @"MAD Viewer is the mobile analytics document viewer.")
			: NSLocalizedString(@"MAD Designer is the mobile analytics document designer.", @"MAD Designer is the mobile analytics document designer.");

		MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
		titleView.text = title;
		titleView.accessibilityHint = hint;
		titleView.accessibilityTraits = UIAccessibilityTraitHeader;
		
		self.titleView = titleView;
		self.title = title;
		self.hidesBackButton = YES;
	}
	return self;
}

@end
