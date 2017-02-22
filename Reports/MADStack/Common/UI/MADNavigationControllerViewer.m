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
    @property (nonatomic, strong) MADViewerController *viewerController;
@end

@implementation MADNavigationControllerViewer

@synthesize title = _title;
@synthesize document = _document;

- (void)viewDidLoad {
    [super viewDidLoad];
    id rootViewController = [MADViewerController newViewerController: _document];
    self.viewerController = rootViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.viewControllers.count == 0) {
        [self pushViewController:self.viewerController animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed) {
        NSArray *viewControllers = [[NSArray alloc] init];
        [self setViewControllers:viewControllers animated:animated];
    }
}

+ (UIImage *)newTabBarImage {
    return [MADViewerController newTabBarImage];
}

- (NSString *)title {
    if (_title == nil) {
        _title = self.viewerController == nil ?
                    [MADViewerController Title] : self.viewerController.title;
    }
    return _title;
}

- (void)setDocument:(MADocument *)document {
    if (_document != document) {
        _document = document;
    }
}

@end
