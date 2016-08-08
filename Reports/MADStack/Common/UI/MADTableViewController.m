//
//  MADTableViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewController.h"
#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@interface MADTableViewController()

#include "MADViewControllerBaseInterfacePrivate.h"

@end

@implementation MADTableViewController

#include "MADViewControllerBase.m"

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.tableView.backgroundView setNeedsDisplay];
            [self.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        }];
    }
}

@end
