//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADViewerController.h"
#import "MADOperationRefreshReload.h"
#import "MADPrintingProtocol.h"
#import "MADTabBarController.h"
#import "MADActivityReportPrintPreview.h"
#import "MADDocumentPageController.h"
#import "MADPageSlider.h"
#import "MADSliderPageVertical.h"
#import "MADLabelStatus.h"
#import "MADPageViewAttributes.h"
#import "MADDocumentScroller.h"
#import "MADRefreshOperationReload.h"
#import "MTStoreKitController+Features.h"
#import "UIViewController+tabBarItem.h"
#import "NSDate+Extras.h"
#import "MADThemeManager.h"
#import "madlog.h"

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationObserver.h>
#import <MADAPI/MADNotificationDidReadRows.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/UIApplication+Helpers.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADDataStructures/MTPair.h>
#import <MAD/MADActivityItemProviderDelegate.h>
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import <MAD/MADActivityItemProviderPdf.h>
#import <MAD/MADNotificationDidFormatPage.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIAccessibilityConstants.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIDocumentInteractionController.h>
#import <UIKit/UILocalNotification.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/UIPrintInteractionController.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UITabBarItem.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>

static NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";
static NSString * const MADStoryboardIDViewerController = @"MADIdentifierStoryboardViewerViewController";
static const CGFloat MADBarButtonItemsMargin = 8.0;

//#pragma mark -
//#pragma mark MADOperationRenderOnViewert
//
//@interface MADOperationRenderOnViewert : NSOperation
//    - (instancetype)initWithDocument:(MADocument *)document;
//    @property (readonly, nonatomic, weak) MADocument *document;
//@end

#pragma mark -
#pragma mark MADOperationLoadDocument

@interface MADOperationLoadDocument : NSOperation
	- (instancetype)initWithDocument:(MADocument *)document;
	@property (readonly, nonatomic, weak) MADocument *document;
@end

#pragma mark -
#pragma mark MADOperationLoadPrintPageRender

@interface MADOperationLoadPrintPageRender : NSOperation
	- (instancetype)initWithDocument:(MADocument *)document;
	@property (readonly, nonatomic, weak) MADocument *document;
	@property (readonly, nonatomic, weak) MADPrintPageRenderer *printPageRenderer;
@end

@interface MADViewerController () <UIPopoverPresentationControllerDelegate, UIStateRestoring, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIDocumentInteractionControllerDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, MADOperationObserver, MADPageSliderProtocol, MADPrintingProtocol, MADActivityReportPrintPreviewDelegate, MADActivityItemProviderDelegate>

@property (nonatomic, strong) MADDateFromTimeFormatter *dateTimeFormatter;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;
@property (nonatomic, strong)   MADPageSlider *pageSlider;
@property (nonatomic, weak)     MADLabelStatus *labelStatus;
@property (nonatomic, readonly) MADTabBarController *tabBarController;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemRefresh;

@property (nonatomic, strong) MADPrintPageRenderer *printPageRendererReport;
@property (nonatomic, strong) MADActivityItemProviderPdf *activityItemProviderPdf;

@property (nonatomic, strong) MADOperationQueue *refreshQueue;

@end

@implementation UIResponder (MADViewerController)

- (void)done:(id)eh { [[self nextResponder] done:nil]; }

@end


@implementation MADViewerController {
	NSDate *_lastCacheDate;
	MADReportPosition _currentLocation;
	BOOL _isFirstAppearance;
	BOOL _firstTimeViewWillLayoutSubviews;
	BOOL _refreshing;
	BOOL _didRefreshBeforeReaload;
	BOOL _activityExporting;
	BOOL _startedRefresh;
	BOOL _pageIsAnimating;
	BOOL _updatingOfTimerIsPaused;
}

	@dynamic tabBarController;
	@synthesize document = _document, title = _title;

#pragma mark -
#pragma mark Static helpers

+ (void)setNavigationBarAppearanceTinted {
	NSArray <Class <UIAppearanceContainer>> *classes;
	Class thisClass = self;
	classes = [[NSArray alloc] initWithObjects: thisClass, nil];
	UINavigationBar *appearanceProxy;
	appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
	appearanceProxy.barTintColor = nil;
	appearanceProxy.tintColor = [MADColorEverydayApps newColorWhite];
}

+ (void)setNavigationBarAppearanceHighlighted {
	NSArray <Class <UIAppearanceContainer>> *classes = [[NSArray alloc] initWithObjects: self, nil];
	UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
	appearanceProxy.barTintColor = [MADColorEverydayApps newColorAnalogous4];
	appearanceProxy.tintColor = [MADColorEverydayApps newColorRed];
}

+ (instancetype)newViewerController:(MADocument *)document {
	id controller = [[UIStoryboard storyboardWithName: @"MADDesigner" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: MADStoryboardIDViewerController];
	[((typeof(self))controller) setDocument: document];
	return controller;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	if (_timerLabelTimeSinceRefreh != nil) {
		if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
			if (_timerLabelTimeSinceRefreh.valid) {
				[_timerLabelTimeSinceRefreh invalidate];
			}
		}
		_timerLabelTimeSinceRefreh = nil;
	}
}

