//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNavigationController.h"
#import "UIColor+EverydayApps.h"

@implementation MTNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *whiteColor = [UIColor whiteColor];
    UIColor *barTintColor = [UIColor tintColorBlue];
    
    [[self toolbar] setBarTintColor:barTintColor];
    [[self toolbar] setBarStyle:UIBarStyleBlack];
    [[self toolbar] setTranslucent:YES];

    [[self navigationBar] setBarStyle:UIBarStyleBlack];
    [[self navigationBar] setTranslucent:YES];
    
    NSMutableDictionary *titleTextAttributes = [[[self navigationBar] titleTextAttributes] mutableCopy];
    titleTextAttributes[NSForegroundColorAttributeName] = whiteColor;
    [[self navigationBar] setTitleTextAttributes:titleTextAttributes];
}

- (UITabBarItem *)tabBarItem {
    return [[self topViewController] tabBarItem];
}

@end
