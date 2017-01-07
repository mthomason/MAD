//
//  MADNavigationControllerFileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerFileExplorer.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIResponder.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADTransparentPresentationController.h"

@interface MADNavigationControllerFileExplorer ()

@end

@implementation MADNavigationControllerFileExplorer

+ (void)initialize {
    [super initialize];
    
    if (self == [MADNavigationControllerFileExplorer self]) {
        @autoreleasepool {
            
            NSArray <Class <UIAppearanceContainer>> *classes;
            Class thisClas = [MADTransparentPresentationController class];
            classes = [[NSArray alloc] initWithObjects: thisClas, nil];

            UINavigationBar *appearanceProxyNavigationBar;
            UIToolbar *appearanceProxyToolbar;

            appearanceProxyNavigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            appearanceProxyNavigationBar.barTintColor = [UIColor clearColor];
            appearanceProxyNavigationBar.translucent = YES;
            
            //NSMutableDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
            //titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];

            appearanceProxyToolbar = [UIToolbar appearanceWhenContainedInInstancesOfClasses: classes];
            appearanceProxyToolbar.barTintColor = [MADColorEverydayApps newColorBlue];
            appearanceProxyToolbar.tintColor    = [MADColorEverydayApps newColorWhite];
            appearanceProxyToolbar.barStyle = UIBarStyleBlack;
            appearanceProxyToolbar.translucent = YES;

            
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [self.navigationBar setTitleTextAttributes:titleTextAttributes];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source {
    UIPresentationController *result = nil;
    if (presented == self || presenting == self) {
        result = [[MADTransparentPresentationController alloc] initWithPresentedViewController:presented
                                                                      presentingViewController:presenting];
    }
    return result;
}

- (MADNavigationControllerType)controllerType {
    return MADNavigationControllerTypeFileExplorer;
}

@end