- (void)timerDealloc {
	NSTimer *timer = self.timerLabelTimeSinceRefreh;
	if (timer != nil) {
		if ([timer respondsToSelector:@selector(isValid)]) {
			if (timer.valid) {
				[timer invalidate];
			}
		}
		timer = nil;
		self.timerLabelTimeSinceRefreh = nil;
	}
}

#pragma mark -
#pragma mark Initialize

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		_isFirstAppearance = YES;
		_firstTimeViewWillLayoutSubviews = YES;
		_activityExporting = NO;
		_didRefreshBeforeReaload = NO;
		_refreshing = NO;
		_activityExporting = NO;
		_startedRefresh = NO;
		_pageIsAnimating = NO;
		_updatingOfTimerIsPaused = NO;
		_lastCacheDate = nil;
		
		MADOperationQueue *refreshQueue = [[MADOperationQueue alloc] init];
		self.refreshQueue = refreshQueue;
		
		MADPageSlider *pageSlider = [[MADPageSlider alloc] init];
		self.pageSlider = pageSlider;
		
	}
	return self;
}

#pragma mark -
#pragma mark UIViewController Standard Callbacks

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;
	
	self.view.backgroundColor = [UIColor lightGrayColor];
	[MADThemeManager applyAppearanceToBarButtonItem:_barButtonItemRefresh traitCollection:self.traitCollection];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	_currentLocation = MADReportPositionMake(0, 0);
	
	_refreshing = NO;
	_startedRefresh = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.dataSource = self;
	self.delegate = self;
	
	MADPageSlider *pageSlider = self.pageSlider;
	pageSlider.sliderDelegate = self;
	[self.view addSubview: pageSlider];
	[self.view bringSubviewToFront: pageSlider];

	[self.navigationController.toolbar setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.pageSlider.sliderDelegate = nil;
	[self.pageSlider removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[self updateNavigationPrompt:animated];

	MADocument *document = self.document;
	
	MADRefreshOperationReload *reload = [[MADRefreshOperationReload alloc] initWithDocument: document
																			 viewController: self];
	
	MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] initWithPosition: _currentLocation
																					   size: document.paper.paperSize];
	MADDocumentPageController *page = [MADDocumentPageController newDocumentPageController: document
																			pageAttributes: pageAttributes];
	
	page.view.frame = self.view.bounds;
	page.delegate = self;
	
	NSArray <MADDocumentPageController *> *pages = @[page];
	[self setViewControllers: pages
				   direction: UIPageViewControllerNavigationDirectionForward
					animated: animated
				  completion: nil];
	
	NSUInteger statusLabelIndex;
	statusLabelIndex = [self.toolbarItems indexOfObjectPassingTest:^BOOL(__kindof UIBarButtonItem * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		return [obj.customView isKindOfClass:[MADLabelStatus class]];
	}];
	
	if (statusLabelIndex == NSNotFound) {
		NSMutableArray <__kindof UIBarButtonItem *> *toolbarItems = self.toolbarItems.mutableCopy;
		MADLabelStatus *labelStatus = [[MADLabelStatus alloc] initWithFrame: CGRectMake(CGPointZero.x, CGPointZero.y, 30.0, 44.0)];
		
		UIBarButtonItem *buttonStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
		[toolbarItems insertObject: buttonStatus atIndex: 0];
		[self setToolbarItems: toolbarItems animated:animated];
		self.labelStatus = labelStatus;
	}

	UIBarButtonItem *buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
																				   target: self
																				   action: @selector(refresh:)];
	[MADThemeManager applyAppearanceToBarButtonItem:buttonRefresh traitCollection:self.traitCollection];

	UIBarButtonItem *buttonDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																				target: nil
																				action: @selector(done:)];
	[MADThemeManager applyAppearanceToBarButtonItem:buttonDone traitCollection:self.traitCollection];

	[self.navigationController setToolbarHidden:NO animated:animated];
	
	[self updateTimeSinceLastRefresh:self];
	
	buttonRefresh.enabled = YES;
	buttonDone.enabled = YES;
	self.barButtonItemRefresh = buttonRefresh;

	[self.tabBarController.navigationItem setRightBarButtonItem: buttonRefresh animated: YES];
	[self.tabBarController.navigationItem setLeftBarButtonItem: buttonDone animated: YES];
	
	[self.refreshQueue addOperation:reload];

}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	self.pageSlider.sliderDelegate = nil;
	self.dataSource = nil;
	self.delegate = nil;
	[self.tabBarController.navigationItem setRightBarButtonItem:nil];
	// FIXME: This has to be cleared, or the cache grows, and grows.
	[self timerDealloc];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	CGFloat nonSliderButtonsWidth = CGSizeZero.width;
	NSUInteger counter = 0;
	
	NSArray<UIBarButtonItem *> *items = self.navigationController.toolbar.items;
	for (UIBarButtonItem *barButtonItem in items) {
		UIView *view = [barButtonItem valueForKey:NSStringFromSelector(@selector(view))];
		if (view != nil) {
			nonSliderButtonsWidth += (view ? view.frame.size.width : CGSizeZero.width) + MADBarButtonItemsMargin;
		} else {
			nonSliderButtonsWidth += barButtonItem.width;
		}
		counter++;
	}
	[self.pageSlider setNeedsLayout];
	[self.view bringSubviewToFront:self.pageSlider];
	self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0, 44.0);
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																  presentingController:(UIViewController *)presenting
																	  sourceController:(UIViewController *)source {
	return self;
}

