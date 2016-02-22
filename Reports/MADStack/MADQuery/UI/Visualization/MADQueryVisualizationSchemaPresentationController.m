//
//  MADQueryVisualizationSchemaPresentationController.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationSchemaPresentationController.h"
#import <CoreData/NSManagedObjectID.h>
#import "MADQueryVisualizationTableDefination.h"

@interface MADQueryVisualizationSchemaPresentationController ()

    @property (nonatomic, copy) NSManagedObjectID *objectID;

@end

@implementation MADQueryVisualizationSchemaPresentationController

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
         presentedViewController:(UIViewController *)presentedViewController
        presentingViewController:(UIViewController *)presentingViewController {
    if (self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController]) {
        self.objectID = objectID.copy;
    }
    return self;
}

- (CGRect)frameOfPresentedViewInContainerView {
    return [self.delegatePresentation frameOfItemWithObjectID: self.objectID];
}

- (BOOL)shouldPresentInFullscreen {
    return NO;
}

- (BOOL)shouldRemovePresentersView {
    return NO;
}

- (void)presentationTransitionWillBegin {
    [self.containerView addSubview:self.presentedViewController.view]; }

- (void)presentationTransitionDidEnd:(BOOL)completed { }

- (void)dismissalTransitionWillBegin { }

- (void)dismissalTransitionDidEnd:(BOOL)completed { }

@end
