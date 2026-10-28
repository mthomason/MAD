//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController_Private.h"
#import "MADDesignerViewController+ElementSaving.h"
#import "MADDesignerViewController+Toolbox.h"
#import "MADDesignerViewController+CollectionView.h"

@implementation RptqObject (MADDesignerViewControllerChangeShim)
- (NSDictionary<NSString *, id> *)changedValues {
	return self.backingObject.values;
}
@end

@implementation MADDesignerViewController

@dynamic view;

@synthesize document = _document;
@synthesize title = _title;

#pragma mark -
#pragma mark Static Helpers

+ (NSString *)keyPathDocument {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(document));
	return key;
}

+ (NSString *)keyPathDocumentRedoTitle {
	static NSString *key = nil;
	if (key == nil) {
		key = [[MADStringUtilities stringByAppendingPeriod: [self keyPathDocument]] stringByAppendingString:NSStringFromSelector(@selector(undoManager))];
		key = [[MADStringUtilities stringByAppendingPeriod: key] stringByAppendingString:NSStringFromSelector(@selector(redoMenuItemTitle))];
	}
	return key;
}

+ (NSString *)keyPathDocumentUndoTitle {
	static NSString *key = nil;
	if (key == nil) {
		key = [[MADStringUtilities stringByAppendingPeriod: [self keyPathDocument]] stringByAppendingString:NSStringFromSelector(@selector(undoManager))];
		key = [[MADStringUtilities stringByAppendingPeriod: key] stringByAppendingString:NSStringFromSelector(@selector(undoMenuItemTitle))];
	}
	return key;
}

+ (NSString *)Title {
	return [NSString stringWithFormat: @"MAD %@", NSLocalizedString(@"Designer", @"Designer")];
}

#pragma mark -
#pragma mark MTTabBarImageProtocol

+ (UIImage *)TabBarImage {
	return [UIImage imageNamed:@"UIBarButtonItemMadDesigner8"];
}

+ (instancetype)newDesignerViewController:(MADocument *)document {
	MADDesignerViewController *controller = [[UIStoryboard storyboardWithName:@"MADDesigner"
																	   bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
	[controller setDocument: document];
	return controller;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	_reportSectionDatasource = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if (self = [super initWithCoder:aDecoder]) {
		
		NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView = [[NSMutableDictionary alloc] init];
		self.borderAppliedToView = borderAppliedToView;
		_identifierJustDisplayed = -1;
		_boundsOnDisappear = CGRectZero;
		_zoomScaleRestore = -1.0;
		_shownAndHidden = NO;
		_editAggregate = NO;
		_insetsSetup = NO;
		_toolboxVisible = NO;
		_sectionSettingsVisible = NO;
		
	}
	return self;
}

#pragma mark -
#pragma mark UITraitCollection

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	BOOL animate = previousTraitCollection != nil;
	
	if (previousTraitCollection == nil ||
		previousTraitCollection.verticalSizeClass != self.traitCollection.verticalSizeClass) {
		
		[UIView setAnimationsEnabled:animate];
		[self displayPrompt];
		[UIView setAnimationsEnabled:YES];
	}
	if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
		[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemAdd traitCollection:self.traitCollection];
	}
}

#pragma mark -
#pragma mark UIViewController

- (NSString *)title {
	if (_title == nil) {
		_title = [MADDesignerViewController Title];
	}
	return _title;
}

- (MADDesignerStatusLabel *)statusLabelZoomScale {
	if (_statusLabelZoomScale == nil) {
		MADDesignerStatusLabel *detailDisplay = [[MADDesignerStatusLabel alloc] initWithFrame: [self detailDisplayFrame]];
		_statusLabelZoomScale = detailDisplay;
	}
	return _statusLabelZoomScale;
}

- (NSNumberFormatter *)numberFormatterPercentage {
	if (_numberFormatterPercentage == nil) {
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
		_numberFormatterPercentage = numberFormatter;
	}
	return _numberFormatterPercentage;
}

- (MADToolboxTransitioningDelegate *)toolboxTransitioningDelegate {
	if (_toolboxTransitioningDelegate == nil) {
		MADToolboxTransitioningDelegate *delegate = [[MADToolboxTransitioningDelegate alloc] init];
		_toolboxTransitioningDelegate = delegate;
	}
	return _toolboxTransitioningDelegate;
}

- (MADToolboxTransitioningDelegate *)settingsTransitioningDelegate {
	if (_settingsTransitioningDelegate == nil) {
		MADToolboxTransitioningDelegate *delegate = [[MADToolboxTransitioningDelegate alloc] init];
		_settingsTransitioningDelegate = delegate;
	}
	return _settingsTransitioningDelegate;
}

- (UINavigationController *)navigationControllerToolbox {
	if (_navigationControllerToolbox == nil) {
		UINavigationController *navigation = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeToolbox];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
		navigation.transitioningDelegate = self.toolboxTransitioningDelegate;
		navigation.modalPresentationStyle = UIModalPresentationCustom;
		navigation.preferredContentSize = sizePopoverDefault();
		_navigationControllerToolbox = navigation;
	}
	return _navigationControllerToolbox;
}

- (UINavigationController *)navigationControllerSectionLayoutSettings {
	if (_navigationControllerSectionLayoutSettings == nil) {
		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController: self.viewControllerSectionLayoutSettings];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
		navigation.transitioningDelegate = self.settingsTransitioningDelegate;
		navigation.modalPresentationStyle = UIModalPresentationCustom;
		navigation.preferredContentSize = CGSizeMake(MADDefaultsPopooverWidth, 100.0);
		_navigationControllerSectionLayoutSettings = navigation;
	}
	return _navigationControllerSectionLayoutSettings;
}

- (MADToolboxViewController *)viewControllerToolbox {
	if (_viewControllerToolbox == nil) {
		MADToolboxViewController *viewControllerToolbox = (MADToolboxViewController *)self.navigationControllerToolbox.topViewController;
		viewControllerToolbox.clearsBackground = [self padLike];
		viewControllerToolbox.document = _document;
		viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
		
		_toolboxTransitioningDelegate.popoverPresentationControllerDelegate = self;
		_toolboxTransitioningDelegate.passthroughContainer = self.view.scroller;
		
		_viewControllerToolbox = viewControllerToolbox;
	}
	return _viewControllerToolbox;
}

- (MADDesignerSectionLayoutController *)viewControllerSectionLayoutSettings {
	if (_viewControllerSectionLayoutSettings == nil) {
		MADDesignerSectionLayoutController *controller = [MADDesignerSectionLayoutController newDesignerSectionLayoutController];
		controller.delegate = self;
		self.viewControllerSectionLayoutSettings = controller;
	}
	return _viewControllerSectionLayoutSettings;
}

