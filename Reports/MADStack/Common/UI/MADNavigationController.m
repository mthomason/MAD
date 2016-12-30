//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationController.h"
#import "MADTransparentPresentationController.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>

@implementation MADNavigationController

@synthesize document = _document;

+ (void)initialize {
    if (self == [MADNavigationController self]) {
        Class thisClas = [MADTransparentPresentationController class];
        UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedIn:thisClas, nil];
        UIColor *clearColor = [UIColor clearColor];
        appearanceProxy.barTintColor = clearColor;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIColor *white, *blue;
    white = [MADColorEverydayApps newColorWhite];
    blue = [MADColorEverydayApps newColorBlue];
    self.toolbar.tintColor = white;
    self.toolbar.barTintColor = blue;
    self.toolbar.barStyle = UIBarStyleBlack;
    self.toolbar.translucent = YES;
    self.navigationBar.translucent = YES;

    NSMutableDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if ([vc conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        ((id <MADViewControllerDocumentProtocol>)vc).document = _document;
    }
    [super showViewController:vc sender:sender];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

- (UITabBarItem *)tabBarItem {
    UITabBarItem *tabBarItems;
    UITabBarController *tabBarController = (UITabBarController *)self.topViewController;
    tabBarItems = tabBarController.tabBarItem;
    return tabBarItems;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    UIViewController *foundViewController;
    
    for (UIViewController *childViewController in self.viewControllers) {
        foundViewController = [childViewController viewControllerForUnwindSegueAction: action
                                                                   fromViewController: fromViewController
                                                                           withSender: sender];
        
        if (foundViewController) {
            break;
        }
    }
    
    if (!foundViewController) {
        foundViewController = [super viewControllerForUnwindSegueAction: action
                                                     fromViewController: self
                                                             withSender: sender];
    }
    
    return [super viewControllerForUnwindSegueAction: action
                                  fromViewController: self
                                          withSender: sender];
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

- (IBAction)done:(id)sender {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController respondsToSelector:@selector(done:)]) {
            [viewController performSelectorOnMainThread: @selector(done:)
                                             withObject: self
                                          waitUntilDone: NO];
        }
    }
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

@end
