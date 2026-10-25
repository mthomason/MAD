//
//  MADTransparentPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 10/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTransparentPresentationController.h"
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@implementation MADTransparentPresentationController

+ (void)initialize {
	[super initialize];
	if (self == [MADTransparentPresentationController self]) {
		@autoreleasepool {
			NSArray <Class <UIAppearanceContainer>> *classes = [[NSArray alloc] initWithObjects: [MADTransparentPresentationController class], nil];
			UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxy.barTintColor = [UIColor clearColor];
		}
	}
}

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
	if (self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController]) {
		
	}
	return self;
}

- (BOOL) shouldRemovePresentersView {
	return NO;
}

- (void)presentationTransitionWillBegin {
	[super presentationTransitionWillBegin];
}

@end