- (MADPromptManager *)promptManager {
	if (_promptManager == nil) {
		MADPromptManager *promptManager;
		promptManager = [[MADPromptManager alloc] initWithDefaultPrompt:_document.fileURL.lastPathComponent];
		_promptManager = promptManager;
	}
	return _promptManager;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	MADocument *document = self.document;
	NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
	
	self.hidesStatusBar = NO;
	
	NSArray <NSLayoutConstraint *> *containerConstraints = self.view.scroller.container.constraints;
	if (containerConstraints.count > 0) {
		[self.view.scroller.container removeConstraints:containerConstraints];
	}
	
	NSArray <NSLayoutConstraint *> *scrollerConstraints = self.view.scroller.constraints;
	if (scrollerConstraints.count > 0) {
		[self.view.scroller removeConstraints:scrollerConstraints];
	}
	
	self.view.scroller.container.backgroundColor = [UIColor secondarySystemBackgroundColor];
	self.view.scroller.backgroundColor = [UIColor systemBackgroundColor];
	
	UITapGestureRecognizer *tapGestureDoubleTap = self.view.scroller.doubleTapToZoom;
	tapGestureDoubleTap.delegate = self;
	
	UIGestureRecognizer *tap = [MADTapGestureRecognizer newTapGestureRecognizerStrayTouchWithTarget: self
																							 action: @selector(handleTapStray:)
																						   delegate: self];
	[tap requireGestureRecognizerToFail:tapGestureDoubleTap];
	[self.view.scroller addGestureRecognizer:tap];
	self.view.scroller.delegate = self;
	self.strayTouchGesture = tap;
	
	NSLayoutConstraint *constraintContentLeft = [MADLayoutConstraint LayoutConstraintView: self.view containerLeft: self.view.scroller.container];
	constraintContentLeft.priority = 999;
	NSLayoutConstraint *constraintContentRight = [MADLayoutConstraint LayoutConstraintView: self.view containerRight: self.view.scroller.container];
	constraintContentRight.priority = 999;
	NSLayoutConstraint *constraintWidth = [MADLayoutConstraint newLayoutConstraintContent: self.view.scroller.container width: [self widthForCurrentZoom]];
	
	[self.view addConstraints:@[
		constraintContentLeft,
		constraintContentRight,
		[MADLayoutConstraint LayoutConstraintView: self.view.scroller containerTop: self.view.scroller.container],
		[MADLayoutConstraint LayoutConstraintScroller: self.view.scroller bottom: self.view.scroller.container],
		constraintWidth,
		[MADLayoutConstraint LayoutConstraintViewScrollerTop: self.view.scroller view: self.view.scroller.container]
	]];
	
	self.layoutConstraintContainerLeft = constraintContentLeft;
	self.layoutConstraintContainerWidth = constraintWidth;
	
	[MADThemeManager applyAppearanceToBarButtonItem:_barButtonItemAdd traitCollection:self.traitCollection];
}

- (void)viewSafeAreaInsetsDidChange {
	[self.view layoutIfNeeded];
	self.layoutConstraintContainerWidth.constant = self.view.safeAreaLayoutGuide.layoutFrame.size.width - (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right);
	self.layoutConstraintContainerLeft.constant = self.view.safeAreaInsets.left;
	[UIView animateWithDuration:0.33333333f animations:^{
		[self.view layoutIfNeeded];
	}];
	[super viewSafeAreaInsetsDidChange];
}

- (CGFloat)widthForCurrentZoom {
	return self.view.safeAreaLayoutGuide.layoutFrame.size.width / self.view.scroller.zoomScale;
}

- (void)observeValueForKeyPath:(NSString * __unused)keyPath ofObject:(id __unused)object change:(NSDictionary * __unused)change context:(void * __unused)context {
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	MADocument *maDocument = self.document;
	
	if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
		[UIView setAnimationsEnabled:NO];
		[self displayPrompt];
		[UIView setAnimationsEnabled:YES];
	}
	
	[self addObservers];
	
	_lastMenuItemSelectRequiresElementView = NO;
	_zoomScaleRestore = self.view.scroller.zoomScale;
	[self.view.scroller setZoomScale: 1.0 animated: NO];
	
	[self.view addSubview:self.statusLabelZoomScale];
	[self updateDisplayDetailZoomValue];
	
	MADReportSectionsDataSource *datasource = [[MADReportSectionsDataSource alloc] initWithManagedObjectContext:maDocument.storeContext];
	datasource.eventDelegate = self;
	[datasource refreshData];
	self.reportSectionDatasource = datasource;
	self.view.scroller.container.datasource = datasource;
	self.view.scroller.container.delegate = self;
	[self.view.scroller.container.strayTouchGestureRecognizer requireGestureRecognizerToFail: self.view.scroller.doubleTapToZoom];
	[self.view.scroller.container reloadData];
	
	[self.view.scroller setNeedsLayout];
	[self.view.scroller.container setNeedsLayout];
	
	UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Undo", @"Undo Button Title")
																	style: UIBarButtonItemStylePlain
																   target: self
																   action: @selector(undo)];
	[self.navigationController setToolbarHidden:NO animated:animated];
	NSArray *toolbarItems = [[NSArray alloc] initWithObjects:toolbarItem, nil];
	[self setToolbarItems:toolbarItems animated:NO];
	self.undoButton = toolbarItem;
}

- (void)undo {
	[self.document.undoManager undo];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (_insetsSetup == NO) _insetsSetup = YES;
	
	[self setScrollersEnabled:YES];
	
	if (_shownAndHidden && _zoomScaleRestore > 1.0001) {
		[self.view.scroller setZoomScale:_zoomScaleRestore animated:NO];
		[self handledScrollViewDidEndZooming: nil withView: nil atScale: self.view.scroller.zoomScale];
		[self.view.scroller scrollRectToVisible:_boundsOnDisappear animated:NO];
	}
	[self.view.scroller flashScrollIndicators];
	[self.view setNeedsUpdateConstraints];
	[self.view setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	_boundsOnDisappear = self.view.scroller.bounds;
	[self.statusLabelZoomScale removeFromSuperview];
	NSArray *emptyArray = [[NSArray alloc] init];
	[self setToolbarItems:emptyArray animated:animated];
	self.undoButton = nil;
	MADocument *document = self.document;
	[document saveContext];
	[document autosaveWithCompletionHandler:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	NSEnumerator <UIView *> *subviews = self.view.scroller.container.subviews.objectEnumerator;
	for (id view in subviews) {
		if ([view isKindOfClass:[MADDesignerSectionView class]]) {
			[((MADDesignerSectionView *)view).sectionLabel removeFromSuperview];
			[view removeFromSuperview];
		}
	}
	
	[self.elementViewsDictionary removeAllObjects];
	[self.visibleElementViews removeAllObjects];
	[self.view.scroller.container cleanup];
	
	_shownAndHidden = YES;
	[self removeObservers];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	self.statusLabelZoomScale.frame = [self detailDisplayFrame];
	[self.viewControllerSectionLayoutSettings.view setNeedsLayout];
	[self.view.scroller.container.ruler setNeedsDisplay];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGRect presentedRect = CGRectZero;
	if (self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil &&
		[self.toolboxTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		
		presentedRect = self.toolboxTransitioningDelegate.presentationController.presentedViewController.view.frame;
		
	} else if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
			   [self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		
		presentedRect = self.settingsTransitioningDelegate.presentationController.presentedViewController.view.frame;
		
	}
	if (presentedRect.origin.x > CGPointZero.x) {
		for (UICollectionView *sectionView in self.view.scroller.container.sectionViews.objectEnumerator) {
			sectionView.contentInset = UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.width, CGSizeZero.height, presentedRect.size.width - MTReportDesignerBorderPaddingSides);
			sectionView.scrollIndicatorInsets = sectionView.contentInset;
		}
	} else {
		for (UICollectionView *sectionView in self.view.scroller.container.sectionViews.objectEnumerator) {
			sectionView.contentInset = UIEdgeInsetsZero;
			sectionView.scrollIndicatorInsets = UIEdgeInsetsZero;
		}
	}
}

- (void)updateViewConstraints {
	CGFloat ratio = [self widthForCurrentZoom];
	if (!isinf(ratio) && !isnan(ratio)) {
		self.layoutConstraintContainerWidth.constant = ratio;
	}
	
	[self.view.scroller.container setNeedsUpdateConstraints];
	[super updateViewConstraints];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[super prepareForSegue:segue sender:sender];
	
	if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
		MADocument *document = self.document;
		[(segue.destinationViewController) setDocument: document];
	}
}

- (BOOL)prefersStatusBarHidden {
	return self.hidesStatusBar || (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
	if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>__unused context) {
			[self.view setNeedsDisplay];
		};
	} else {
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>__unused context) { };
	}
	[coordinator animateAlongsideTransition: transition completion: ^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self adjustContextOffsetForOpenPopover];
		[self.view setNeedsUpdateConstraints];
	}];
}