- (void)presentationTransitionWillBegin { }
- (void)presentationTransitionDidEnd:(BOOL)completed { }
- (void)dismissalTransitionWillBegin { }
- (void)dismissalTransitionDidEnd:(BOOL)completed { }

#pragma mark -
#pragma mark UIViewControllerContextTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
	return 3.0;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
	self.pageSlider.alpha = 0.0f;
	NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
	[UIView animateWithDuration:transitionDuration animations:^{
		self.pageSlider.alpha = 1.0f;
	} completion:^(BOOL __unused finished) {
		[transitionContext completeTransition:![transitionContext transitionWasCancelled]];
	}];
}

#pragma mark -
#pragma mark UIContentContainer

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) { }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[self updateNavigationPrompt:previousTraitCollection != nil];
	if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
		[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemRefresh traitCollection:self.traitCollection];
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.navigationController.toolbar setNeedsLayout];
		[self.navigationItem.titleView sizeToFit];
		[self.pageSlider setNeedsLayout];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.navigationController.toolbar setNeedsLayout];
		[self.navigationItem.titleView sizeToFit];
		[self.pageSlider setNeedsLayout];
	}];
}

#pragma mark -
#pragma mark MADPrintingProtocol

- (MADPrintPageRenderer *)printPageRenderer {
	return self.printPageRendererReport;
}

#pragma mark -
#pragma mark MADPageSliderDelegate

- (void)sliderDidChangeToPage:(NSUInteger)page {
	[self moveToPageAtIndex:page];
}

#pragma mark -
#pragma mark Overrides

- (MADTabBarController *)tabBarController {
	return (MADTabBarController *)self.navigationController.tabBarController;
}

- (MADDateFromTimeFormatter *)dateTimeFormatter {
	if (_dateTimeFormatter == nil) {
		MADDateFromTimeFormatter *dateTimeFormatter = [[MADDateFromTimeFormatter alloc] init];
		_dateTimeFormatter = dateTimeFormatter;
	}
	return _dateTimeFormatter;
}

+ (NSString *)Title { return @"MAD Viewer"; }

- (NSString *)title { return [self.class Title]; }

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)TabBarImage {
	return [UIImage imageNamed:MADImageBarButtonItemMadViewer8];
}

- (nullable MADDocumentPageController *)visiblePageViewController {
	id result = self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
	return result;
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
	
	BOOL success;
	if ((success = ((unsigned long)index != _currentLocation.currentPage && index != NSNotFound))) {
		
		MADDocumentPageController *visiblePageViewController = [self visiblePageViewController];
		_currentLocation.currentPage = index;
		
		[self.labelStatus updatePageStatus: _currentLocation];

		MADDocumentScroller *documentScroller = visiblePageViewController.documentScroller;
		MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] initWithPosition: _currentLocation
																						   size: documentScroller.contentSize];
		pageAttributes.zoomScaleInital = documentScroller.zoomScale;
		pageAttributes.contentOffsetInital = documentScroller.contentOffset;
		pageAttributes.contentScaleFactor = visiblePageViewController.documentView.contentScaleFactor;
		
		MADDocumentPageController *pageOne = [[MADDocumentPageController alloc] initWithDocument: self.document
																			  andPageAttributtes: pageAttributes];

		pageOne.view.frame = self.view.bounds;
		pageOne.view.backgroundColor = [self.view.backgroundColor copy];
		pageOne.delegate = self;

		[self.view bringSubviewToFront: self.pageSlider];
 
		_updatingOfTimerIsPaused = NO;
		_refreshing = NO;
		NSArray <MADDocumentPageController *> *pages = @[pageOne];
		[self setViewControllers: pages
					   direction: UIPageViewControllerNavigationDirectionForward
						animated: NO
					  completion: ^(BOOL finished) {
			if (finished) {
				[pageOne.view setNeedsDisplay];
			}
		}];
	}
	return success;
}

- (MADDocumentPageController *)currentPageviewController {
	return [self pageViewControllerAtIndex: _currentLocation.currentPage];
}

- (MADDocumentPageController *)pageViewControllerAtIndex:(NSUInteger)index {
	return index < self.viewControllers.count ? self.viewControllers[index] : self.viewControllers.lastObject;
}

#pragma mark -
#pragma mark Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
	return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
	NSURL *temporaryFile = [[NSURL fileURLWithPath: NSTemporaryDirectory()] URLByAppendingPathComponent:@"preview.pdf"];
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtURL:temporaryFile
															 error:&error];
	if (!success && error != nil) {
		os_log_error(GetDesignerLog(), "Error: %@", error);
	}
	NSAssert(success, @"Failed to delete file.");
}

#pragma mark -
#pragma mark UI Updates

- (void)setDisplayActive {
	self.pageingEnabled = YES;
	self.tabBarItemsEnabled = YES;
	self.pageSlider.enabled = YES;
	self.barButtonItemActivity.enabled = YES;
	_refreshing = NO;
	_updatingOfTimerIsPaused = NO;

	UIBarButtonItem *buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
																				   target: self
																				   action: @selector(refresh:)];
	[MADThemeManager applyAppearanceToBarButtonItem:buttonRefresh traitCollection:self.traitCollection];
	buttonRefresh.enabled = YES;
	self.barButtonItemRefresh = buttonRefresh;
	[self.tabBarController.navigationItem setRightBarButtonItem: buttonRefresh
													  animated: YES];
}

