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

@interface MADNavigationControllerToolbox ()
    <UINavigationBarDelegate, UIBarPositioningDelegate>
@end

@implementation MADNavigationControllerToolbox

+ (void)initialize {
    [super initialize];
    if (self != [MADNavigationControllerToolbox self])  return;
    [UINavigationBar appearanceWhenContainedIn:[MADNavigationControllerToolbox class], nil].barTintColor        = [UIColor clearColor];
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

@end