#pragma mark -
#pragma mark Lazy Load

- (NSMutableSet <NSNumber *> *)selectedElementIDs {
	if (!_selectedElementIDs) {
		_selectedElementIDs = [[NSMutableSet alloc] init];
	}
	return _selectedElementIDs;
}

- (NSMutableSet <MADDesignerElementView *> *)visibleElementViews {
	if (!_visibleElementViews) {
		_visibleElementViews = [[NSMutableSet alloc] init];
	}
	return _visibleElementViews;
}

- (NSMutableDictionary <NSNumber *, __kindof MADDesignerElementView *> *)elementViewsDictionary {
	if (!_elementViewsDictionary) {
		_elementViewsDictionary = [[NSMutableDictionary alloc] init];
	}
	return _elementViewsDictionary;
}

#pragma mark -
#pragma mark UIAccessibility

- (BOOL)accessibilityPerformEscape {
	[self.delegate viewControllerDidFinish:nil];
	return YES;
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
	return direction == UIAccessibilityScrollDirectionUp || direction == UIAccessibilityScrollDirectionDown;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL __unused)animated {
	viewController.view.frame = navigationController.view.frame;
}

- (void)navigationController:(UINavigationController * __unused)navigationController
	   didShowViewController:(UIViewController * __unused)viewController
					animated:(BOOL __unused)animated {
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginZooming: (UIScrollView *)scrollView
						  withView: (UIView * __unused)view {
	if ([scrollView isEqual:self.view.scroller]) {
		[self.statusLabelZoomScale show];
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	
	if ([scrollView isEqual:self.view.scroller]) {
		
		[self updateDisplayDetailZoomValue];
		self.statusLabelZoomScale.frame = [self detailDisplayFrame];
		
		[self.view.scroller.container.ruler setNeedsDisplay];
		
		@autoreleasepool {
			UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
			UIFont *font = [UIFont fontWithDescriptor: [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1]
												 size: fontDescriptor.pointSize / scrollView.zoomScale];
			
			NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
			NSArray <MADDesignerSectionLabel *> *sectionControlViewsArray = self.view.scroller.container.sectionLabels.allValues;
			for (MADDesignerSectionLabel *controlView in sectionControlViewsArray) {
				CGRect controlViewTextBounds = [controlView.text boundingRectWithSize: controlView.bounds.size
																			  options: (NSStringDrawingOptions)-1
																		   attributes: attributes
																			  context: nil];
				
				controlView.preferredMaxLayoutWidth = controlViewTextBounds.size.width / scrollView.zoomScale;
				controlView.font = font;
				controlView.scale = self.view.scroller.zoomScale;
				controlView.contentScaleFactor = scrollView.zoomScale * self.view.scroller.traitCollection.displayScale;
				[controlView setNeedsDisplay];
			}
		}
		
		[self adjustScroller];
		[self.view.scroller.container invalidateIntrinsicContentSize];
		self.view.scroller.container.center = CGPointMake(ScrollViewCenterX(scrollView),
														  ScrollViewCenterY(scrollView));
	}
}

- (void)scrollViewDidEndZooming: (UIScrollView *)scrollView
					   withView: (UIView *)view
						atScale: (CGFloat)scale {
	[self handledScrollViewDidEndZooming:scrollView withView:view atScale:scale];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([scrollView isEqual:self.view.scroller]) {
		[self adjustScroller];
	}
	self.statusLabelZoomScale.frame = [self detailDisplayFrame];
	NSString *message = [[NSString alloc] initWithFormat: NSLocalizedString(@"Scrolled to %@.", @"Scrolled to %@."), NSStringFromCGPoint(scrollView.contentOffset)];
	UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, message);
	[self.view setNeedsUpdateConstraints];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView * __unused)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView * __unused)scrollView {
	return YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView * __unused)scrollView {
	return self.view.scroller.container;
}

#pragma mark -
#pragma mark ScrollView helpers

- (void)adjustScroller {
	
	[self adjustContextOffsetForOpenPopover];
	
	if (self.view.scroller.contentOffset.x != 0) {
		CGPoint offset = self.view.scroller.contentOffset;
		offset.x = CGPointZero.x;
		self.view.scroller.contentOffset = offset;
		self.view.scroller.contentSize = CGSizeMake(self.view.scroller.frame.size.width, self.view.scroller.contentSize.height);
	}
}

- (void)handledScrollViewDidEndZooming: (UIScrollView *)scrollView
							  withView: (UIView * __unused)view
							   atScale: (CGFloat)scale {
	
	if ([scrollView isEqual:self.view.scroller]) {
		
		CGFloat scaleWithScreen = scale * scrollView.traitCollection.displayScale;
		self.view.scroller.container.ruler.contentScaleFactor = scaleWithScreen;
		
		NSSet *elementViews = self.visibleElementViews;
		for (MADDesignerElementView *elementView in elementViews) {
			elementView.contentScaleFactor = scaleWithScreen;
		}
		UIFont *captionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		CGFloat pointsize = captionFont.pointSize;
		
		NSArray <__kindof MADDesignerSectionLabel *> *sectionControlViewsArray = self.view.scroller.container.sectionLabels.allValues;
		for (__kindof MADDesignerSectionLabel *controlView in sectionControlViewsArray) {
			controlView.font = [captionFont fontWithSize:pointsize / scale];
			controlView.contentScaleFactor = scaleWithScreen;
			[controlView setNeedsDisplay];
		}
		
		NSEnumerator *objectEnumerator = self.view.scroller.container.sectionViews.objectEnumerator;
		for (UICollectionView *section in objectEnumerator) {
			section.contentScaleFactor = scale;
		}
		
		[self.view setNeedsLayout];
		
		[self.statusLabelZoomScale hide];
	}
	
	[self adjustContextOffsetForOpenPopover];
}