- (void)setDisplayInactive {
	self.pageingEnabled = NO;
	self.tabBarItemsEnabled = NO;
	self.pageSlider.enabled = NO;
	self.barButtonItemActivity.enabled = NO;
	_refreshing = YES;
	_updatingOfTimerIsPaused = NO;

	// The refresh button is replaced by the indicator for the whole run, so it
	// cannot be tapped again mid-refresh; the stored button is disabled as well
	// for the moment before the swap lands.
	self.barButtonItemRefresh.enabled = NO;

	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleMedium];
	activityIndicator.hidden = NO;
	activityIndicator.hidesWhenStopped = NO;
	activityIndicator.color = [MADColorEverydayApps newColorRed];

	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[activityIndicator startAnimating];
	[self.tabBarController.navigationItem setRightBarButtonItem: barButtonItem
													  animated: YES];
}

- (void)setPageingEnabled:(BOOL)enabled {
	NSArray *gestureRecognizers = self.gestureRecognizers;
	[gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull gestureRecognizer, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		gestureRecognizer.enabled = enabled;
	}];
}

- (void)setTabBarItemsEnabled:(BOOL)enabled {
	NSArray <UITabBarItem *> *tabBarItems = self.tabBarController.tabBar.items;
	[tabBarItems enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UITabBarItem * _Nonnull tabBarItem, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{ tabBarItem.enabled = enabled; }];
	}];
}

#pragma mark -
#pragma mark Actions

- (IBAction)activity:(id)sender {
	_activityExporting = YES;
	self.pageSlider.enabled = NO;
	
	MADActivityItemProviderPdf *activityItemProviderPdf = self.activityItemProviderPdf;
	activityItemProviderPdf.delegate = self;
	NSArray *activityItems = [[NSArray alloc] initWithObjects: activityItemProviderPdf, nil];
	self.activityItemProviderPdf = activityItemProviderPdf;
	
	MADActivityReportPrintPreview *printPreview = [[MADActivityReportPrintPreview alloc] init];
	printPreview.delegate = self;
	
	NSArray *applicationActivities = [[NSArray alloc] initWithObjects: printPreview, nil];
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
																						 applicationActivities:applicationActivities];

	MADViewerController * __weak weakself = self;

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed,
														  NSArray *__unused returnedItems, NSError *__unused activityError) {
		MADViewerController *sself = weakself;
		sself.pageSlider.enabled = YES;
		sself->_activityExporting = NO;
		if (completed || (!completed && activityType == nil)) {
			[(MADTabBarController *)sself.tabBarController enableTabBarItems];
		} else {
			if (activityType.length > 0) {  // Long running activity
				if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
						id document = sself.document;
						[document updatePrintingReportFormatter];
						MADPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource: document];
						
						[UIPrintInteractionController sharedPrintController].delegate = document;
						[UIPrintInteractionController sharedPrintController].printPageRenderer = printPageRenderer;
						if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
							
							[MADViewerController setNavigationBarAppearanceHighlighted];
							MADViewerController * __weak weakself2 = sself;
							[[UIPrintInteractionController sharedPrintController] presentAnimated:YES completionHandler:^(UIPrintInteractionController *__unused printInteractionController, BOOL animatinCompleted, NSError *__unused error) {
								 
								 if (animatinCompleted) {
									 MADViewerController *sself2 = weakself2;
									 [MADViewerController setNavigationBarAppearanceTinted];
									 
									 sself2.pageSlider.enabled = YES;
									 sself2->_activityExporting = NO;
									 [(MADTabBarController *)sself2.tabBarController enableTabBarItems];
								 }
							 }];
						}
				}
			} else {
				[(MADTabBarController *)sself.tabBarController enableTabBarItems];
			}
		}
	};
	activityViewController.modalPresentationStyle = UIModalPresentationPopover;
	
	UIPopoverPresentationController *ppc = activityViewController.popoverPresentationController;
	ppc.barButtonItem = sender;
	
	MADViewerController * __weak weakSelf = self;
	[self presentViewController:activityViewController animated:YES completion:^{
		weakSelf.presentedViewController.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
	}];
	[self.tabBarController disableTabBarItems];
}

- (IBAction)refresh:(id)sender {
	_didRefreshBeforeReaload = YES;
	
	if (_refreshing == NO) {
		_startedRefresh = YES;
		_refreshing = YES;
		
		[self setDisplayInactive];
		
		MADocument *document = self.document;
		MADOperationRefreshReload *refresh = [[MADOperationRefreshReload alloc] initWithDocument: document
																				  viewController: self
																			  databaseConnection: document.database.databaseConnection];
		[refresh addObserver:self];

		__weak MADViewerController *weakSelf = self;
		refresh.completionBlock = ^{
			__strong MADViewerController *strongSelf = weakSelf;
			if (strongSelf) {
				strongSelf->_refreshing = NO;
			}
		};
		[self.refreshQueue addOperation:refresh];
	}
}

- (IBAction)zoomToActualSize:(id)sender { }

- (IBAction)zoomToFit:(id)sender { }

- (IBAction)zoomToFullScreen:(id)sender { }

