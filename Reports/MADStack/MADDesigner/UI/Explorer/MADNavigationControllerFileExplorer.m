//
//  MADNavigationControllerFileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerFileExplorer.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIResponder.h>

#import "MADAnimatedTransitioningNavigationCrossFadePop.h"
#import "MADAnimatedTransitioningNavigationCrossFadePush.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADTransparentPresentationController.h"

#import "MADExplorerNavigationBar.h"
#import "MADExplorerToolbar.h"
#import "MADExplorerController.h"

#import "MADExplorerAnimated.h"

@interface MADNavigationControllerFileExplorer ()

@property (weak, nonatomic) IBOutlet MADExplorerNavigationBar *fileExplorerNavigationBar;
@property (weak, nonatomic) IBOutlet MADExplorerToolbar *fileExplorerToolBar;

@end

@implementation MADNavigationControllerFileExplorer

+ (void)initialize {
    [super initialize];
    
    if (self == [MADNavigationControllerFileExplorer self]) {
        @autoreleasepool {
            
            NSArray <Class <UIAppearanceContainer>> *classes;
            classes = [[NSArray alloc] initWithObjects: [MADTransparentPresentationController class], nil];

            UINavigationBar *appearanceProxyNavigationBar;
            UIToolbar *appearanceProxyToolbar;

            appearanceProxyNavigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            appearanceProxyNavigationBar.barTintColor = [UIColor clearColor];
            appearanceProxyNavigationBar.translucent = YES;
            
            appearanceProxyToolbar = [UIToolbar appearanceWhenContainedInInstancesOfClasses: classes];
            appearanceProxyToolbar.barTintColor = [MADColorEverydayApps newColorBlue];
            appearanceProxyToolbar.tintColor    = [MADColorEverydayApps newColorWhite];
            appearanceProxyToolbar.barStyle = UIBarStyleBlack;
            appearanceProxyToolbar.translucent = YES;
            
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
/*    UIColor *white, *blue;
    white = [MADColorEverydayApps newColorWhite];
    blue = [MADColorEverydayApps newColorBlue];
    self.toolbar.tintColor = white;
    self.toolbar.barTintColor = blue;
    self.toolbar.barStyle = UIBarStyleBlack;
    self.toolbar.translucent = YES;
    self.navigationBar.translucent = YES;
    
    NSMutableDictionary *titleTextAttributes;
    titleTextAttributes = self.navigationBar.titleTextAttributes.mutableCopy;
    titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];*/
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    if (self.viewControllers.count == 1) {
        MADExplorerController *fileExplorer;
        fileExplorer = [MADExplorerController newExplorerController];
        [self pushViewController:fileExplorer animated:YES];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(done:)) {
        return YES;
    }
    return NO;
}

- (void)done:(id)sender {
    [self.viewControllers[1] done:sender];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (MADNavigationControllerType)controllerType {
    return MADNavigationControllerTypeFileExplorer;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MADExplorerController class]]) {
        [self setToolbarHidden: NO animated: animated];
    } else {
        [self setToolbarHidden: YES animated: animated];
    }
    
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated { }

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC  {

    id <UIViewControllerAnimatedTransitioning> animationController;
    BOOL toTabViewController = NO;
    BOOL toFileExplorferViewController = NO;
    if ((toFileExplorferViewController = [toVC isKindOfClass:[MADExplorerController class]]) ||
        (toTabViewController = [toVC isKindOfClass:[UITabBarController class]])) {
        toVC.modalPresentationStyle = UIModalPresentationCustom;
        
        switch (operation) {
            case UINavigationControllerOperationPush:
                animationController = [MADExplorerAnimated newFileExplorerAnimatedShowToolbar:toFileExplorferViewController
                                                                                      pushing:YES];
                break;

            case UINavigationControllerOperationPop:
                animationController = [MADExplorerAnimated newFileExplorerAnimatedShowToolbar:toFileExplorferViewController
                                                                                      pushing:NO];
                break;

            case UINavigationControllerOperationNone:
            default:
                break;
        }
    }
    return animationController;
}

@end