- (void)updateDisplayDetailZoomValue {
	self.statusLabelZoomScale.text = [self.numberFormatterPercentage stringFromNumber:[NSNumber numberWithDouble: self.view.scroller.zoomScale]];
}

#pragma mark -
#pragma mark UIDocumentStateChangedNotification

- (void)documentStateChanged {
	UIDocumentState documentState = self.document.documentState;
	if (documentState & UIDocumentStateEditingDisabled) {
		self.view.userInteractionEnabled = NO;
	} else {
		self.view.userInteractionEnabled = YES;
	}
}

#pragma mark -
#pragma mark Store Context Notifications

- (void)updateForChangesToDocumentElement:(RptqDocumentElement *)documentObject {
	MADocument *doc = self.document;
	NSDictionary <NSString *, id> *changes = [documentObject changedValues];
	NSNumber *fontsize = [changes objectForKey:NSStringFromSelector(@selector(fontsize))];
	if (fontsize != nil) {
		MADDesignerElementTextView *elementView = (MADDesignerElementTextView *)[self elementViewForManagedObject:documentObject];
		[elementView updateFontSize:fontsize.doubleValue];
		[elementView setNeedsDisplay];
	}
	
	NSString *fontname = [changes objectForKey:NSStringFromSelector(@selector(fontname))];
	if (fontname != nil) {
		MADDesignerElementTextView *elementView = (MADDesignerElementTextView *)[self elementViewForManagedObject:documentObject];
		[elementView updateFontName:fontname];
		[elementView setNeedsDisplay];
	}
	
	for (id change in changes) {
		
		if ([change isEqualToString: NSStringFromSelector(@selector(rect))] ||
			[change isEqualToString: NSStringFromSelector(@selector(margin))] ||
			[change isEqualToString: NSStringFromSelector(@selector(border))] ||
			[change isEqualToString: NSStringFromSelector(@selector(textStyle))] ||
			[change isEqualToString: NSStringFromSelector(@selector(alignment))] ||
			[change isEqualToString: NSStringFromSelector(@selector(numericFormat))] ||
			[change isEqualToString: NSStringFromSelector(@selector(padding))] ||
			[change isEqualToString: NSStringFromSelector(@selector(dropPoint))] ||
			[change isEqualToString: NSStringFromSelector(@selector(inSectionRow))]) {
			
			MADDesignerSectionView *section = [self getSectionViewForSectionID: documentObject.inSectionRow.inSection.identifier];
			MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[@(section.identifier)];
			MADSectionLayoutAttributes *attributes = layoutManager.items[@(documentObject.identifier)];
			if (attributes != nil) {
				attributes.frame = [documentObject elementViewFrameDesignerFrameCalculated];
				_identifierJustDisplayed = documentObject.identifier;
				[layoutManager positionItem:attributes];
				[section.collectionViewLayout invalidateLayout];
			}
			
		}
		
	}
}

- (void)managedObjectContextDidChange:(NSNotification *)notification {
	UIBarButtonItem *undoButton = self.undoButton;
	MADocument *document = self.document;
	undoButton.enabled = document.undoManager.canUndo;
	undoButton.title = document.undoManager.undoMenuItemTitle.copy;
	
	NSSet *updatedObjects = notification.userInfo[RptqStoreContextUpdatedObjectsKey];
	
	for (RptqObject *updatedObject in updatedObjects) {
		if ([updatedObject isKindOfClass:[RptqTextStyle class]]) {
			RptqTextStyle *updatedTextStyle = (RptqTextStyle *)updatedObject;
			if (updatedTextStyle.inElement != nil) {
				MADDesignerElementTextView *elementView;
				elementView = (MADDesignerElementTextView *)[self elementViewForManagedObject:updatedTextStyle.inElement];
				[elementView updateFontName:updatedTextStyle.inElement.fontname
								   fontSize:updatedTextStyle.inElement.fontsize
									   bold:updatedTextStyle.bold
									 italic:updatedTextStyle.italic];
				[elementView updateSetUnderline:updatedTextStyle.underline];
				[elementView updateSetStrikethrough:updatedTextStyle.strikethrough];
				[elementView setNeedsDisplay];
			}
		} else if ([updatedObject isKindOfClass:[RptqAlignment class]]) {
			
			NSNumber *horizontal = [updatedObject.changedValues objectForKey:@"horizontal"];
			if (horizontal != nil) {
				MADDesignerElementTextView *elementView = (MADDesignerElementTextView *)[self elementViewForManagedObject:((RptqAlignment *)updatedObject).inElement];
				[elementView updateHorizontalAlignment:horizontal.shortValue];
				[elementView setNeedsDisplay];
			}
			
		} else if ([updatedObject isKindOfClass:[RptqDirectionalAsymmetry class]]) {
			if (((RptqDirectionalAsymmetry *)updatedObject).inElementMargin != nil) {
				[self positionItem:((RptqDirectionalAsymmetry *)updatedObject).inElementMargin];
				
			} else if (((RptqDirectionalAsymmetry *)updatedObject).inElementPadding != nil) {
				[self positionItem:((RptqDirectionalAsymmetry *)updatedObject).inElementPadding];
				
			} else if (((RptqDirectionalAsymmetry *)updatedObject).inBorder.inElement != nil) {
				[self positionItem:((RptqDirectionalAsymmetry *)updatedObject).inBorder.inElement];
			}
			
		} else if ([updatedObject isKindOfClass:[RptqSize class]]) {
			[self positionItem:((RptqSize *)updatedObject).inRect.inElement];
		} else if ([updatedObject isKindOfClass:[RptqDocumentElement class]]) {
			[self updateForChangesToDocumentElement:(RptqDocumentElement *)updatedObject];
		} else if ([updatedObject isKindOfClass:[RptqDocumentSection class]]) {
			
			RptqDocumentSection *documentSection = (RptqDocumentSection *)updatedObject;
			NSDictionary *changes = [documentSection changedValues];
			for (id change in changes) {
				if ([change isEqualToString:NSStringFromSelector(@selector(height))]) {
					MADDesignerSectionView *section = (MADDesignerSectionView *)[self getSectionViewForDocumentSection: documentSection];
					[self relayoutSectionView:section];
					[section invalidateIntrinsicContentSize];
					[section.collectionViewLayout invalidateLayout];
				}
			}
		}
	}
}

- (void)positionItem:(RptqDocumentElement *)documentObject {
	MADocument *doc = self.document;
	MADDesignerSectionView *section = [self getSectionViewForSectionID: documentObject.inSectionRow.inSection.identifier];
	if (section == nil) {
		os_log_error(GetDesignerLog(), "Section not found for document object.");
		return;
	}
	MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[@(section.identifier)];
	if (layoutManager == nil) {
		os_log_error(GetDesignerLog(), "Layout manager not found for section.");
		return;
	}
	MADSectionLayoutAttributes *attributes = layoutManager.items[@(documentObject.identifier)];
	if (attributes != nil) {
		attributes.frame = [documentObject elementViewFrame];
		_identifierJustDisplayed = documentObject.identifier;
		[layoutManager positionItem:attributes];
		[section.collectionViewLayout invalidateLayout];
	}
	MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
	[elementView setNeedsDisplay];
}