#pragma mark -
#pragma mark Acivities

- (MADActivityItemProviderPdf *)activityItemProviderPdf {
	NSString *temporaryDirectoryPath = NSTemporaryDirectory();
	NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
	NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
	MADActivityItemProviderPdf *activityItemProviderPdf = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
	activityItemProviderPdf.document = self.document;
	return activityItemProviderPdf;
}

#pragma mark -
#pragma mark UIDocumentInteractionController

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
	return self;
}

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller
							 completion:(void (^)(BOOL))completion {
	if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
		completion(YES);
	} else {
		//[self.popoverControllerActivity dismissPopoverAnimated:YES];
		completion(YES);
	}
}

#pragma mark -
#pragma mark UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
	   viewControllerAfterViewController:(MADDocumentPageController *)pageViewControllerLast {
	MADDocumentPageController *result = nil;

	//if (viewerViewController->_pageIsAnimating == NO) {
		NSUInteger visiblePageNumber = 0;
		pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight |
													   UIViewAutoresizingFlexibleWidth;
		pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
		
		if (pageViewControllerLast != nil &&
			[pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
			visiblePageNumber = pageViewControllerLast.pageViewAttributes.pageNumber;
		}
		
		if (visiblePageNumber + 1 <= _currentLocation.totalPages) {
			
			UIScrollView *documentScroller = pageViewControllerLast.documentScroller;

			MADPageViewAttributes *pageAttributes;
			pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPage: visiblePageNumber + 1
																		  total: _currentLocation.totalPages
																		   size: documentScroller.contentSize];
			pageAttributes.zoomScaleInital = documentScroller.zoomScale;
			pageAttributes.contentOffsetInital = documentScroller.contentOffset;
			pageAttributes.contentScaleFactor = pageViewControllerLast.documentView.contentScaleFactor;

			result = [[MADDocumentPageController alloc] initWithDocument: self.document
														andPageAttributtes: pageAttributes];
			result.delegate = self;
			result.view.backgroundColor = self.view.backgroundColor;
			result.view.frame = self.view.bounds;
			result.view.autoresizingMask = MADViewAutoresizingFlexable();
			result.view.translatesAutoresizingMaskIntoConstraints = YES;
		}
	//}
	return result;
	
}

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
	  viewControllerBeforeViewController:(MADDocumentPageController *)pageViewControllerPrevious {
	MADDocumentPageController *result = nil;
	
	//if (viewerViewController->_pageIsAnimating == NO) {
		
		NSUInteger visiblePageNumber = 0;
		
		if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
		
			visiblePageNumber = pageViewControllerPrevious.pageViewAttributes.pageNumber;
			
		}
		if (visiblePageNumber - 1 > 0) {
			
			UIScrollView *documentScroller = pageViewControllerPrevious.documentScroller;
			MADPageViewAttributes *pageAttributes;
			pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPage: visiblePageNumber - 1
																		  total: _currentLocation.totalPages
																		   size: documentScroller.contentSize];
			pageAttributes.zoomScaleInital = documentScroller.zoomScale;
			pageAttributes.contentOffsetInital = documentScroller.contentOffset;
			pageAttributes.contentScaleFactor = pageViewControllerPrevious.documentView.contentScaleFactor;

			result = [[MADDocumentPageController alloc] initWithDocument: self.document
														andPageAttributtes: pageAttributes];
			result.view.backgroundColor = self.view.backgroundColor;

			result.delegate =  self;
			result.view.frame = self.view.bounds;
			result.view.autoresizingMask = MADViewAutoresizingFlexable();
			result.view.translatesAutoresizingMaskIntoConstraints = YES;
		}
		
	//}

	return result;
}

#pragma mark -
#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(MADViewerController *)pageViewController
		didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers
	   transitionCompleted:(BOOL)completed {

	if (completed || finished) {
		pageViewController->_pageIsAnimating = NO;

		if (pageViewController.viewControllers.count > 0) {
			MADDocumentPageController *viewController = pageViewController.viewControllers[0];
			pageViewController->_currentLocation.currentPage = viewController.pageViewAttributes.pageNumber - 1;
			[self.labelStatus updatePageStatus: _currentLocation];
			[pageViewController.pageSlider.pageSlider setValue: pageViewController->_currentLocation.currentPage
													  animated: YES];
		}

	}

}

- (void)pageViewController:(MADViewerController *)pageViewController
							willTransitionToViewControllers:(NSArray *)pendingViewControllers {
	pageViewController->_pageIsAnimating = YES;
}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
				   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
	pageViewController->_pageIsAnimating = NO;
	return UIPageViewControllerSpineLocationMin;

}

#pragma mark -
#pragma mark Status Label

