//
//  MADTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 11/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADViewController.h"

@implementation MADViewController

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];

    if (self.isViewLoaded) {
        __weak UIViewController *weakself = self;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end

@implementation MADTableViewController

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];

    if (self.isViewLoaded) {
        __weak UITableViewController *weakself = self;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.tableView.backgroundView setNeedsDisplay];
            [weakself.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end

@implementation MADCollectionViewController

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        __weak UICollectionViewController *weakself = self;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.collectionView.backgroundView setNeedsDisplay];
            [weakself.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end

@implementation MADSplitViewController

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        __weak UISplitViewController *weakself = self;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [weakself.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end
