//
//  MADNavigationControllerToolbox.m
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerToolbox.h"
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarCommon.h>
#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import "MADToolboxViewController.h"

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

@end
