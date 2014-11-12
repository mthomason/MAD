//
//  MADFontPickerNavigationController.m
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFontPickerNavigationController.h"
#import "MADFontSelectorViewController.h"

@implementation MADFontPickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIViewController *visibleViewController = self.visibleViewController;
    if ([visibleViewController isKindOfClass:[MADFontSelectorViewController class]]) {
        [self setNavigationBarHidden:NO animated:NO];
    } else {
        [self setNavigationBarHidden:YES animated:NO];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

@end
