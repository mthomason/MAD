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

        UITableView *tableView;
        UINavigationItem *navigationItem;
        UIView __weak *backgroundView, __weak *titleView;
        
        
        tableView = self.tableView;
        navigationItem = self.navigationItem;
        backgroundView = tableView.backgroundView;
        titleView = navigationItem.titleView;
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [backgroundView setNeedsDisplay];
            [titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [titleView sizeToFit];
        }];

    }
}

@end
