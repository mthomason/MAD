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
    if (self == [MADNavigationControllerFileExplorer self]) {
        Class thisClas = [MADTransparentPresentationController class];
        UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedIn:thisClas, nil];
        UIColor *clearColor = [UIColor clearColor];
        appearanceProxy.barTintColor = clearColor;
    }
}

/*- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.topViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        ((id <MADViewControllerDocumentProtocol>)self.topViewController).document = self.document;
    }
    //[self setNeedsStatusBarAppearanceUpdate];
}*/

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

/*- (UITabBarItem *)tabBarItem {
    return ((UITabBarController *)self.topViewController).tabBarItem;
}*/

/*- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
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
}*/

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

/*- (IBAction)done:(id)sender {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController respondsToSelector:@selector(done:)]) {
            [viewController performSelectorOnMainThread: @selector(done:)
                                             withObject: self
                                          waitUntilDone: NO];
        }
    }
}*/

@end
