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
    [self.visibleViewController.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.visibleViewController.view setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden {
    [super setNavigationBarHidden:navigationBarHidden];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [super setNavigationBarHidden:hidden animated:animated];
}

@end
