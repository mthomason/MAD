//
//  MADNavigationControllerToolbox.m
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerToolbox.h"
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarCommon.h>
#import "MADTransparentPresentationController.h"

@interface MADNavigationControllerToolbox ()
    <UINavigationBarDelegate, UIBarPositioningDelegate>
@end

@implementation MADNavigationControllerToolbox

+ (void)initialize {
    [super initialize];
    if (self == [MADNavigationControllerToolbox self]) {
        @autoreleasepool {
            NSArray <Class <UIAppearanceContainer>> *classes;
            UINavigationBar <UIAppearance> *appearanceProxy;
            classes = [[NSArray <Class <UIAppearanceContainer>> alloc] initWithObjects: self, nil];
            appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
            appearanceProxy.barTintColor = [UIColor clearColor];
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (MADNavigationControllerType)controllerType {
    return MADNavigationControllerTypeToolbox;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
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
