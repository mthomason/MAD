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

@implementation MADNavigationController

@dynamic document;

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.topViewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
        NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
        ((id <MADocumentProtocol>)self.topViewController).document = self.document;
    }
    [self setNeedsStatusBarAppearanceUpdate];
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

- (UITabBarItem *)tabBarItem {
    return self.topViewController.tabBarItem;
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
    if (self.document != document) {
        self.document = document;
        for (UIViewController *viewController in self.viewControllers) {
            if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
                ((id <MADocumentProtocol>) viewController).document = document;
            }
        }
    }
}

@end
