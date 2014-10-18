//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationController.h"

@interface MADQueryNavigationController ()

@property (nonatomic, weak) IBOutlet UINavigationController *mainViewController;
@property (nonatomic, weak) IBOutlet UIViewController *secondaryViewController;
@property (nonatomic, weak) UISplitViewController *splitViewController;

@end

@implementation MADQueryNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    UISplitViewController *splitViewController = (UISplitViewController *)self.topViewController;
    self.splitViewController = splitViewController;
    
    UINavigationController *leftViewController = splitViewController.viewControllers[0];
    self.mainViewController = leftViewController;
    
    UIViewController *rightViewController = splitViewController.viewControllers[1];
    self.secondaryViewController = rightViewController;
    
    UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular];
   // [self setOverrideTraitCollection:traitCollection forChildViewController:leftViewController];
}

@end
