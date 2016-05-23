//
//  MADTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 11/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADViewController.h"

#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@interface MADViewController()

#include "MADViewControllerBaseInterfacePrivate.h"

@end

@implementation MADViewController

#include "MADViewControllerBase.m"

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];

    if (self.isViewLoaded) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end
