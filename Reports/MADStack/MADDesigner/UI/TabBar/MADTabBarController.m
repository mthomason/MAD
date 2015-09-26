//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

const NSInteger MADIndexQuery = 0;
const NSInteger MADIndexDesigner = 1;
const NSInteger MADIndexViewer = 2;

@interface MADTabBarController ()

@end

@implementation MADTabBarController

@synthesize document;

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
    NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
            ((id <MADocumentProtocol>)viewController).document = self.document;
        }
    }
    NSLog(@"\t%s\n%@\n%lu", __PRETTY_FUNCTION__, self.viewControllers, self.viewControllers.count);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
