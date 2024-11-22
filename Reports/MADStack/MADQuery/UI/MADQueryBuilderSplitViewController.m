//
//  MADQueryBuilderContainerController.m
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderSplitViewController.h"

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIStoryboardPopoverSegue.h>
#import <UIKit/UIImage.h>

#import <MAD/MADocument.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"

#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADQueryVisualizationViewController.h"
#import "MADNavigationControllerQueryBuilder.h"
#import "MADNavigationControllerQueryVisualization.h"

static NSString * const TextTitleFormat = @"MAD %@";
static NSString * const TextTitleQuery = @"Query";

static NSString * const SplitViewController = @"MADIdentifierQueryBuilderSplitViewController";

static NSString * const MADStoryboardQuery = @"MADQuery";
static NSString * const TextRedraw = @"Redraw";

@interface MADQueryBuilderSplitViewController ()
	<UISplitViewControllerDelegate, UIPopoverControllerDelegate>

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
@dynamic primaryViewController, secondaryViewController,
		 primaryNavigationController, secondaryNavigationController;

+ (void)initialize {
	[super initialize];
	
	if (self != [MADQueryBuilderSplitViewController self]) {
		@autoreleasepool {
			UIBarButtonItem <UIAppearance> *appearanceProxy;
			NSArray <Class <UIAppearanceContainer>> *classes;
			classes = [[NSArray alloc] initWithObjects: self, nil];
			appearanceProxy = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxy.tintColor = [UIColor whiteColor];
		}
	}
}

+ (instancetype)newQueryBuilderSplitViewController:(MADocument *)document {
	id bundle = [NSBundle mainBundle];
	id storybard = [UIStoryboard storyboardWithName: MADStoryboardQuery bundle: bundle];
	id controller = [storybard instantiateViewControllerWithIdentifier:SplitViewController];
	[((typeof(self))controller) setDocument: document];
	return controller;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
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
	self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	if (!_setupInitalLayout) {

		UINavigationController *navigationController;
		UIBarButtonItem *buttonSQL;

		navigationController = self.navigationController;
		buttonSQL = _barButtonItemSQL;

		buttonSQL.tintColor = [UIColor whiteColor];

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
	NSString *localizedSuffix = NSLocalizedString(TextTitleQuery, TextTitleQuery);
	id title = [[NSString alloc] initWithFormat: TextTitleFormat, localizedSuffix];
	return title;
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

	BOOL animate;
	NSMutableArray<__kindof UIBarButtonItem *> *toolbarItemsLimited;
	NSArray<__kindof UIBarButtonItem *> *toolbarItemsFull, *toolbarItemsPremium;
	UIBarButtonItem *barButtonItemRevealQuery;
	
	animate = animated.boolValue;
	
	toolbarItemsFull = self.toolbarItems;
	toolbarItemsLimited = toolbarItemsFull.mutableCopy;
	toolbarItemsFull = nil;
	
	
	toolbarItemsPremium = [[NSArray alloc] initWithObjects: barButtonItemRevealQuery, nil];
	[toolbarItemsLimited removeObjectsInArray:toolbarItemsPremium];
	toolbarItemsPremium = nil;
	
	barButtonItemRevealQuery = nil;
	
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

+ (UIImage *)newTabBarImage {
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
			break;

		case UISplitViewControllerDisplayModePrimaryHidden:
			break;

		case UISplitViewControllerDisplayModeAllVisible:
			break;

		case UISplitViewControllerDisplayModePrimaryOverlay:
			break;

		default:
			break;
	}
}

- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc {
	return UISplitViewControllerDisplayModeAllVisible;

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
	[self.navigationController presentViewController:vc animated:YES completion:^{
		
	}];

	return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
   showsecondaryViewController:(UIViewController *)vc
					 sender:(id)sender {


	return NO;
}

- (void)presentationTransitionWillBegin {
	// Add a custom dimming view behind the presented view controller's view
	//[[self containerView] addSubview:_dimmingView];
	//[_dimmingView addSubview:[[self presentedViewController] view]];
	
	// Use the transition coordinator to set up the animations.
	id <UIViewControllerTransitionCoordinator> transitionCoordinator =
	[[self presentingViewController] transitionCoordinator];
	
	// Fade in the dimming view during the transition.
	[self.view setAlpha:0.0];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		 [self.view setAlpha:1.0];
	 } completion:nil];
}


- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(MADQueryBuilderSplitViewController *)splitViewController {
	return splitViewController.primaryNavigationController;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(MADQueryBuilderSplitViewController *)splitViewController {
	return splitViewController.primaryNavigationController;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
	collapseSecondaryViewController:(UIViewController *)secondaryViewController
		  ontoPrimaryViewController:(UIViewController *)primaryViewController {

	return YES; // Query visualization is not needed.
	
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController
		separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {

	return nil;

}

#pragma mark -
#pragma mark Override

- (void)setDocument:(MADocument *)document {
	if (document != _document) {
		_document = document;
		UIViewController *childViewController;
		NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
		for (childViewController in childViewControllers) {
			if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
				[((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
			}
		}
	}
}

- (IBAction)barButtonItemDisplayToggle:(id)sender {
}
@end
