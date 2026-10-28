//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADViewerController_Private.h"
#import "MADViewerController+PrintingAndExport.h"

static NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";
static NSString * const MADStoryboardIDViewerController = @"MADIdentifierStoryboardViewerViewController";
static const CGFloat MADBarButtonItemsMargin = 8.0;

@implementation UIResponder (MADViewerController)

- (void)done:(id __unused)eh { [[self nextResponder] done:nil]; }

@end

@implementation MADViewerController

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
	appearanceProxy.tintColor = [UIColor systemBlueColor];
}

+ (void)setNavigationBarAppearanceHighlighted {
	NSArray <Class <UIAppearanceContainer>> *classes = [[NSArray alloc] initWithObjects: self, nil];
	UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
	appearanceProxy.barTintColor = nil;
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
	
	self.view.backgroundColor = [UIColor secondarySystemBackgroundColor];
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

	// The reload below formats the report, and on a large document that takes a couple
	// of seconds.  The refresh button has nothing to do until it finishes -- and a
	// refresh started mid-format would set a second format going against the same
	// document -- so it is disabled for the run.  The reload's -finishReload: restores
	// it through -setDisplayActive; registering the observer gives the finish a second
	// path through -operationDidFinish:, whose !_refreshing branch was written for this
	// operation but never reached because nothing ever registered it.
	buttonRefresh.enabled = NO;
	MADLabelStatus *labelStatus = self.labelStatus;
	[labelStatus updateRefreshStarted];
	[reload addObserver:self];
	[self.refreshQueue addOperation:reload];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	self.pageSlider.sliderDelegate = nil;
	self.dataSource = nil;
	self.delegate = nil;
	[self.tabBarController.navigationItem setRightBarButtonItem:nil];
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

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController * __unused)dismissed {
	return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController * __unused)presented
																  presentingController:(UIViewController * __unused)presenting
																	  sourceController:(UIViewController * __unused)source {
	return self;
}

- (void)presentationTransitionWillBegin { }
- (void)presentationTransitionDidEnd:(BOOL __unused)completed { }
- (void)dismissalTransitionWillBegin { }
- (void)dismissalTransitionDidEnd:(BOOL __unused)completed { }

#pragma mark -
#pragma mark UIViewControllerContextTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning> __unused)transitionContext {
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

- (IBAction)refresh:(id __unused)sender {
	_didRefreshBeforeReaload = YES;
	
	if (_refreshing == NO) {
		_startedRefresh = YES;
		_refreshing = YES;

		[self setDisplayInactive];

		[self.labelStatus updateRefreshStarted];
		
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
			[MADBarcodeCache.sharedCache flush];
		};
		[self.refreshQueue addOperation:refresh];
	}
}

- (IBAction)zoomToActualSize:(id __unused)sender { }

- (IBAction)zoomToFit:(id __unused)sender { }

- (IBAction)zoomToFullScreen:(id __unused)sender { }

#pragma mark -
#pragma mark UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController * __unused)viewerViewController
	   viewControllerAfterViewController:(MADDocumentPageController *)pageViewControllerLast {
	MADDocumentPageController *result = nil;

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
	return result;
}

- (UIViewController *)pageViewController:(MADViewerController * __unused)viewerViewController
	  viewControllerBeforeViewController:(MADDocumentPageController *)pageViewControllerPrevious {
	MADDocumentPageController *result = nil;
	
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

		result.delegate = self;
		result.view.frame = self.view.bounds;
		result.view.autoresizingMask = MADViewAutoresizingFlexable();
		result.view.translatesAutoresizingMaskIntoConstraints = YES;
	}

	return result;
}

#pragma mark -
#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(MADViewerController *)pageViewController
		didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray * __unused)previousViewControllers
	   transitionCompleted:(BOOL)completed {

	if (completed || finished) {
		pageViewController->_pageIsAnimating = NO;

		if (pageViewController.viewControllers.count > 0) {
			MADDocumentPageController *viewController = pageViewController.viewControllers[0];
			pageViewController->_currentLocation.currentPage = viewController.pageViewAttributes.pageNumber - 1;
			MADLabelStatus *labelStatus = self.labelStatus;
			[labelStatus updatePageStatus: _currentLocation];
			[pageViewController.pageSlider.pageSlider setValue: (float)pageViewController->_currentLocation.currentPage
													  animated: YES];
		}
	}
}

