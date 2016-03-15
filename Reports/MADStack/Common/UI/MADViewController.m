//
//  MADTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 11/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADViewController.h"

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

@interface MADCollectionViewController()

#include "MADViewControllerBaseInterfacePrivate.h"

@end

@implementation MADCollectionViewController

#include "MADViewControllerBase.m"

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.collectionView.backgroundView setNeedsDisplay];
            [self.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end

@interface MADSplitViewController()

#include "MADViewControllerBaseInterfacePrivate.h"

@end

@implementation MADSplitViewController

#include "MADViewControllerBase.m"

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end

@interface MADPageViewController()

#include "MADViewControllerBaseInterfacePrivate.h"

@end

@implementation MADPageViewController

#include "MADViewControllerBase.m"

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if (self.isViewLoaded) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.navigationItem.titleView sizeToFit];
        }];
    }
    
}

@end
