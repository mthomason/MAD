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

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    UIViewController *foundViewController;
    
    for (UIViewController *childViewController in self.viewControllers) {
        foundViewController = [childViewController viewControllerForUnwindSegueAction:action
                                                                   fromViewController:fromViewController
                                                                           withSender:sender];
        
        if (foundViewController) {
            break;
        }
    }
    
    if (!foundViewController) {
        foundViewController = [super viewControllerForUnwindSegueAction:action
                                                     fromViewController:fromViewController
                                                             withSender:sender];
    }
    
    return foundViewController;
}

@end