#pragma mark -
#pragma mark Store Context Did Save

- (void)managedObjectContextDidSave:(NSNotification *)notification {
	NSSet *updatedObjects = notification.userInfo[RptqStoreContextUpdatedObjectsKey];
	if (updatedObjects == nil) {
		os_log_info(GetDesignerLog(), "No updated objects in context save notification.");
		return;
	}
	for (RptqObject *object in updatedObjects) {
		if ([object isKindOfClass:[RptqDocumentElement class]]) {
			MADDesignerElementView *elementView = [self elementViewForManagedObject:(RptqDocumentElement *)object];
			[elementView updateForManagedObjectContent:notification.object];
		}
	}
}

#pragma mark -
#pragma mark Menu Notifications

- (void)willHideMenuNotification:(NSNotification *)notification {
	MADLogDebug("%s: Notification: %@", __PRETTY_FUNCTION__, notification);
	MADLogDebug("%s: Menu will hide. Current state - toolboxVisible: %d, sectionSettingsVisible: %d, lastMenuItemSelectRequiresElementView: %d",
				__PRETTY_FUNCTION__, _toolboxVisible, _sectionSettingsVisible, _lastMenuItemSelectRequiresElementView);
	
	MADDesignerElementView *lastElementViewToShowMenu = self.lastElementViewToShowMenu;
	if (lastElementViewToShowMenu) {
		MADLogDebug("%s: Last element view to show menu: %@ (ID: %ld)", __PRETTY_FUNCTION__, lastElementViewToShowMenu, (long)lastElementViewToShowMenu.identifier);
	}
}

- (void)didHideMenuNotification:(NSNotification *)notification {
	MADLogDebug("%s: Notification: %@", __PRETTY_FUNCTION__, notification);
	MADLogDebug("%s: Menu did hide. Initial state - toolboxVisible: %d, lastMenuItemSelectRequiresElementView: %d",
				__PRETTY_FUNCTION__, _toolboxVisible, _lastMenuItemSelectRequiresElementView);
	if (_lastMenuItemSelectRequiresElementView == NO) {
		MADDesignerElementView *lastElementViewToShowMenu = self.lastElementViewToShowMenu;
		if (lastElementViewToShowMenu) {
			MADLogDebug("%s: Processing last element view %@ (ID: %ld)", __PRETTY_FUNCTION__, lastElementViewToShowMenu, (long)lastElementViewToShowMenu.identifier);
			[self deselectElementView: lastElementViewToShowMenu animated: YES];
			NSNumber *identifer = @(lastElementViewToShowMenu.identifier);
			[self.selectedElementIDs removeObject: identifer];
			(self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
			MADLogDebug("%s: Removed element ID %@ from selection. Current selected IDs: %@", __PRETTY_FUNCTION__, identifer, self.selectedElementIDs);
		}
		self.lastElementViewToShowMenu = nil;
	}
	_lastMenuItemSelectRequiresElementView = NO;
	
	MADLogDebug("%s: Final state - toolboxVisible: %d, lastMenuItemSelectRequiresElementView: %d",
				__PRETTY_FUNCTION__, _toolboxVisible, _lastMenuItemSelectRequiresElementView);
}

- (void)didShowMenuNotification:(NSNotification *)notification {
	MADLogDebug("%s: Notification: %@", __PRETTY_FUNCTION__, notification);
	MADLogDebug("%s: Menu did show. Current toolboxVisible: %d, sectionSettingsVisible: %d",
				__PRETTY_FUNCTION__,
				_toolboxVisible,
				_sectionSettingsVisible);
	
	if (_toolboxVisible) {
		MADLogDebug("%s: Toolbox is visible while menu shows - this might be unexpected", __PRETTY_FUNCTION__);
	}
}

- (void)willShowMenuNotification:(NSNotification *)notification {
	MADLogDebug("%s: Notification: %@", __PRETTY_FUNCTION__, notification);
	MADLogDebug("%s: Menu will show. Current toolboxVisible: %d, sectionSettingsVisible: %d",
				__PRETTY_FUNCTION__,
				_toolboxVisible,
				_sectionSettingsVisible);
	
	if (_toolboxVisible) {
		MADLogDebug("%s: Hiding toolbox because menu is appearing", __PRETTY_FUNCTION__);
		__weak MADDesignerViewController *weakself = self;
		[self dismissViewControllerAnimated:YES completion:^{
			__strong MADDesignerViewController *strongSelf = weakself;
			if (strongSelf != nil) {
				strongSelf->_toolboxVisible = NO;
			}
			MADLogDebug("%s: Toolbox dismissed", __PRETTY_FUNCTION__);
		}];
	}
}

#pragma mark -
#pragma mark UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
	return NO;
}

- (BOOL)canPerformAction:(SEL __unused)action withSender:(id __unused)sender {
	return NO;
}

#pragma mark -
#pragma mark Gesture Recognizer Delegate

- (BOOL)gestureRecognizer: (UIGestureRecognizer * __unused)gestureRecognizer
	   shouldReceiveTouch: (UITouch * __unused)touch {
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer * __unused)otherGestureRecognizer {
	
	BOOL panGesture = [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
	BOOL elementView = [gestureRecognizer.view isKindOfClass:[MADDesignerElementView class]];
	BOOL simultaneously = panGesture && !elementView;
	if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
		simultaneously = NO;
	}
	return simultaneously;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer * __unused)gestureRecognizer {
	return YES;
}

#pragma mark -
#pragma mark Actions

- (void)edit:(id __unused)sender { }

#pragma mark -
#pragma mark Gesture Recognizer Handlers

- (void)handlePinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
	
	MADDesignerElementView *piece = ((MADDesignerElementView *)gestureRecognizer.view);
	RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: piece.identifier
																	   fromObjectContext: _document.storeContext];
	
	CGSize currentSize = element.sizeContentView;
	
	if (element.documentObjectType == MADPrintPageElementTypeImage) {
		CGFloat scale = gestureRecognizer.scale;
		CGSize newSize = CGSizeMake(currentSize.width * scale, currentSize.height * scale);
		
		if (newSize.width > 0 && newSize.height > 0) {
			[element setSizeWidth:(float)newSize.width height:(float)newSize.height];
		}
	} else {
		if (gestureRecognizer.numberOfTouches > 1) {
			CGPoint p1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
			CGPoint p2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
			MADCompassDirection direction = MADSpecificDirectionOfDegrees(CGAngleBetweenTwoPoints(p1, p2));
			struct MADResizeAspect resizeAspect = MADResizeTypeForDirection(direction);
			
			switch (resizeAspect.direction) {
					
				case horizontal:
					[element setSizeWidth:(float)(currentSize.width * gestureRecognizer.scale)];
					break;
					
				case vertical:
					[element setSizeHeight:(float)(currentSize.height * gestureRecognizer.scale)];
					break;
					
				default: {
					[element setSizeWidth:(float)(currentSize.width * gestureRecognizer.scale)
								   height:(float)(currentSize.height * gestureRecognizer.scale)];
					break;
				}
			}
		}
	}
	
	gestureRecognizer.scale = 1.0;
	NSError *error = nil;
	BOOL saved = [element.storeContext save:&error];
	if (!saved && error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
	}
}

