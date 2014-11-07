//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

const NSInteger MADIndexQuery = 0;
const NSInteger MADIndexDesigner = 1;
const NSInteger MADIndexViewer = 2;

@interface MADTabBarController ()

@end

@implementation MADTabBarController

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.selectedViewController.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
