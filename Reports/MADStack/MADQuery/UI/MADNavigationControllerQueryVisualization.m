//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerQueryVisualization.h"
#import <UIKit/UIViewControllerTransitionCoordinator.h>

@implementation MADNavigationControllerQueryVisualization

@synthesize document = _document;

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) {
            [self.view setNeedsDisplay];
        };
    } else {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) { };
    }
    //UIView *toView = [coordinator viewForKey:UITransitionContextToViewKey];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        //[toView setNeedsDisplay];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setDocument:(MADocument *)document {
    if (document != _document) {
        _document = document;
        UIViewController *childViewController;
        NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
        for (childViewController in childViewControllers) {
            if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
                [((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
            }
        }
    }
}

@end
