//
//  UINavigationControllerModelControllers.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UINavigationControllerQueryDesigner.h"
#import "UIColor+EverydayApps.h"

@implementation UINavigationControllerQueryDesigner

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [[UINavigationBar appearanceWhenContainedIn: [self class], nil] setTintColor: [UIColor edaBlueDark]];
    [[UIToolbar appearanceWhenContainedIn: [self class], nil] setTintColor: [UIColor edaBlueDark]];
}

@end