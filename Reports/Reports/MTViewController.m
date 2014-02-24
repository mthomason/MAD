//
//  MUIViewController.m
//  Reports
//
//  Created by Michael Thomason on 10/31/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewController.h"
#import "UIColor+EverydayApps.h"

@implementation MTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *barTintColor = [UIColor tintColor];
    UIColor *tintColor = [UIColor tintColor2];
    UIToolbar *toolbar = [[self navigationController] toolbar];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
