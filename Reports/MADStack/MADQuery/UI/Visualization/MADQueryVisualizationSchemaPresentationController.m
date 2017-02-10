//
//  MADQueryVisualizationSchemaPresentationController.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationSchemaPresentationController.h"
#import <CoreData/NSManagedObjectID.h>
#import "MADHierarchicalDisplayModel.h"

@interface MADQueryVisualizationSchemaPresentationController ()

@end

@implementation MADQueryVisualizationSchemaPresentationController {
    int64_t _objectID;
}


- (instancetype)initWithObjectID:(int64_t)objectID
         presentedViewController:(UIViewController *)presentedViewController
        presentingViewController:(UIViewController *)presentingViewController {
    if (self = [super initWithPresentedViewController: presentedViewController
                             presentingViewController: presentingViewController]) {
        _objectID = objectID;
    }
    return self;
}

- (CGRect)frameOfPresentedViewInContainerView {
    return [self.delegatePresentation frameOfItemWithObjectID: _objectID];
}

- (BOOL)shouldPresentInFullscreen {
    return NO;
}

- (BOOL)shouldRemovePresentersView {
    return NO;
}

- (void)presentationTransitionWillBegin {
    [self.containerView addSubview:self.presentedViewController.view];
}

- (void)presentationTransitionDidEnd:(BOOL)completed { }

- (void)dismissalTransitionWillBegin { }

- (void)dismissalTransitionDidEnd:(BOOL)completed { }

@end