- (void)updateTimeSinceLastRefresh:(id)sender {
	MADLabelStatus *labelStatus = self.labelStatus;
	MTDateResolution resolution;
	
	if (_lastCacheDate == nil) {    // No Cache exist, so return quickly.
		NSError *error = nil;
		NSString *path = self.document.urlDataTableCache.path;
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		} else {
			_lastCacheDate = [attributes.fileModificationDate copy];
		}

		if (_lastCacheDate == nil) {    // Find last cache date
			[labelStatus displayNoCache];
			return;
		}
		
	}

	MTPair *dateStringAndInterval = [self.dateTimeFormatter stringWithTimeIntervalSinceDate:_lastCacheDate];
	[labelStatus updateStatusWithTime:dateStringAndInterval.former];
	resolution = ((NSNumber *)dateStringAndInterval.latter).shortValue;

	if (self.timerLabelTimeSinceRefreh != nil) {
		if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
			if ((self.timerLabelTimeSinceRefreh).valid) {
				[self.timerLabelTimeSinceRefreh invalidate];
			}
		}
		self.timerLabelTimeSinceRefreh = nil;
	}
	
	NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: [MADDateFromTimeFormatter timeIntervalForResolution:resolution]
												  target: self
												selector: @selector(updateTimeSinceLastRefresh:)
												userInfo: nil repeats: NO];
	self.timerLabelTimeSinceRefreh = t;
}

#pragma mark -
#pragma mark Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
	NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation {
	if ([operation isKindOfClass:[MADOperationRefreshReload class]]) {
		
		__weak MADViewerController *weakSelf = self;
		void (^updateUIBlock)(void) = ^{
			__strong MADViewerController *strongSelf = weakSelf;
			if (strongSelf) {
				[strongSelf.pageSlider setEnabled:NO];
				[strongSelf.pageSlider setNeedsLayout];
				[strongSelf.pageSlider setNeedsDisplay];
			}
		};
		
		if ([NSThread isMainThread]) {
			updateUIBlock();
		} else {
			dispatch_async(dispatch_get_main_queue(), updateUIBlock);
		}
	}
}

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray<NSError *> *)errors {
	if (errors != nil && errors.count > 0) {
		for (NSError *error in errors) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		}
		
		// Define block to present error alerts
		void (^presentErrorsBlock)(void) = ^{
			for (NSError *error in errors) {
				NSString *message = error.localizedDescription ?: @"An unknown error occurred.";
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
																			   message:message
																		preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
																   style:UIAlertActionStyleDefault
																 handler:nil];
				[alert addAction:okAction];
				
				// Assuming `self` is a UIViewController or has access to one
				UIViewController *presentingVC = self.presentedViewController ?: self;
				[presentingVC presentViewController:alert animated:YES completion:nil];
			}
		};
		
		// Ensure alerts are presented on the main thread
		if ([NSThread isMainThread]) {
			presentErrorsBlock();
		} else {
			dispatch_async(dispatch_get_main_queue(), presentErrorsBlock);
		}
	}
	
	self.pageSlider.enabled = YES;

	// The open-time reload operation (viewDidAppear:) is a MADRefreshOperationReload
	// and finishes through this same callback.  When the user has already started a
	// refresh, its finish must not flip the display back to active -- that hides the
	// refresh activity indicator mid-refresh.  The refresh group (a
	// MADOperationRefreshReload) still updates the display through the first branch.
	BOOL reloadDisplayUpdate = [operation isKindOfClass:[MADOperationRefreshReload class]] ||
		([operation isKindOfClass:[MADRefreshOperationReload class]] && !_refreshing);
	if (reloadDisplayUpdate) {

		_lastCacheDate = nil;

		__weak MADViewerController *weakSelf = self;
		void (^updateUIBlock)(void) = ^{
			__strong MADViewerController *strongSelf = weakSelf;
			if (strongSelf) {
				strongSelf.pageSlider.numberOfPages = strongSelf->_currentLocation.totalPages;
				[strongSelf updateTimeSinceLastRefresh:nil];
				[strongSelf setDisplayActive];
			}
		};

		if ([NSThread isMainThread]) {
			updateUIBlock();
		} else {
			dispatch_async(dispatch_get_main_queue(), updateUIBlock);
		}
	}
}

#pragma mark -
#pragma mark MADOperationRefreshReloadProtocol

- (void)operation:(MADOperation *)operation didReadRows:(NSNotification *)sender {
	NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

- (void)operation:(MADOperation *)operation didFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)operation:(MADOperation *)operation updateRecordsRead:(NSUInteger)records {
	NSNumber *numberOfResults;
	numberOfResults = [[NSNumber alloc] initWithUnsignedInteger: records];
	[self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];

}

- (void)operation:(MADOperation *)operation updatePages:(NSUInteger)numberOfPages {
	os_log_debug(OS_LOG_DEFAULT, "%s: pages=%lu thread=%@ labelStatus=%p operation=%p",
				 __PRETTY_FUNCTION__, (unsigned long)numberOfPages,
				 NSThread.currentThread.description, self.labelStatus, operation);
	if ([operation isKindOfClass:[MADRefreshOperationReload class]]) {
		self.pageSlider.numberOfPages = numberOfPages;
	}
	_currentLocation.totalPages = numberOfPages;
	[self.labelStatus updatePageStatus: _currentLocation];
}

#pragma mark -
#pragma mark MTActivityItemProviderDelegate

// ???: Why is it like this?

- (void)showPrintDialog {

	MADViewerController * __weak weakself = self;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
			if (sharedController) {
				MADViewerController *sself = weakself;
				
				MADocument *document = sself.document;
				document.activityDelegate = sself;
				[document updatePrintingReportFormatter];
				UIPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource: document];
				sharedController.printPageRenderer = printPageRenderer;
				sharedController.delegate = document;
				
				MADViewerController * __weak weakself2 = sself;
				[sharedController presentFromBarButtonItem: sself.barButtonItemActivity
												  animated: YES
										 completionHandler: ^(UIPrintInteractionController *__unused pic, BOOL __unused completed, NSError *__unused error) {
					MADViewerController *sself2 = weakself2;
					sself2.pageSlider.enabled = YES;
					[sself2.tabBarController enableTabBarItems];
				}];
			}
		});
	});
}

