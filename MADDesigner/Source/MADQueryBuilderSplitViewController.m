//
//  MADQueryBuilderContainerController.m
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MADQueryVisualizationViewController.h"
#import "MADNavigationControllerQueryBuilder.h"
#import "MADNavigationControllerQueryVisualization.h"

#import <MAD/MADocument.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIImage.h>

@interface MADQueryBuilderSplitViewController () <UISplitViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSQL;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemDisplayToggle;

@property (nonatomic, assign) BOOL localEditing;
@property (nonatomic, assign) BOOL setupDetail;
@property (nonatomic, assign) BOOL setupInitalLayout;

@property (readonly, nonatomic, strong) MADNavigationControllerQueryVisualization *secondaryNavigationController;
@property (readonly, nonatomic, strong) MADNavigationControllerQueryBuilder *primaryNavigationController;
@property (readonly, nonatomic, strong) MADQueryVisualizationViewController *secondaryViewController;
@property (readonly, nonatomic, strong) MADQueryViewController *primaryViewController;

@end

@implementation MADQueryBuilderSplitViewController

@synthesize document = _document, title = _title;
@dynamic primaryViewController, secondaryViewController, primaryNavigationController, secondaryNavigationController;

+ (instancetype)newQueryBuilderSplitViewController:(MADocument *)document {
	id controller = [[UIStoryboard storyboardWithName: @"MADQuery" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MADIdentifierQueryBuilderSplitViewController"];
	[((typeof(self))controller) setDocument: document];
	return controller;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if (self = [super initWithCoder:aDecoder]) {
		
		_setupDetail = NO;
		_setupInitalLayout = NO;
		_localEditing = NO;
		self.delegate = self;
		
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	if (!_setupInitalLayout) {
		_setupInitalLayout = YES;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	NSArray *toolbarItems = [[NSArray alloc] initWithObjects:_barButtonItemSQL, nil];
	[self setToolbarItems:toolbarItems animated:animated];
	[self.secondaryNavigationController setToolbarItems:toolbarItems animated:animated];
}

+ (NSString *)Title {
	return [[NSString alloc] initWithFormat: @"MAD %@", NSLocalizedString(@"Query", @"Query")];
}

- (NSString *)title {
	if (_title == nil) {
		_title = [self.class Title];
	}
	return _title;
}

- (MADNavigationControllerQueryBuilder *)primaryNavigationController {
	return self.viewControllers.firstObject;
}

- (MADNavigationControllerQueryVisualization *)secondaryNavigationController {
	return self.viewControllers.lastObject;
}

- (MADQueryViewController *)primaryViewController {
	return self.viewControllers.firstObject.childViewControllers[0];
}

- (MADQueryVisualizationViewController *)secondaryViewController {
	return self.viewControllers.lastObject.childViewControllers[0];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)layoutForUnlicensedUser:(NSNumber *)animated {
	UIBarButtonItem *barButtonItemRevealQuery = nil;
	BOOL animate = animated.boolValue;
	NSArray<__kindof UIBarButtonItem *> *toolbarItemsFull = self.toolbarItems;
	NSMutableArray<__kindof UIBarButtonItem *> *toolbarItemsLimited = toolbarItemsFull.mutableCopy;
	toolbarItemsFull = nil;
	
	if (barButtonItemRevealQuery != nil) {
		[toolbarItemsLimited removeObject:barButtonItemRevealQuery];
	}
	
	[self setToolbarItems: toolbarItemsLimited animated: animate];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if (sender == self) {
		MADocument *document = self.document;
		[(segue.destinationViewController) setDocument: document];
		[segue.destinationViewController reloadMainDocumentAnimated:YES];
	}
}

- (IBAction)showReportDocumentList:(id)sender {
	[self.viewControllerDelegate viewControllerDidFinish:self];
}

- (IBAction)redrawQueryVisualization:(id)sender {
	[self.secondaryViewController redraw: YES];
}

- (IBAction)edit:(id)sender {
	self.localEditing = !self.localEditing;
	[self.primaryViewController edit:sender];
	[self setEditing:self.localEditing animated:YES];
}

- (void)viewControllerDidFinish:(id)sender {
	__block id <MADViewControllerStandardProtocol> viewControllerDelegate = _viewControllerDelegate;
	BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue] != NO;
	[self dismissViewControllerAnimated:YES completion:^{
		if (procDelegateFunction) {
			[viewControllerDelegate viewControllerDidFinish:nil];
		}
		viewControllerDelegate = nil;
	}];
	_viewControllerDelegate = nil;
}

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)TabBarImage {
	return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
}

#pragma mark - UISplitViewControllerDelegate

// This method allows a client to update any bar button items etc.
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
	switch (displayMode) {
		case UISplitViewControllerDisplayModeAutomatic:
		case UISplitViewControllerDisplayModeSecondaryOnly:
		case UISplitViewControllerDisplayModeOneBesideSecondary:
		case UISplitViewControllerDisplayModeOneOverSecondary:
		case UISplitViewControllerDisplayModeTwoBesideSecondary:
		case UISplitViewControllerDisplayModeTwoOverSecondary:
		case UISplitViewControllerDisplayModeTwoDisplaceSecondary:
		default:
			break;
	}
}

- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc {
	return UISplitViewControllerDisplayModeOneBesideSecondary;
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
	Protocol *documentProtocol = @protocol(MADViewControllerDocumentProtocol);
	if ([vc conformsToProtocol: documentProtocol]) {
		[(id <MADViewControllerDocumentProtocol>)vc setDocument:_document];
	}
	[super showViewController:vc sender:sender];
}

- (BOOL)splitViewController: (UISplitViewController *)splitViewController
		 showViewController: (UIViewController *)vc
					 sender: (id)sender {
	
	Protocol *viewControllerDocumentProtocol = @protocol(MADViewControllerDocumentProtocol);
	if ([vc conformsToProtocol: viewControllerDocumentProtocol]) {
		[(id <MADViewControllerDocumentProtocol>)vc setDocument:_document];
	}
	[self.navigationController presentViewController:vc animated:YES completion:nil];
	
	return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showsecondaryViewController:(UIViewController *)vc
					 sender:(id)sender {
	
	
	return NO;
}

- (void)presentationTransitionWillBegin {
	id <UIViewControllerTransitionCoordinator> transitionCoordinator = [[self presentingViewController] transitionCoordinator];
	[self.view setAlpha:0.0];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.view setAlpha:1.0];
	} completion:nil];
}


- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(MADQueryBuilderSplitViewController *)splitViewController {
	return splitViewController.primaryNavigationController;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(MADQueryBuilderSplitViewController *)splitViewController {
	return splitViewController.primaryNavigationController;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
	return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
	return nil;
}

#pragma mark -
#pragma mark Override

- (void)setDocument:(MADocument *)document {
	if (document != _document) {
		_document = document;
		NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
		for (UIViewController *childViewController in childViewControllers) {
			if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
				[((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
			}
		}
	}
}

- (IBAction)barButtonItemDisplayToggle:(id)sender { }

@end
