//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNavigationController.h"

@implementation MTNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationBar] setBarStyle:UIBarStyleBlack];
    [[self navigationBar] setTranslucent:YES];
    NSMutableDictionary *titleTextAttributes = [[[self navigationBar] titleTextAttributes] mutableCopy];
    UIColor *whiteColor = [UIColor whiteColor];
    [titleTextAttributes setObject:whiteColor forKey:NSForegroundColorAttributeName];
    [[self navigationBar] setTitleTextAttributes:titleTextAttributes];
}

- (UITabBarItem *)tabBarItem {
    return [[self topViewController] tabBarItem];
}

@end
