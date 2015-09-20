//
//  MADNavigationControllerSplitParentViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerSplitParentViewController.h"

@interface MADNavigationControllerSplitParentViewController ()

@end

@implementation MADNavigationControllerSplitParentViewController

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    //NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];
    self.navigationBar.hidden = YES;
    self.hidesBarsWhenVerticallyCompact = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { }

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.navigationBar.frame = CGRectMake(self.navigationBar.frame.origin.x,
                                          CGPointZero.y + self.topLayoutGuide.length,
                                          self.navigationBar.frame.size.width,
                                          self.navigationBar.frame.size.height);
}

@end