- (void)handlePanPiece:(UIPanGestureRecognizer *)gestureRecognizer {
	[self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
	switch (gestureRecognizer.state) {
		case UIGestureRecognizerStatePossible:
			break;
		case UIGestureRecognizerStateFailed:
			break;
			
		case UIGestureRecognizerStateBegan: {
			
			[self beginPanPiece:(MADDesignerElementView *)gestureRecognizer.view transition:^{
				[self translatePanGesture:gestureRecognizer];
			} completion:^{
				[self translatePanGesture:gestureRecognizer];
			}];
			
			break;
		}
		case UIGestureRecognizerStateChanged: {
			[self translatePanGesture:gestureRecognizer];
			break;
		}
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded: {
			[self endPanPieceWithGesture:gestureRecognizer];
			break;
		}
		default:
			break;
	}
}

- (void)handleTapStray:(UITapGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateEnded) {
		[self designView:nil handleTapStray:sender];
	}
}

- (void)handleTapLabel:(UITapGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateEnded) {
		[self designView:nil handleTapLabel:sender];
	}
}

- (void)handleToggleElementView:(UITapGestureRecognizer *)sender {
	
	if (sender.state == UIGestureRecognizerStateEnded) {
		
		MADDesignerElementView *elementView = (MADDesignerElementView *)sender.view;
		[self dismissSectionPresentationIfOpen];
		
		[self.view.scroller.container removeBorderFromSections];
		
		if ([self elementViewIsSelected: elementView] == NO) {
			[self selectElementView: elementView];
			
			[self.promptManager addString: elementView.textRepresentation];
			[self displayPrompt];
			
			if (self.selectedElementIDs.count == 1) {
				[self actionShowToolbox];
			} else {
				[self adjustToolboxLocation];
			}
			
			[self setDisplayInactive];
			
		} else {
			
			[self deselectElementView: elementView animated: YES];
			NSNumber *elementViewIdentifier = @(elementView.identifier);
			[self.selectedElementIDs removeObject: elementViewIdentifier];
			(self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
			
			[self.promptManager removeString: elementView.textRepresentation];
			[self displayPrompt];
			
			if (self.selectedElementIDs.count == 0) {
				[self actionHideToolbox];
			} else {
				[self adjustToolboxLocation];
				[self setDisplayInactive];
			}
		}
	}
}

#pragma mark -
#pragma mark Helpers

- (BOOL)elementViewIsSelected:(MADDesignerElementView *)elementView {
	return [self.selectedElementIDs containsObject:@(elementView.identifier)];
}

- (void)selectElementView:(__kindof MADDesignerElementView *)elementView {
	if (self.view.scroller.container.selectedSections.count > 0) {
		[self.view.scroller.container removeBorderFromAllSectionViews];
	} else {
		if (!elementView) return;
		[self.selectedElementIDs addObject: @(elementView.identifier)];
		[self.view.scroller.container applyBorderToView:elementView];
		self.viewControllerToolbox.document = self.document;
		self.viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
	}
}

- (void)deselectElementView:(MADDesignerElementView *)elementView
				   animated:(BOOL __unused)animated {
	[self.view.scroller.container removeBorderFromView: elementView];
	NSArray <UIView *> *passThroughViewsArray = self.popoverToolbox.passthroughViews;
	if (passThroughViewsArray != nil) {
		NSMutableSet <UIView *> * _Nullable passThroughViewsSet = [[NSMutableSet alloc] initWithArray: passThroughViewsArray];
		[passThroughViewsSet removeObject: elementView];
		self.popoverToolbox.passthroughViews = passThroughViewsSet.allObjects;
	}
}

- (RptqDocumentSection *)sectionForLabelTag:(NSInteger)tag {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)tag
														  withNumberOfGroups: query.hasQueryGroups.count];
	return section;
}

- (void)redrawAllElementViewsInCollectionView:(UICollectionView *)collectionView {
	NSArray<NSIndexPath *> *indexPathsForVisibleItems = collectionView.indexPathsForVisibleItems;
	for (NSIndexPath *indexPath in indexPathsForVisibleItems) {
		MADDesignerElementView *elementView = [self elementViewAtIndexPath: indexPath
														  inCollectionView: collectionView];
		[elementView setNeedsDisplay];
	}
}

- (MADDesignerElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath
								  inCollectionView:(UICollectionView *)collectionView {
	return [self elementViewForCollectionViewCell:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (MADDesignerElementView *)elementViewForCollectionViewCell:(UICollectionViewCell *)cell {
	MADDesignerElementView *result = nil;
	NSArray *subviews = cell.contentView.subviews;
	if ([subviews count] <= 0) return nil;
	
	for (id elementView in subviews) {
		if ([elementView isKindOfClass:[MADDesignerElementView class]]) {
			result = elementView;
			break;
		}
	}
	return result;
}

- (CGRect)rectForSelectedElements {
	NSSet <UIView *> *views = [self selectedElementViews];
	return [self.view.scroller.container popoverRectForSelectedViews:views];
}

#pragma mark -
#pragma mark Gesture Helpers

- (void)translatePanGesture:(UIPanGestureRecognizer *)gesture {
	CGPoint translation = [gesture translationInView:self.view];
	gesture.view.center = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);
	[gesture setTranslation:CGPointZero inView:self.view];
}

- (void)beginPanPiece: (MADDesignerElementView *)piece
		   transition: (void (^)(void))transition
		   completion: (void (^)(void))completion {
	
	if (self.presentedViewController != nil) {
		[self actionHideToolbox];
	}
	
	[self setScrollersEnabled: NO];
	
	[UIView animateWithDuration:0.2 animations:^{
		piece.alpha = 0.8;
		piece.backgroundColor = [UIColor darkGrayColor];
	}];
	
	[self.view.scroller.container bringSubviewToFront: piece];
	
	int64_t pieceID = piece.identifier;
	
	RptqStoreContext *private = _document.storeContext;

	MADDesignerViewController *strongself = self;

	RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: pieceID
																			  fromObjectContext: private];
	NSNumber *sectionIdentifier = @(documentObject.inSectionRow.inSection.identifier);
	
	__weak MADDesignerViewController *weakself1 = strongself;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
		MADDesignerViewController *strongself1 = weakself1;
		if (!strongself1) return;
		
		MADDesignerSectionView *sectionView = strongself1.view.scroller.container.sectionViews[sectionIdentifier];
		
		CGRect b = [strongself1.view convertRect:piece.frame fromView:sectionView];
		piece.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, b.size.width, b.size.height);
		[strongself1.view addSubview: piece];
		
		[UIView animateWithDuration:0.2 animations:^{
			piece.alpha = 0.8;
			piece.backgroundColor = [UIColor darkGrayColor];
		}];
		
		transition();
		
		MADocument *document = strongself1.document;
		NSNumber *sectionViewID = @(sectionView.identifier);
		MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[sectionViewID];
		
		NSNumber *pieceIDWrapper = @(pieceID);
		MADSectionLayoutAttributes *itemToRemove = (layoutManager.items)[pieceIDWrapper];
		
		MADocument * __weak wdocument = document;
		MADDesignerViewController __weak *weakself2 = strongself1;
		
		[sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
			[wdocument removeDocumentObjectWithObjectID: pieceID];
		} animationComplete:^(BOOL complete) {
			if (complete) {
				MADDesignerViewController *strongself2 = weakself2;
				[strongself2.view.scroller.container invalidateIntrinsicContentSize];
				[strongself2.view setNeedsUpdateConstraints];
			}
		} completion:^() {
			[weakself2 redrawAllElementViewsInCollectionView:sectionView];
			completion();
		}];
	}];
}

