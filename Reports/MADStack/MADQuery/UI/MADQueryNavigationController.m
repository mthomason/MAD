//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationController.h"

@implementation MADQueryNavigationController

- (void)dealloc {
/*    for (UIViewController *controller in self.viewControllers) {
        if ([controller isKindOfClass:[UISplitViewController class]]) {
            for (UIViewController *childViewController in ((UISplitViewController *) controller).childViewControllers) {
                [childViewController willMoveToParentViewController:nil];
                [childViewController.view removeFromSuperview];
                [childViewController removeFromParentViewController];
                [childViewController didMoveToParentViewController:nil];
            }
            
        }
    }
    [self popViewControllerAnimated:NO];*/
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
            NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
            ((id <MADocumentProtocol>)self.topViewController).document = self.document;
        }
    }

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

@end
