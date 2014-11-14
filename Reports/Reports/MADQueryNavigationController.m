//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationController.h"
#import "UIColor+EverydayApps.h"

@interface MADQueryNavigationController ()

@property (nonatomic, weak) IBOutlet UINavigationController *mainViewController;
@property (nonatomic, weak) IBOutlet UIViewController *secondaryViewController;
@property (nonatomic, weak) UISplitViewController *splitViewController;

@end

@implementation MADQueryNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNavigationBarHidden:NO];
    UISplitViewController *splitViewController = (UISplitViewController *)self.topViewController;
    self.splitViewController = splitViewController;
    
    UINavigationController *leftViewController = splitViewController.viewControllers[0];
    self.mainViewController = leftViewController;
    
    UIViewController *rightViewController = splitViewController.viewControllers[1];
    self.secondaryViewController = rightViewController;
    
   // UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular];
   // [self setOverrideTraitCollection:traitCollection forChildViewController:leftViewController];
    
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.navigationBar.frame = CGRectMake(self.navigationBar.frame.origin.x, CGPointZero.y + self.topLayoutGuide.length, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
}

- (void)viewDidLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
