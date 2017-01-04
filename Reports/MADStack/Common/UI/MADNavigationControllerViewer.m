//
//  MADNavigationControllerViewer.m
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationControllerViewer.h"
#import "MADViewerController.h"
#import <UIKit/UINavigationController.h>

@interface MADNavigationControllerViewer ()
    @property (nonatomic, strong) MADViewerController *viewerController;
@end

@implementation MADNavigationControllerViewer

@synthesize title = _title;

- (void)viewDidLoad {
    [super viewDidLoad];
    id rootViewController = [MADViewerController newViewerController: self.document];
    self.viewerController = rootViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self pushViewController:self.viewerController animated:animated];
    [self setNavigationBarHidden:YES animated:NO];
    [self setToolbarHidden:NO animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSArray *emptyArray = [[NSArray alloc] init];
    [self setViewControllers: emptyArray animated:animated];
    //[self popViewControllerAnimated: NO];
}

+ (UIImage *)newTabBarImage {
    return [MADViewerController newTabBarImage];
}

- (NSString *)title {
    if (_title == nil) {
        _title = self.viewerController == nil ?
                    [MADViewerController Title] : self.viewerController.title.copy;
    }
    return _title;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
