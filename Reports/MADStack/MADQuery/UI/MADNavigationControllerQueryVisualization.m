//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerQueryVisualization.h"

@implementation MADNavigationControllerQueryVisualization

@synthesize document = _document;

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
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //for (UIViewController *viewController in self.viewControllers) {
    //    if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
    //        MADocument * __unsafe_unretained document = self.document;
    //        NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    //        ((id <MADViewControllerDocumentProtocol>)self.topViewController).document = document;
    //    }
    //}

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
