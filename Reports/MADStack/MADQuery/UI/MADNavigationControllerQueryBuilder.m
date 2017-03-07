//
//  MADNavigationControllerQueryBuilder.m
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerQueryBuilder.h"
#import <Foundation/NSObject.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIAppearance.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIResponder.h>

#import "MADViewControllerDocumentProtocol.h"

#import "MADQueryViewController.h"

#import "MADAnimatedTransitionControllerPop.h"
#import "MADAnimatedTransitionControllerPush.h"

@interface MADNavigationControllerQueryBuilder ()
    <UINavigationControllerDelegate>

@end

@implementation MADNavigationControllerQueryBuilder {
    BOOL _firstTimeLayout;
}

@synthesize document = _document;

- (void)dealloc {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)initialize {
    [super initialize];
    
    if (self == [MADNavigationControllerQueryBuilder self]) {
        @autoreleasepool {

        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _firstTimeLayout = YES;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBarsWhenVerticallyCompact = NO;
}

#pragma mark - Navigation

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    id result = [super popViewControllerAnimated:animated];;
    return result;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated {
    [super pushViewController: viewController
                     animated: animated];
    //[self setNavigationBarHidden: NO animated: animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self setNavigationBarHidden:YES animated:animated];
    [self setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*if (self.childViewControllers.count <= 0) {
        MADQueryViewController *madQueryViewController = [MADQueryViewController newQueryViewController:_document];
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationCustom;
        madQueryViewController.modalPresentationStyle = UIModalPresentationNone;
        madQueryViewController.providesPresentationContextTransitionStyle = YES;
        [self pushViewController:madQueryViewController animated:YES];
    }*/
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    for (UIViewController *vc in self.childViewControllers) {
        [vc.view setNeedsLayout];
    }// self.childViewControllers
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //self.navigationBar.frame = CGRectMake(self.navigationBar.frame.origin.x,
    //                                      CGPointZero.y + self.topLayoutGuide.length,
    //                                      self.navigationBar.frame.size.width,
    //                                      self.navigationBar.frame.size.height);
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    //[self.presentedViewController presentationTransitionWillBegin];
    //[super navigationController:navigationController
    //     willShowViewController:viewController
    //                   animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    //[super navigationController:navigationController
    //      didShowViewController:viewController
    //                   animated:animated];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController NS_AVAILABLE_IOS(7_0) {
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC  NS_AVAILABLE_IOS(7_0) {
    return [fromVC isKindOfClass:[MADQueryViewController class]] ? [[MADAnimatedTransitionControllerPush alloc] init] : [[MADAnimatedTransitionControllerPop alloc] init];
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