- (void)pageViewController:(MADViewerController *)pageViewController
							willTransitionToViewControllers:(NSArray * __unused)pendingViewControllers {
	pageViewController->_pageIsAnimating = YES;
}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
				   spineLocationForInterfaceOrientation:(UIInterfaceOrientation __unused)orientation {
	pageViewController->_pageIsAnimating = NO;
	return UIPageViewControllerSpineLocationMin;
}

#pragma mark -
#pragma mark Status Label

- (void)updateTimeSinceLastRefresh:(id __unused)sender {
	MADLabelStatus *labelStatus = self.labelStatus;
	MTDateResolution resolution;
	
	if (_lastCacheDate == nil) {
		NSError *error = nil;
		NSString *path = self.document.urlDataTableCache.path;
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		} else {
			_lastCacheDate = [attributes.fileModificationDate copy];
		}

		if (_lastCacheDate == nil) {
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

- (void)operation:(MADOperation * __unused)operation didProduceOperation:(NSOperation * __unused)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray<NSError *> *)errors {
	if (errors != nil && errors.count > 0) {
		for (NSError *error in errors) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		}

		[self.labelStatus updatePageStatus: _currentLocation];
		
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
				
				UIViewController *presentingVC = self.presentedViewController ?: self;
				[presentingVC presentViewController:alert animated:YES completion:nil];
			}
		};
		
		if ([NSThread isMainThread]) {
			presentErrorsBlock();
		} else {
			dispatch_async(dispatch_get_main_queue(), presentErrorsBlock);
		}
	}
	
	self.pageSlider.enabled = YES;

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

- (void)operation:(MADOperation * __unused)operation didReadRows:(NSNotification *)sender {
	NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

- (void)operation:(MADOperation * __unused)operation didFormatPage:(NSNotification *)sender {
	NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
	[self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)operationDidBeginFormatting:(MADOperation *)__unused operation {
	[self.labelStatus updateFormattingStarted];
}

- (void)operation:(MADOperation * __unused)operation updateRecordsRead:(NSUInteger)records {
	NSNumber *numberOfResults;
	numberOfResults = [[NSNumber alloc] initWithUnsignedInteger: records];
	[self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
}

- (void)operation:(MADOperation *)operation updatePages:(NSUInteger)numberOfPages {
	MADLabelStatus * labelStatus = self.labelStatus;
	os_log_debug(OS_LOG_DEFAULT, "%s: pages=%lu thread=%@ labelStatus=%p operation=%p",
				 __PRETTY_FUNCTION__, (unsigned long)numberOfPages,
				 NSThread.currentThread.description, labelStatus, operation);
	if ([operation isKindOfClass:[MADRefreshOperationReload class]]) {
		self.pageSlider.numberOfPages = numberOfPages;
	}
	_currentLocation.totalPages = numberOfPages;
	[labelStatus updatePageStatus: _currentLocation];
}

#pragma mark -
#pragma mark UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
	switch (direction) {

		case UIAccessibilityScrollDirectionNext:
		case UIAccessibilityScrollDirectionRight:
			return [self moveToPageAtIndex: _currentLocation.currentPage + 1 ];
			
		case UIAccessibilityScrollDirectionPrevious:
		case UIAccessibilityScrollDirectionLeft:
			return [self moveToPageAtIndex: _currentLocation.currentPage - 1 ];
			
		default:
			return NO;
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

- (void)updateNavigationPrompt:(BOOL __unused)animated {
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

- (void)operation:(MADOperation * __unused)operation setDisplayActive:(BOOL)active {
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
			if (!strongSelf) return;

			if (active) {
				[strongSelf setDisplayActive];
			} else {
				[strongSelf setDisplayInactive];
			}
		});
	}
}

- (void)operation:(MADOperation * __unused)operation finishReload:(MADocument *)document {
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
			if (!strongSelf) return;

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
