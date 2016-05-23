//
//  MADToolboxStyleStyleViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxStyleStyleViewController.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@implementation MADToolboxStyleStyleViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

@end
