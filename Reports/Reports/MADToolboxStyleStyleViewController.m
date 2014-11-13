//
//  MADToolboxStyleStyleViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxStyleStyleViewController.h"

@interface MADToolboxStyleStyleViewController ()

@end

@implementation MADToolboxStyleStyleViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //UIViewController *vc = self.navigationController.parentViewController.navigationController;
    //vc.preferredContentSize = CGSizeMake(320.0000f, 280.0000f);
}

@end