- (void)endPanPieceWithGesture:(UIPanGestureRecognizer *)gesture {
	
	MADDesignerElementView *piece = (MADDesignerElementView *)gesture.view;
	int64_t pieceIdentifier = piece.identifier;
	MADDesignerSectionView *sectionView = nil;
	
	for (UIView *subview in self.view.scroller.container.subviews) {
		if ([subview isKindOfClass:[MADDesignerSectionView class]]) {
			CGPoint location = [self.view convertPoint:gesture.view.frame.origin toView:subview];
			if ([subview pointInside:location withEvent:nil]) {
				piece.transform = CGAffineTransformIdentity;
				piece.alpha = 1.0;
				sectionView = (MADDesignerSectionView *)subview;
				break;
			}
		}
	}
	
	if (sectionView == nil) {
		CGFloat minDistance = CGFLOAT_MAX, distance;
		for (UICollectionView *view in self.view.scroller.container.subviews) {
			if ([view isKindOfClass: [MADDesignerSectionView class]]) {
				CGPoint p1 = [self.view convertPoint:gesture.view.frame.origin toView:self.view];
				CGPoint p2 = [self.view.scroller.container convertPoint:view.frame.origin toView:self.view];
				if ((distance = (CGFloat)MADDistance(p1, p2)) < minDistance) {
					sectionView = (MADDesignerSectionView *)view;
					minDistance = distance;
				}
			}
		}
		
		if (sectionView == nil) {
			for (UICollectionView *view in self.view.scroller.container.subviews) {
				if ([view isKindOfClass: [MADDesignerSectionView class]]) {
					sectionView = (MADDesignerSectionView *)view;
					break;
				}
			}
		}
	}
	
	CGPoint locationInSection = [self.view convertPoint: gesture.view.frame.origin
												 toView: sectionView];
	
	if (sectionView != nil) {
		
		NSNumber *sectionViewObjectIdTag = @(sectionView.identifier);
		RptqStoreContext *private = self.document.storeContext;

		RptqDocumentSection *documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																				   fromObjectContext:private];
		NSNumber *documentSectionKey = @(documentSection.identifier);
		CGFloat documentSectionHeight = documentSection.height;
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			[self.view.scroller.container updateSection:documentSectionKey height:documentSectionHeight];
			[self.view setNeedsUpdateConstraints];
			
			MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[sectionViewObjectIdTag];
			NSIndexPath *path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
													inSection: 0];
			[sectionView insertItemAtIndex:path update:^(){
				
				MADSectionLayoutAttributes *la = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
				la.objectID = pieceIdentifier;
				
				RptqStoreContext *context = self.document.storeContext;
				RptqDocumentSection *docSection = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																					  fromObjectContext:context];
				RptqDocumentElement *docObj = [RptqDocumentElement newDocumentElementWithIdentifier: pieceIdentifier
																				  fromObjectContext: context];
				CGSize documentObjectSize = [docObj sizeCalculated];
				la.frame = CGRectMake(locationInSection.x, locationInSection.y, documentObjectSize.width, documentObjectSize.height);
				[layoutManager addItem:la];
				[layoutManager layout];
				[piece removeFromSuperview];
				
				[docSection addDocumentObject: docObj
								withDropPoint: locationInSection
						 managedObjectContext: context];
				
				if ([context hasChanges]) {
					NSError *saveError = NULL;
					BOOL saved = [context save:&saveError];
					if (!saved && saveError != nil) {
						os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
					}
				}
			} animationComplete:^(BOOL complete) {
				if (complete) {
					[self.view.scroller.container invalidateIntrinsicContentSize];
					[self.view setNeedsUpdateConstraints];
				}
			} completion:^() {
				RptqStoreContext *context = self.document.storeContext;
				RptqDocumentSection *docSection = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																					  fromObjectContext:context];
				docSection.height = [sectionView intrinsicContentSize].height;
				if ([context hasChanges]) {
					NSError *saveError = NULL;
					BOOL saved = [context save:&saveError];
					if (!saved && saveError != nil) {
						os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
					}
				}
				[self redrawAllElementViewsInCollectionView:sectionView];
				[self.view setNeedsLayout];
			}];
		}];
	}
	[self setScrollersEnabled: YES];
	[piece setNeedsDisplay];
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		UIView *v = gestureRecognizer.view;
		CGPoint locationInView = [gestureRecognizer locationInView:v];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.view.scroller.container];
		locationInSuperview = [self.view.scroller.container convertPoint:locationInSuperview toView:self.view];
		v.layer.anchorPoint = CGPointMake(locationInView.x / v.bounds.size.width, locationInView.y / v.bounds.size.height);
		v.center = locationInSuperview;
	}
}

#pragma mark -
#pragma mark Display Helpers

- (void)relayoutSectionView:(MADDesignerSectionView *)documentSectionView {
	
	RptqStoreContext *private = self.document.storeContext;
	int64_t objectIdentifier = documentSectionView.identifier;
	CGFloat height;

	RptqDocumentSection *documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier: objectIdentifier
																			   fromObjectContext: private];
	height = documentSection.height;

	NSNumber *objectID = @(objectIdentifier);
	[self.view.scroller.container updateSection:objectID height:height];
	[self.view setNeedsUpdateConstraints];
}

- (void)setDisplayActive {
	[self setHidesStatusBar: NO];
	_sectionSettingsVisible = NO;
	_toolboxVisible = NO;
	
	MADTabBarController *tabBarController = (MADTabBarController *)self.navigationController.tabBarController;
	tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	[tabBarController enableTabBarItems];
}

- (void)setDisplayInactive {
	MADTabBarController *tabBarController = (MADTabBarController *)self.navigationController.tabBarController;
	tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	[tabBarController disableTabBarItems];
}

