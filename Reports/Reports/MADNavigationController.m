//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationController.h"
#import "MADTransparentPresentationController.h"
#import "UIColor+EverydayApps.h"


@implementation MADNavigationController

@synthesize document = _document;

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    [super viewDidLoad];
    NSLog(@"\tVC: %@", self.viewControllers);
    NSLog(@"\tTV: %@", self.topViewController);
    if ([self.topViewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
        NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
        ((id <MADocumentProtocol>)self.topViewController).document = self.document;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.toolbar.tintColor = [UIColor tintColorWhite];
    self.toolbar.barTintColor = [UIColor tintColorBlue];
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
    
    return foundViewController;
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
    if (document != _document) {
        _document = document;
        for (UIViewController *viewController in self.viewControllers) {
            if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
                ((id <MADocumentProtocol>) viewController).document = document;
            }
        }
    }
}

@end
