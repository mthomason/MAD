//
//  MADNavigationControllerSplitParentViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerSplitParentViewController.h"
#import "MADQueryViewController.h"
#import "UIColor+EverydayApps.h"

@interface MADNavigationControllerSplitParentViewController ()

@end

@implementation MADNavigationControllerSplitParentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.hidden = YES;
//    [self setNavigationBarHidden:YES animated:NO];
    self.hidesBarsWhenVerticallyCompact = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {

    self.navigationBar.hidden = YES;
    return [super popViewControllerAnimated:animated];
    
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController: viewController
                     animated: animated];
    self.navigationBar.hidden = NO;
    //[self setNavigationBarHidden: NO
    //                    animated: animated];


}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { }

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    /*
    if ([self.visibleViewController isKindOfClass:[MADQueryViewController class]]) {
        if (self.navigationBarHidden != NO) {
            [self setNavigationBarHidden: YES
                                animated: YES];
        }
    } else {
        if (self.navigationBarHidden) {
            [self setNavigationBarHidden: NO
                                animated: YES];
        }
    }
     */
}

- (void)viewDidLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.navigationBar.frame = CGRectMake(self.navigationBar.frame.origin.x,
                                          CGPointZero.y + self.topLayoutGuide.length,
                                          self.navigationBar.frame.size.width,
                                          self.navigationBar.frame.size.height);
}


@end
