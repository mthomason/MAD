//
//  MADNavigationControllerFileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerFileExplorer.h"
#import "MADTransparentPresentationController.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIResponder.h>

@implementation MADNavigationControllerFileExplorer

+ (void)initialize {
    [super initialize];
    
    if (self != [MADNavigationControllerFileExplorer self]) return;
    
    Class thisClas = [MADTransparentPresentationController class];
    UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedIn:thisClas, nil];
    UIColor *clearColor = [UIColor clearColor];
    appearanceProxy.barTintColor = clearColor;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.toolbar.tintColor = [MADColorEverydayApps newColorWhite];
    self.toolbar.barTintColor = [MADColorEverydayApps newColorBlue];
    self.toolbar.barStyle = UIBarStyleBlack;
    self.toolbar.translucent = YES;
    self.navigationBar.translucent = YES;
    
    NSMutableDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    
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

@end
