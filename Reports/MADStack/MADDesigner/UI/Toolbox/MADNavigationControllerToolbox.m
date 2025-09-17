//
//  MADNavigationControllerToolbox.m
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADNavigationControllerToolbox.h"
#import "MADToolboxViewController.h"
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarCommon.h>
#import <UIKit/UIViewControllerTransitionCoordinator.h>

@interface MADNavigationControllerToolbox () <UINavigationBarDelegate, UIBarPositioningDelegate>
@end

@implementation MADNavigationControllerToolbox

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (MADNavigationControllerType)controllerType {
	return MADNavigationControllerTypeToolbox;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (CGSize)preferredContentSize {
	return self.viewControllers.firstObject.preferredContentSize;
}

@end
