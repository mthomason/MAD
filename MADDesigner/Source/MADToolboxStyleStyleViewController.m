//
//  MADToolboxStyleStyleViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/29/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADToolboxStyleStyleViewController.h"

#import <UIKit/UINavigationController.h>

@implementation MADToolboxStyleStyleViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

@end
