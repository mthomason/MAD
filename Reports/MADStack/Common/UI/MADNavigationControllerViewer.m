//
//  MADNavigationControllerViewer.m
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerViewer.h"
#import "MADViewerController.h"

@interface MADNavigationControllerViewer ()
@end

@implementation MADNavigationControllerViewer

@synthesize document = _document;

- (void)dealloc {
    _viewControllerDelegate = nil;
    _document = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.viewControllers.count == 0) {
        id rootViewController = [MADViewerController newViewerController: _document];
        [self pushViewController:rootViewController animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

+ (UIImage *)newTabBarImage {
    return [MADViewerController newTabBarImage];
}

- (NSString *)title {
    return self.viewControllers.count > 0 ? self.viewControllers.firstObject.title : [MADViewerController Title];
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:animated completion:completion];
    NSArray *viewControllers = [[NSArray alloc] init];
    [self setViewControllers:viewControllers animated:animated];
}

@end
