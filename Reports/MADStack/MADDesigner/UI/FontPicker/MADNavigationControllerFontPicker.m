//
//  MADNavigationControllerFontPicker.m
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationControllerFontPicker.h"
#import "MADFontSelectorViewController.h"

@implementation MADNavigationControllerFontPicker

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	BOOL hidden = ![self.visibleViewController isKindOfClass:[MADFontSelectorViewController class]];
	[self setNavigationBarHidden:hidden animated:NO];
	[self.visibleViewController.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.visibleViewController.view setNeedsLayout];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (self.isBeingDismissed) {
		[self setViewControllers:@[] animated:animated];
	}
}

@end
