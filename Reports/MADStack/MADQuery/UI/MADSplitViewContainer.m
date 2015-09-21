//
//  MADSplitViewContainer.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/21/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADSplitViewContainer.h"
#import "MADQueryBuilderSplitViewController.h"
#import "UIStoryboard+Designer.h"

@interface MADSplitViewContainer ()

@property (nonatomic, strong) MADQueryBuilderSplitViewController *splitViewController;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@end

@implementation MADSplitViewContainer

@synthesize document = _document;

- (void)dealloc {
    _splitViewController = nil;
    [_containerView removeFromSuperview];
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
/*    for (UIViewController *viewController in self.childViewControllers) {
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
    [self dismissViewControllerAnimated:NO completion:NULL];*/
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIStoryboard *storyboard = [UIStoryboard Designer];
    MADQueryBuilderSplitViewController *splitViewController =  [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierQueryBuilderSplitViewController"];
    self.splitViewController = splitViewController;
    
}
- (void)viewWillAppear:(BOOL)animated {
    self.splitViewController.document = self.document;
    self.splitViewController.viewControllerDelegate = self.viewControllerDelegate;
    [super viewWillAppear:animated];
    [self.splitViewController willMoveToParentViewController:self];
    [self.containerView addSubview:self.splitViewController.view];
    [self addChildViewController:self.splitViewController];
    [self.splitViewController didMoveToParentViewController:self];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.splitViewController willMoveToParentViewController:nil];
    [self.splitViewController.view removeFromSuperview];
    [self.splitViewController removeFromParentViewController];
    [self.splitViewController didMoveToParentViewController:nil];
}

/*- (void)setDocument:(MADocument *)document {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
            ((id <MADocumentProtocol>)viewController).document = document;
        }
    }
}*/

/*- (void)setViewControllerDelegate:(id <MTViewControllerProtocol>)delegate {
    for (UIViewController *viewController in self.childViewControllers) {
        if ([viewController isKindOfClass:[MADQueryBuilderSplitViewController class]]) {
            ((MADQueryBuilderSplitViewController *)viewController).viewControllerDelegate = delegate;
        }
    }
}*/



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
        ((id <MADocumentProtocol>)segue.destinationViewController).document = self.document;
    }
    if ([segue.destinationViewController isKindOfClass:[MADQueryBuilderSplitViewController class]]) {
        ((MADQueryBuilderSplitViewController *)segue.destinationViewController).viewControllerDelegate = self.viewControllerDelegate;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
