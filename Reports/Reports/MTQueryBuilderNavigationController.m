//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderNavigationController.h"

@implementation MTQueryBuilderNavigationController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    if ([UIDevice isLagacyOS]) {
        [[UINavigationBar appearanceWhenContainedIn: [self class], nil] setTintColor: [UIColor edaBlueDark]];
        [[UIToolbar appearanceWhenContainedIn: [self class], nil] setTintColor: [UIColor edaBlueDark]];
    }
}

@end