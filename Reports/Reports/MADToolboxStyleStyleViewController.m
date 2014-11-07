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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    [self.tableView setContentOffset:CGPointMake(CGPointZero.x, CGPointZero.y + self.topLayoutGuide.length) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    [super viewWillAppear:animated];
}



@end