#pragma mark -
#pragma mark MADActivityProtocol

- (UIViewController *)activeViewController { return self; }

#pragma mark -
#pragma mark UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
	switch (direction) {

		case UIAccessibilityScrollDirectionNext:
		case UIAccessibilityScrollDirectionRight:
			return [self moveToPageAtIndex: _currentLocation.currentPage + 1 ];
			break;
			
		case UIAccessibilityScrollDirectionPrevious:
		case UIAccessibilityScrollDirectionLeft:
			return [self moveToPageAtIndex: _currentLocation.currentPage - 1 ];
			break;
			
		default:
			return NO;
			break;
	}
}

- (BOOL)accessibilityPerformEscape {
	[self.viewControllerDelegate viewControllerDidFinish:nil];
	return YES;
}

- (BOOL)isAccessibilityElement {
	return NO;
}

#pragma mark -
#pragma mark Helpers

- (void)updateNavigationPrompt:(BOOL)animated {
	os_log_debug(GetDesignerLog(), "This feature is omitted.");
}

#pragma mark -
#pragma mark MADViewControllerDocumentProtocol

- (void)setDocument:(MADocument *)document {
	if (_document != document) {
		_document = document;
	}
}

#pragma mark -
#pragma mark Operations

- (void)operation:(MADOperation *)operation setDisplayActive:(BOOL)active {
	// This method is called from a background thread. Dispatch UI work to the main thread.
	if ([NSThread isMainThread]) {
		if (active) {
			[self setDisplayActive];
		} else {
			[self setDisplayInactive];
		}
	} else {

		__weak MADViewerController *weakSelf = self;
		dispatch_async(dispatch_get_main_queue(), ^{

			__strong MADViewerController *strongSelf = weakSelf;
			if (!strongSelf) return;;

			if (active) {
				[strongSelf setDisplayActive];
			} else {
				[strongSelf setDisplayInactive];
			}
		});
	}
}

- (void)operation:(MADOperation *)operation finishReload:(MADocument *)document {
	[self finishReload:document];
}

- (void)finishReload:(MADocument *)document {
	if ([NSThread isMainThread]) {
		MADPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
		self.printPageRendererReport = printPageRenderer;
		
		MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] initWithPosition: _currentLocation
																						   size: document.paperSize];
		
		MADDocumentPageController *page = [MADDocumentPageController newDocumentPageController: document
																				pageAttributes: pageAttributes];
		page.view.frame = self.view.bounds;
		page.delegate = self;
		
		NSArray *viewControllers = [[NSArray alloc] initWithObjects:page, nil];
		
		[self setViewControllers: viewControllers
					   direction: UIPageViewControllerNavigationDirectionForward
						animated: NO
					  completion: nil];
		
		[self setDisplayActive];
	} else {
		__weak MADViewerController *weakSelf = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__strong MADViewerController *strongSelf = weakSelf;
			if (!strongSelf) return;;

			MADPrintPageRenderer *printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
			strongSelf.printPageRendererReport = printPageRenderer;
			
			MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] initWithPosition: strongSelf->_currentLocation
																							   size: document.paperSize];
			
			MADDocumentPageController *page = [MADDocumentPageController newDocumentPageController: document
																					pageAttributes: pageAttributes];
			page.view.frame = strongSelf.view.bounds;
			page.delegate = strongSelf;
			
			NSArray *viewControllers = [[NSArray alloc] initWithObjects:page, nil];
			
			[strongSelf setViewControllers: viewControllers
								 direction: UIPageViewControllerNavigationDirectionForward
								  animated: NO
								completion: nil];

			[strongSelf setDisplayActive];
		});
	}
}

#pragma mark -
#pragma mark UIAccessibilityContainer

/*
- (NSInteger)accessibilityElementCount {
    return 1;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return self.parentViewController.view;
}

- (NSArray *)accessibilityElements {
    self.parentViewController.view.isAccessibilityElement = YES;
    self.parentViewController.view.accessibilityLabel = @"Report";
    NSArray *elements = @[self.parentViewController.view];
    return elements;
}*/

#pragma mark -
#pragma mark Debugging

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"Number of Pages:                  %lu\n", (unsigned long)_currentLocation.totalPages];
	[debug appendFormat:@"Current Page Index:               %lu\n", (unsigned long)_currentLocation.currentPage];
	[debug appendFormat:@"Last Cache Date:                  %@\n", _lastCacheDate];
	[debug appendFormat:@"Timer Label Time Since Refreh:    %@\n", self.timerLabelTimeSinceRefreh];
	[debug appendFormat:@"Page Slider:                      %@\n", self.pageSlider];
	[debug appendFormat:@"Bar Button Item Activity:         %@\n", self.barButtonItemActivity];
	[debug appendFormat:@"Print Page Renderer Report:       %@\n", self.printPageRendererReport];
	[debug appendFormat:@"Activity Item ProviderPdf:        %@\n", self.activityItemProviderPdf];
	[debug appendFormat:@"Refreshing:                       %@\n", _refreshing ? @"Yes" : @"No"];
	[debug appendFormat:@"Did Refresh Before Reaload:       %@\n", _didRefreshBeforeReaload ? @"Yes" : @"No"];
	[debug appendFormat:@"Activity Exporting:               %@\n", _activityExporting ? @"Yes" : @"No"];
	[debug appendFormat:@"Started Refresh:                  %@\n", _startedRefresh ? @"Yes" : @"No"];
	[debug appendFormat:@"Page is Animating:                %@\n", _pageIsAnimating ? @"Yes" : @"No"];
	[debug appendFormat:@"Updating of Timer is Paused:      %@\n", _updatingOfTimerIsPaused ? @"Yes" : @"No"];
	[debug appendFormat:@"Refresh Queue:                    %@\n", self.refreshQueue];
	return debug;
}