- (void)setScrollersEnabled:(BOOL)enabled {
	MADDesignerScrollView *scroller = self.view.scroller;
	@synchronized(scroller) {
		if ([scroller respondsToSelector:@selector(setScrollEnabled:)]) {
			scroller.scrollEnabled = enabled;
			[scroller flashScrollIndicators];
			for (UICollectionView *collectionView in (scroller.container).subviews) {
				if ([collectionView isKindOfClass: [UICollectionView class]]) {
					collectionView.scrollEnabled = enabled;
					[collectionView flashScrollIndicators];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Element View helpers

- (BOOL)dismissAllPopovers {
	BOOL result = NO;
	if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self deselectAllElementsAnimated:YES];
	}
	[self setDisplayActive];
	return result;
}

- (NSArray <MADDesignerElementView *> *)elementViewsInSection:(NSInteger)section
									   numberOfItemsInSection:(NSUInteger)numberOfItemsInSection
											 inCollectionView:(UICollectionView *)collectionView {
	MADDesignerElementView *elementView = nil;
	NSMutableArray <MADDesignerElementView *> *elementViews = [[NSMutableArray <MADDesignerElementView *> alloc] initWithCapacity:numberOfItemsInSection];
	for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
		elementView = [self elementViewAtIndexPath: [NSIndexPath indexPathForItem:(NSInteger)item inSection:section]
								  inCollectionView: collectionView];
		if (elementView != nil) [elementViews addObject:elementView];
	}
	return elementViews;
}

- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifier {
	MADDesignerSectionView *documentSectionView = nil;
	NSArray<__kindof UIView *> *subviews = self.view.scroller.container.subviews;
	for (UIView *subview in subviews) {
		if ([subview isKindOfClass:[MADDesignerSectionView class]]) {
			if (((MADDesignerSectionView *)subview).identifier == identifier) {
				documentSectionView = (MADDesignerSectionView *)subview;
				break;
			}
		}
	}
	return documentSectionView;
}

- (NSSet <UIView *> *)selectedElementViews {
	
	NSMutableSet <UIView *> *results = [[NSMutableSet alloc] init];
	if (self.selectedElementIDs.count > 0) {
		
		BOOL quickHashWorks = YES;
		for (NSNumber *selectedObjectId in self.selectedElementIDs) {
			UIView *selectedView = [self.elementViewsDictionary objectForKey:selectedObjectId];
			if (selectedView != nil) {
				[results addObject:selectedView];
			} else {
				quickHashWorks = NO;
			}
		}
		
		NSAssert(quickHashWorks, @"Maybe not such a good idea.");
		if (quickHashWorks == NO) {
			RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
			
			for (RptqDocumentSection *documentSection in sectionEnumerator) {
				MADDesignerSectionView *documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier];
				
				for (NSInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
					
					for (NSInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
						
						MADDesignerElementView *elementView = [self elementViewAtIndexPath: [NSIndexPath indexPathForItem:item inSection:section]
																		  inCollectionView: documentSectionView];
						if (elementView != nil && [self.selectedElementIDs containsObject: @(elementView.identifier)]) {
							[results addObject:elementView];
						}
					}
				}
			}
		}
	}
	return results;
}

- (MADDesignerSectionView *)getSectionViewForSectionID:(int64_t)sectionID {
	NSAssert([NSThread isMainThread], @"%s: Must run on main thread.", __PRETTY_FUNCTION__);
	return self.view.scroller.container.sectionViews[@(sectionID)];
}

- (MADDesignerSectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)section {
	NSAssert([NSThread isMainThread], @"%s: Must run on main thread.", __PRETTY_FUNCTION__);
	return self.view.scroller.container.sectionViews[@(section.identifier)];
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
	for (MADDesignerElementView *elementView in [self selectedElementViews]) {
		[self deselectElementView: elementView animated: animated];
	}
	
	[self.selectedElementIDs removeAllObjects];
	(self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
	
	[self.view.scroller.container removeBorderFromSections];
	
	[self.promptManager removeAll];
	[self displayPrompt];
}

- (void)displayPrompt {
}

- (MADDesignerElementView *)elementViewForManagedObject:(__kindof RptqDocumentElement *)managedObject {
	id elementView = [self.elementViewsDictionary objectForKey:@(managedObject.identifier)];
	if (elementView == nil) {
		elementView = [MADDesignerElementView newDesignerElementView: managedObject
												  tapGestureDelegate: self
														 tapSelector: @selector(handleToggleElementView:)];
	}
	return elementView;
}

#pragma mark -
#pragma mark Constraints Helpers

- (CGRect)detailDisplayFrame {
	return CGRectMake(DetailDisplayFrameOriginX(self.view.frame.size.width),
					  DetailDisplayFrameOriginY(self.view.safeAreaInsets.top),
					  MADSizeWidthViewDetailDisplay, MADSizeHeightViewDetailDisplay);
}

- (void)scrollToDetailSectionView {
	if (self.presentedViewController != nil) {
		self.hidesStatusBar = NO;
		[self.view.scroller scrollRectToVisible: self.view.scroller.container.sectionLabelDetail.frame
									   animated: YES];
	}
}

#pragma mark -
#pragma mark NSNotificationCenter Helpers

- (void)addObservers {
	MADocument *document = self.document;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidChange:)
												 name: RptqStoreContextObjectsDidChangeNotification
											   object: document.storeContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidSave:)
												 name: RptqStoreContextDidSaveNotification
											   object: document.storeContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(willHideMenuNotification:)
												 name: UIMenuControllerWillHideMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(didHideMenuNotification:)
												 name: UIMenuControllerDidHideMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(willShowMenuNotification:)
												 name: UIMenuControllerWillShowMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(didShowMenuNotification:)
												 name: UIMenuControllerDidShowMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(documentStateChanged)
												 name: UIDocumentStateChangedNotification
											   object: document];
}

- (void)removeObservers {
	
	MADocument *document = self.document;
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: RptqStoreContextObjectsDidChangeNotification
												  object: document.storeContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: RptqStoreContextDidSaveNotification
												  object: document.storeContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerWillHideMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerDidShowMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerWillShowMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerDidHideMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIDocumentStateChangedNotification
												  object: document];
}

#pragma mark -
#pragma mark Public IBActions

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action {
	
	if ([action.identifier isEqualToString:@"MTSegueNewDocumentObjectStaticLabelSaveIdentifer"]) {
		[self saveStaticLabel:action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:@"MTSegueChooseWhitespaceSaveIdentifer"]) {
		[self saveWhiteSpace];
		
	} else if ([action.identifier isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
		[self tableViewControllerChooseFieldDidFinish: action.sourceViewController
										  withFieldID: [action.sourceViewController queryFieldID]];
		
	} else if ([action.identifier isEqualToString:@"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer"]) {
		[self saveDynamicLabel: action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {
		[self saveAggregateLabel: action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:@"MTSegueNewDocumentObjectBarcodeSaveIdentifer"]) {
		[self saveBarcodeLabel: action.sourceViewController];
		
	}
	
	[self setDisplayActive];
}

- (IBAction)actionHideToolbox {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	self.hidesStatusBar = NO;
	
	__weak MADDesignerViewController *weakSelf = self;
	[self dismissViewControllerAnimated:YES completion:^{
		__strong MADDesignerViewController *sself = weakSelf;
		if (sself) {
			[sself actionDismiss];
			[sself setDisplayActive];
		}
	}];
}

@end
