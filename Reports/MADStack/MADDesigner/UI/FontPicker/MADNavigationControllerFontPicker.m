//
//  MADNavigationControllerFontPicker.m
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerFontPicker.h"
#import "MADFontSelectorViewController.h"

@implementation MADNavigationControllerFontPicker

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.visibleViewController isKindOfClass:[MADFontSelectorViewController class]]) {
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

@end
