//
//  MADTabBarNavigationController.m
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarNavigationController.h"

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADNavigationControllerViewer.h"

#import "MADTransparentPresentationController.h"

@interface MADTabBarNavigationController ()

@end

@implementation MADTabBarNavigationController

@synthesize document = _document;

+ (void)initialize {
    [super initialize];
    if (self == [MADTabBarNavigationController self]) {
        @autoreleasepool {
            NSArray<Class <UIAppearanceContainer>> * classes;
            UINavigationBar *appearanceProxy;
            
            classes = [[NSArray alloc] initWithObjects: self, nil];
            appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
            appearanceProxy.barTintColor = [UIColor clearColor];
        }
    }
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if ([vc conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        ((id <MADViewControllerDocumentProtocol>)vc).document = _document;
    }
    [super showViewController:vc sender:sender];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

//- (UITabBarItem *)tabBarItem {
//    [super tabBarItem];
//    UITabBarItem *tabBarItems;
//    UITabBarController *tabBarController = (UITabBarController *)self.topViewController;
//    tabBarItems = tabBarController.tabBarItem;
//    return tabBarItems;
//}

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