@end

#pragma mark -
#pragma mark MADOperationRenderOnViewert
/*
@interface MADOperationRenderOnViewert ()
    @property (readwrite, nonatomic, weak) MADocument *document;
    @property (readwrite, nonatomic, weak) MADPrintPageRenderer *printPageRenderer;
@end

@implementation MADOperationLoadDocument {
    BOOL _executing;
    BOOL _finished;
}

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        [self setDocument: document];
        _executing = NO;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isFinished { return _finished; }

- (BOOL)isExecuting { return _executing; }
- (void)executing {

    MADocument *document = self.document;
    self.lastCacheDate = [NSDate date];
    [self setDisplayActive];
    
    [self reloadWithSize:document.paper.paperSize];
    
    [self timerDealloc];
    
    [self updateTimeSinceLastRefresh: NULL];
    
    [self removeObserverDidReadRowsFromDatabase:document.database];
    
    
    
    MADocument *document = self.document;
    _executing = YES;
    
    if (![self isCancelled]) {
        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    }
    
    if (![self isCancelled]) {
        RptqDocument *activeDocumentModel = document.activeDocumentModel;
        [document resetMainQueryWithDocumentModel:activeDocumentModel];
    }
    
    if (![self isCancelled]) {
        [document prepareForQuery];
    }
    
    if (![self isCancelled]) {
        __block BOOL blockComplete = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [document.reportFormatter loadFromCache: document.paper.paperSize];
            blockComplete = YES;
        });
        
        if (blockComplete) {
            _finished = YES;
            _executing = NO;
        }
        
    } else {
        _finished = YES;
        _executing = NO;
    }
}

@end
*/

#pragma mark -
#pragma mark MADOperationLoadPrintPageRender

@interface MADOperationLoadPrintPageRender ()
	@property (readwrite, nonatomic, weak) MADocument *document;
	@property (readwrite, nonatomic, weak) MADPrintPageRenderer *printPageRenderer;
@end

@implementation MADOperationLoadPrintPageRender

- (instancetype)initWithDocument:(MADocument *)document {
	if (self = [super init]) {
		[self setDocument: document];
	}
	return self;
}

- (void)main {
	MADPrintPageRenderer *printPageRenderer;
	MADocument *document;

	if (!self.isCancelled) {
		printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:self.document];
		self.printPageRenderer = printPageRenderer;
	}
	
	if (!self.isCancelled && printPageRenderer == nil) {
		[document activeDocumentModel];
		printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:document];
		self.printPageRenderer = printPageRenderer;
	}
	
	if (!self.isCancelled) {
		document.reportFormatter.didRefresh = NO;
	}
}

@end

#pragma mark -
#pragma mark MADOperationLoadDocument

@interface MADOperationLoadDocument ()
	@property (readwrite, nonatomic, weak) MADocument *document;
@end

@implementation MADOperationLoadDocument {
	BOOL _executing;
	BOOL _finished;
}

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (instancetype)initWithDocument:(MADocument *)document {
	if (self = [super init]) {
		[self setDocument: document];
		_executing = NO;
		_finished = NO;
	}
	return self;
}

/*- (void)start {
    
    // NSOperation.start() contains important logic that shouldn't be bypassed.
    [super start];
    
    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if (self.cancelled) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = NO;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];

        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = YES;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    } else {
        [self main];
    }
}*/

- (BOOL)isAsynchronous {
	return YES;
}

- (BOOL)isFinished { return _finished; }

- (BOOL)isExecuting { return _executing; }

- (void)main {

	//[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
	//_executing = NO;
	//[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];

	MADocument *document = self.document;
	
	if (![self isCancelled]) {
		document.limitResultsDesignMode = [MADStoreKitController sharedObject].isReportingLimited;
	}
	
	if (![self isCancelled]) {
		[document activeDocumentModel];
		[document resetMainQuery];
	}
	
	if (![self isCancelled]) {
		[document prepareForQuery];
	}
	
	if (![self isCancelled]) {
		__block BOOL blockComplete = NO;
		//dispatch_async(dispatch_get_main_queue(), ^{
			[document.reportFormatter loadFromCache: document.paper.paperSize];
			blockComplete = YES;
		//});
		
		if (blockComplete) {
			
			[self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
			_finished = YES;
			[self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
			
			[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
			_executing = NO;
			[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
		}
		
	} else {
		[self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		_finished = YES;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
		
		[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
		_executing = NO;
		[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
	}
}

@end
