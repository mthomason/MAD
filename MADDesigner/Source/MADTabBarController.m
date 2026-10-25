//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTabBarController.h"
#import "MADNavigationController.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADThemeManager.h"

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UITabBarItem.h>

@interface MADTabBarController () <UITabBarControllerDelegate>

@end

@implementation MADTabBarController {
	BOOL _navigationItemInitialized;
	NSUInteger _lastSelectedIndex;
}

@synthesize document = _document;

+ (instancetype)newTabBarController:(MADocument *)document prompt:(NSString *)prompt {
	return [[UIStoryboard storyboardWithName: @"MADDesigner" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierTabBarController"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canResignFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(done:)) {
		return YES;
	}
	return NO;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		_navigationItemInitialized = NO;
		_lastSelectedIndex = NSNotFound;
	}
	return self;
}

- (void)setViewControllerDelegate:(id <MADViewControllerStandardProtocol>)delegate {
	if (_viewControllerDelegate != delegate) {
		_viewControllerDelegate = delegate;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[MADThemeManager applyAppearanceToTabBarController:self traitCollection:self.traitCollection];
	self.delegate = self;
	self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	self.modalPresentationStyle = UIModalPresentationOverFullScreen;
	[self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
		[MADThemeManager applyAppearanceToTabBarController:self traitCollection:self.traitCollection];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	MADocument *document = self.document;
	NSMutableArray <__kindof UIViewController *> *tabBarViewControllers = [[NSMutableArray <__kindof UIViewController *> alloc] initWithCapacity: 3];
	
	MADQueryBuilderSplitViewController *splitViewController =  [MADQueryBuilderSplitViewController newQueryBuilderSplitViewController:document];
	[tabBarViewControllers addObject: splitViewController];
	
	UINavigationController <MADViewControllerDocumentProtocol, MADNavigationProtocol> *navControllerDesigner = [UINavigationController documentNavigationControllerWithType:MADNavigationControllerTypeDesigner document:document];
	[tabBarViewControllers addObject: navControllerDesigner];
	
	UINavigationController <MADViewControllerDocumentProtocol, MADNavigationProtocol> *navControllerViewer = [UINavigationController documentNavigationControllerWithType:MADNavigationControllerTypeViewer document:document];
	[tabBarViewControllers addObject: navControllerViewer];

	id <MADViewControllerStandardProtocol> delegate = self.viewControllerDelegate;
	navControllerViewer.viewControllerDelegate = delegate;
	splitViewController.viewControllerDelegate = delegate;
	[self setViewControllers: tabBarViewControllers animated: animated];
}

- (void)viewWillTransitionToSize:(CGSize)size
	   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
	
	if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>__unused context) {
			[self.view setNeedsDisplay];
		};
	} else {
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>__unused context) { };
	}
	
	UIView *toView = [coordinator viewForKey:UITransitionContextToViewKey];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull __unused context) {
		[toView setNeedsDisplay];
	} completion: nil];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	UINavigationItem *navigationItem = self.navigationItem;
	if (navigationItem.leftBarButtonItem) {
		[navigationItem setLeftBarButtonItem: nil animated: animated];
	}
	if (navigationItem.rightBarButtonItem) {
		[navigationItem setRightBarButtonItem: nil animated: animated];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear: animated];
	[self setViewControllers: nil animated: animated];
	[self.navigationItem setLeftBarButtonItem:nil animated:animated];
	[self.navigationItem setRightBarButtonItem:nil animated:animated];;
}

/*- (id <UILayoutSupport>)topLayoutGuide {
	UINavigationController __weak *navigationController = self.navigationController;
	return navigationController.topLayoutGuide;
}*/

- (UIViewController *)childViewControllerForStatusBarHidden {
	return self.selectedViewController;
}

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

- (void)viewControllerDidFinish:(id)sender {
	[self.viewControllerDelegate viewControllerDidFinish: nil];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	
	if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
		id document = ((id <MADViewControllerDocumentProtocol>)tabBarController).document;
		if (document && [tabBarController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
			((id <MADViewControllerDocumentProtocol>)viewController).document = document;
		}
	}
	
	return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	const int8_t MADIndexQuery = 0;
	const int8_t MADIndexDesigner = 1;
	const int8_t MADIndexViewer = 2;

	_lastSelectedIndex = tabBarController.selectedIndex;
	switch (tabBarController.selectedIndex) {
		case MADIndexQuery:
			tabBarController.edgesForExtendedLayout = UIRectEdgeAll;
			break;
		case MADIndexDesigner:
			tabBarController.edgesForExtendedLayout = UIRectEdgeAll;
			break;
		case MADIndexViewer:
			tabBarController.edgesForExtendedLayout = UIRectEdgeBottom;
			break;
			
		default:
			break;
	}
}

- (nullable id <UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController
							   interactionControllerForAnimationController: (id <UIViewControllerAnimatedTransitioning>)animationController {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
					 animationControllerForTransitionFromViewController:(UIViewController *)fromVC
													   toViewController:(UIViewController *)toVC  {
	return nil;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	
	UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	
	UIView *containerView = transitionContext.containerView;
	UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
	UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
	CGRect fromFrame = [transitionContext initialFrameForViewController:fromViewController];
	CGRect toFrame = [transitionContext finalFrameForViewController:toViewController];
	CGVector offset = CGVectorMake(1.f, 0.f);

	fromView.frame = fromFrame;
	toView.frame = CGRectOffset(toFrame, toFrame.size.width * offset.dx * -1, toFrame.size.height * offset.dy * -1);
	[containerView addSubview:toView];
	
	NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
	[UIView animateWithDuration:transitionDuration animations:^{
		fromView.frame = CGRectOffset(fromFrame, fromFrame.size.width * offset.dx, fromFrame.size.height * offset.dy);
		toView.frame = toFrame;
	} completion:^(BOOL __unused finished) {
		BOOL wasCancelled = [transitionContext transitionWasCancelled];
		[transitionContext completeTransition:!wasCancelled];
	}];
}

#pragma mark -
#pragma mark Helpers

- (void)disableTabBarItems {
	NSArray *tabBarItems = self.tabBar.items;
	for (UITabBarItem *item in tabBarItems) {
		item.enabled = NO;
	}
}

- (void)enableTabBarItems {
	NSArray *tabBarItems = self.tabBar.items;
	for (UITabBarItem *item in tabBarItems) {
		item.enabled = YES;
	}
}

@end
