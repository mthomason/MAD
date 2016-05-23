//
//  MADCollectionViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewController.h"
#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

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
