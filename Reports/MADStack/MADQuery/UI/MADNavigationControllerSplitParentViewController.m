//
//  MADNavigationControllerSplitParentViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerSplitParentViewController.h"
#import <UIKit/UINavigationBar.h>

@interface MADNavigationControllerSplitParentViewController ()

    @property (nonatomic, assign) BOOL firstTimeLayout;

@end

@implementation MADNavigationControllerSplitParentViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.hidesBarsWhenVerticallyCompact = NO;
        _firstTimeLayout = YES;
    }
    return self;
}

- (void)viewDidLoad {
    //NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];
}

#pragma mark - Navigation

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {

    [self setNavigationBarHidden:YES animated:animated];
    id result = [super popViewControllerAnimated:animated];;
    
    return result;
    
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController: viewController
                     animated: animated];
    [self setNavigationBarHidden: NO animated: animated];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id s = segue;
    id e = sender;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (_firstTimeLayout) {
        self.navigationBar.hidden = YES;
        _firstTimeLayout = NO;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.navigationBar.frame = CGRectMake(self.navigationBar.frame.origin.x,
                                          CGPointZero.y + self.topLayoutGuide.length,
                                          self.navigationBar.frame.size.width,
                                          self.navigationBar.frame.size.height);
}

@end
