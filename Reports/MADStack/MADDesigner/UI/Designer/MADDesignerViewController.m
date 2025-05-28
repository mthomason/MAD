//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController.h"
#import "MADViewControllerBarcodeDelegate.h"
#import "MADTabBarController.h"
#import "MADRulerView.h"
#import "MADDesignerElementView.h"
#import "MADDesignerElementTextView.h"
#import "MADDesignerElementView+Constructor.h"
#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"
#import "MADDesignerElementPickerViewController.h"
#import "MADCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MADDesignerSectionLayoutLiquid.h"
#import "MADDesignerSectionLayoutController.h"
#import "MADDesignerSectionBackground.h"
#import "MADManagedObjectCollectionView.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MADPopoverBackgroundView.h"
#import "MADToolboxPresentationController.h"
#import "MADDesignerStatusLabel.h"
#import "MADDesignerScrollView.h"
#import "MADPromptManager.h"
#import "MADQueryChooseFieldProtocol.h"
#import "MADQueryChooseFieldController.h"
#import "MADToolboxViewController.h"
#import "MADToolboxTransitioner.h"
#import "MADNavigationControllerToolbox.h"
#import "MADDesignerSectionLayoutLiquid.h"
#import "NSLayoutConstraint+Designer.h"
#import "UITapGestureRecognizer+Designer.h"
#import "MADNavigationController.h"
#import "UIViewController+tabBarItem.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADCellElementDelegate.h"
#import "MTViewControllerBarcode.h"
#import "MADElementPickerProtocol.h"
#import "MADDesignerLayoutDesignView.h"
#import "MADDesignerView.h"
#import "MADReportSectionDelegateProtocol.h"
#import "MADReportSectionsDataSource.h"
#import "MADThemeManager.h"
#import "madlog.h"

#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADResizeAspect.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <MADFoundation/MADStringUtilities.h>

#import <MAD/madmath.h>
#import <MAD/MADReportSection.h>
#import <MAD/MADocument.h>
#import <MAD/MADFont.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADSectionLayoutAttributes.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqSize.h>

#import <os/log.h>
#import <math.h>
#import <asl.h>

#import <UIKit/NSLayoutAnchor.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIImagePickerController.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIMenuController.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIPopoverPresentationController.h>

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSManagedObjectContext.h>

typedef NS_ENUM(NSUInteger, MTToolboxType) {
	MTToolboxTypeElement = 2,
	MTToolboxTypeSection = 3,
	MTToolboxTypeNone = 4,
};

static const CGFloat MADDefaultsPopooverWidth              = 320.0000f;
static const CGFloat MADDefaultsPopooverHeight             = 480.0000f;

static NSString * const MTSegueNewDocumentObjectStaticLabelSaveIdentifer    = @"MTSegueNewDocumentObjectStaticLabelSaveIdentifer";
static NSString * const MTSegueNewDocumentObjectDynamicLabelSaveIdentifer   = @"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer";
static NSString * const MTSegueChooseWhitespaceSaveIdentifer                = @"MTSegueChooseWhitespaceSaveIdentifer";
static NSString * const MTSegueChooseImageSaveIdentifer                     = @"MTSegueChooseImageSaveIdentifer";

static NSString * const MTIdentifierSegueEditFieldExit                      = @"MTIdentifierSegueEditFieldExit";
static NSString * const MTSegueNewDocumentObjectAggregateLabelSaveIdentifer = @"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer";
static NSString * const MTSegueNewDocumentObjectBarcodeSaveIdentifer        = @"MTSegueNewDocumentObjectBarcodeSaveIdentifer";

static const CGFloat MADSizeWidthViewDetailDisplay              = 32.0000f;
static const CGFloat MADSizeHeightViewDetailDisplay             = 20.0000f;

static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView);
static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView);
static inline CGFloat DetailDisplayFrameOriginX(CGFloat width);
static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop);
static const inline CGSize sizePopoverDefault(void);
static const inline CGSize sizePopoverFonts(void);

static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView) {
	return scrollView.contentSize.width * 0.5000f + MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5000f, 0.0000f);
}

static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView) {
	return scrollView.contentSize.height * 0.5000f + MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5000f, 0.0000f);
}
static inline CGFloat DetailDisplayFrameOriginX(CGFloat width) { return width - MADSizeWidthViewDetailDisplay - MTReportDesignerBorderPaddingDetail; }
static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop) { return CGPointZero.y + marginTop + MTReportDesignerBorderPaddingDetail; }
static const inline CGSize sizePopoverDefault(void) { return CGSizeMake(MADDefaultsPopooverWidth, 320.0); }
static const inline CGSize sizePopoverFonts(void) { return CGSizeMake(MADDefaultsPopooverWidth, MADDefaultsPopooverHeight); }

@interface MADDesignerViewController() <MADViewControllerBarcodeDelegate, MTViewControllerAggregateDelegate, MADCellElementDelegate, MADDesignerSectionLayoutLiquidDelegate, MADElementPickerProtocol, MADViewControllerStandardProtocol, MADDesignerSectionLayoutDelegate, MADQueryChooseFieldProtocol, MADDesignerDesignViewDelegate, UIPopoverPresentationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate>

	@property (null_resettable, nonatomic, strong) MADDesignerView *view;

	@property (nonatomic, strong) MADDesignerStatusLabel *statusLabelZoomScale;

	@property (nonatomic, strong) NSMutableSet <MADDesignerElementView *> *visibleElementViews;
	@property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedElementIDs;

	@property (nonatomic, strong) NSMutableDictionary <NSNumber *, __kindof MADDesignerElementView *> *elementViewsDictionary;
	@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView;

	@property (nonatomic, weak) MADDesignerElementView *lastElementViewToShowMenu;

	@property (nonatomic, strong) MADToolboxTransitioningDelegate *toolboxTransitioningDelegate;
	@property (nonatomic, strong) MADToolboxTransitioningDelegate *settingsTransitioningDelegate;

	@property (nonatomic, strong) NSNumberFormatter *numberFormatterPercentage;

	@property (nonatomic, strong) MADPromptManager *promptManager;

	@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerWidth;
	@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerLeft;

	@property (nonatomic, strong) MADToolboxViewController *viewControllerToolbox;
	@property (nonatomic, strong) MADDesignerSectionLayoutController *viewControllerSectionLayoutSettings;

	@property (nonatomic, strong) UINavigationController *navigationControllerToolbox;
	@property (nonatomic, strong) UINavigationController *navigationControllerSectionLayoutSettings;

	@property (nonatomic, assign) NSInteger lastSelectedSectionControlPanel;

	@property (nonatomic, strong) UIPopoverPresentationController *popoverToolbox;
	@property (nonatomic, strong) UIPopoverPresentationController *popoverObjectSelector;

	@property (nonatomic, copy) NSNumber *objectIdEditDynamicLabel;
	@property (nonatomic, copy) NSNumber *objectIdEditBarcode;     //Never set a value... never used????
	@property (nonatomic, copy) NSNumber *objectIdEditImage;
	@property (nonatomic, copy) NSNumber *barcodeToEditObjectID;
	@property (nonatomic, copy) NSManagedObjectID *aggregateToEditObjectID;

	@property (nonatomic, weak) UIGestureRecognizer *strayTouchGesture;
	@property (nonatomic, weak) UILabel *lastSelectedLabel;
	@property (nonatomic, weak) UIBarButtonItem *undoButton;

	@property (nonatomic, strong) MADReportSectionsDataSource *reportSectionDatasource;

@end

@implementation MADDesignerViewController {
	BOOL _editAggregate;
	BOOL _toolboxVisible;
	BOOL _sectionSettingsVisible;
	BOOL _insetsSetup;
	BOOL _shownAndHidden;
	BOOL _lastMenuItemSelectRequiresElementView;
	int64_t _identifierJustDisplayed;
	CGFloat _zoomScaleRestore;
	CGRect _boundsOnDisappear;
}

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
	MADDesignerViewController *controller = [[UIStoryboard storyboardWithName:@"MADDesigner"  bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
	[controller setDocument: document];
	return controller;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	_reportSectionDatasource = nil;
//    _layoutConstraintContainerWidth = nil;
}

#pragma mark -
#pragma mark Unwind Segue

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action {
	
	if ([action.identifier isEqualToString:MTSegueNewDocumentObjectStaticLabelSaveIdentifer]) {
		[self saveStaticLabel:action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:MTSegueChooseWhitespaceSaveIdentifer]) {
		[self saveWhiteSpace];
		
	} else if ([action.identifier isEqualToString:MTIdentifierSegueEditFieldExit]) {
		[self tableViewControllerChooseFieldDidFinish: action.sourceViewController
										  withFieldID: [action.sourceViewController queryFieldID]];
		
	} else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectDynamicLabelSaveIdentifer]) {
		[self saveDynamicLabel: action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectAggregateLabelSaveIdentifer]) {
		[self saveAggregateLabel: action.sourceViewController];
		
	} else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectBarcodeSaveIdentifer]) {
		[self saveBarcodeLabel: action.sourceViewController];
		
	}
	
	[self setDisplayActive];
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController *)fromViewController
							 sender:(nullable id)sender {
	return action == @selector(unwindToDesigner:);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if (self = [super initWithCoder:aDecoder]) {
		
		NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView;
		borderAppliedToView = [[NSMutableDictionary alloc] init];
		self.borderAppliedToView = borderAppliedToView;
		_identifierJustDisplayed = -1;
		_boundsOnDisappear = CGRectZero;
		_zoomScaleRestore = -1.0000f;
		_shownAndHidden = NO;
		_editAggregate = NO;
		_insetsSetup = NO;
		_toolboxVisible = NO;
		_sectionSettingsVisible = NO;

	}
	return self;
}

/*
#pragma mark -
#pragma mark UIStateRestore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
}
 */

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
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: self.viewControllerSectionLayoutSettings];
		navigationController.transitioningDelegate = self.settingsTransitioningDelegate;
		navigationController.modalPresentationStyle = UIModalPresentationCustom;
		navigationController.preferredContentSize = CGSizeMake(MADDefaultsPopooverWidth, 100.0000f);
		_navigationControllerSectionLayoutSettings = navigationController;
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
		MADDesignerSectionLayoutController *controller;
		controller = [MADDesignerSectionLayoutController newDesignerSectionLayoutController];
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
	tapGestureDoubleTap.delegate =  self;
	
	UIGestureRecognizer *tap = [MADTapGestureRecognizer newTapGestureRecognizerStrayTouchWithTarget: self
																							 action: @selector(handleTapStray:)
																						   delegate: self];
	[tap requireGestureRecognizerToFail:tapGestureDoubleTap];
	[self.view.scroller addGestureRecognizer:tap];
	self.view.scroller.delegate = self;
	self.strayTouchGesture = tap;
		
	
	NSLayoutConstraint *constraintContentLeft = [MADLayoutConstraint newLayoutConstraintView: self.view containerLeft: self.view.scroller.container];
	constraintContentLeft.priority = 999;
	NSLayoutConstraint *constraintContentRight = [MADLayoutConstraint newLayoutConstraintView: self.view containerRight: self.view.scroller.container];
	constraintContentRight.priority = 999;
	NSLayoutConstraint *constraintWidth = [MADLayoutConstraint newLayoutConstraintContent: self.view.scroller.container width: [self widthForCurrentZoom]];
	
	[self.view addConstraints:@[
		constraintContentLeft,
		constraintContentRight,
		[MADLayoutConstraint newLayoutConstraintView: self.view.scroller containerTop: self.view.scroller.container],
		[MADLayoutConstraint newLayoutConstraintScroller: self.view.scroller bottom: self.view.scroller.container],
		constraintWidth,
		[MADLayoutConstraint newLayoutConstraintViewScrollerTop: self.view.scroller view: self.view.scroller.container]
	]];

	self.layoutConstraintContainerLeft = constraintContentLeft;
	self.layoutConstraintContainerWidth = constraintWidth;

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
	CGFloat result;
	if (@available(iOS 11.0, tvOS 11.0, *)) {
		result = self.view.safeAreaLayoutGuide.layoutFrame.size.width / self.view.scroller.zoomScale;
	} else {
		result = self.view.frame.size.width / self.view.scroller.zoomScale;
	}
	return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
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
	[self.view.scroller setZoomScale: 1.0000f animated: NO];
	
	[self.view addSubview:self.statusLabelZoomScale];
	[self updateDisplayDetailZoomValue];
	
	MADReportSectionsDataSource *datasource = [[MADReportSectionsDataSource alloc] initWithManagedObjectContext:maDocument.managedObjectContext];
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
	
	UIEdgeInsets insets;
	
	// FIXME: This is not choosing the correct scroll inset...
	
	if (self.toolboxTransitioningDelegate.presentationController.presentedView.superview != nil &&
		self.presentedViewController.childViewControllers.count > 0 &&
		self.toolboxTransitioningDelegate.presentationController != nil &&
		!(self.presentingViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)) {
		
		insets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, CGSizeZero.width,
								  self.toolboxTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height,
								  CGSizeZero.width);
		
	} else if (self.settingsTransitioningDelegate.presentationController.presentedView.superview != nil &&
			   self.presentedViewController.childViewControllers.count > 0 &&
			   self.settingsTransitioningDelegate.presentationController != nil &&
			   !(self.presentingViewController.traitCollection.verticalSizeClass ==
																UIUserInterfaceSizeClassCompact)) {
		
		insets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, CGSizeZero.width,
								  self.settingsTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height,
								  CGSizeZero.width);
		
	} else {
		
		insets = UIEdgeInsetsMake(self.view.safeAreaInsets.top, CGSizeZero.width, self.view.safeAreaInsets.bottom, CGSizeZero.width);
		
	}
	
	//self.view.scroller.contentInset = self.view.safeAreaInsets;// insets;
	//self.view.scroller.scrollIndicatorInsets = self.view.safeAreaInsets;// insets;
	//self.view.scroller.contentInset = self.view.safeAreaInsets;// insets;
	//self.view.scroller.scrollIndicatorInsets = self.view.scroller.safeAreaInsets;// insets;

	//NSLog(@"%@", NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
	//NSLog(@"%@", NSStringFromUIEdgeInsets(self.view.scroller.container.safeAreaInsets));
	//NSLog(@"%@", NSStringFromUIEdgeInsets(self.view.scroller.safeAreaInsets));
	
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
	
	//self.view.scroller.contentInset = self.view.safeAreaInsets;// insets;
	//self.view.scroller.scrollIndicatorInsets = self.view.safeAreaInsets;// insets;
	
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
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) {
			[self.view setNeedsDisplay];
		};
	} else {
		transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) { };
	}
	[coordinator animateAlongsideTransition: transition completion: ^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[self adjustContextOffsetForOpenPopover];
		[self.view setNeedsUpdateConstraints];
	}];

}

/*- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
			  withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
	
	[super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
	
	if (self.isViewLoaded) {
		UIView __weak *titleView = self.navigationItem.titleView;
		[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			[titleView sizeToFit];
		} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			[titleView sizeToFit];
		}];
	}
	
}*/

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
					animated:(BOOL)animated {
	viewController.view.frame = navigationController.view.frame;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginZooming: (UIScrollView *)scrollView
						  withView: (UIView *)view {
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
			
			UIFont *font = [UIFont fontWithDescriptor: fontDescriptor
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
				controlView.contentScaleFactor =  scrollView.zoomScale * self.view.scroller.traitCollection.displayScale;
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
	NSString *message = [NSString stringWithFormat: NSLocalizedString(@"Scrolled to %@.", @"Scrolled to %@."), NSStringFromCGPoint(scrollView.contentOffset)];
	UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, message);
	[self.view setNeedsUpdateConstraints];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
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
							  withView: (UIView *)view
							   atScale: (CGFloat)scale {
	
	if ([scrollView isEqual:self.view.scroller]) {
		
		CGFloat scaleWithScreen = scale * scrollView.traitCollection.displayScale;
		self.view.scroller.container.ruler.contentScaleFactor = scaleWithScreen;
		//self.view.scroller.container.ruler.contentScaleFactor = scaleWithScreen;
		
		NSSet *elementViews = self.visibleElementViews;
		for (MADDesignerElementView *elementView in elementViews) {
			elementView.contentScaleFactor = scaleWithScreen;
		}
		UIFont *captionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
		CGFloat pointsize = captionFont.pointSize;
		
		NSArray <__kindof MADDesignerSectionLabel *> *sectionControlViewsArray;
		sectionControlViewsArray = self.view.scroller.container.sectionLabels.allValues;
		[sectionControlViewsArray enumerateObjectsWithOptions: NSEnumerationConcurrent
												   usingBlock: ^(__kindof MADDesignerSectionLabel * _Nonnull controlView, NSUInteger idx, BOOL * _Nonnull stop) {
													   
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				controlView.font = [captionFont fontWithSize:pointsize / scale];
				controlView.contentScaleFactor = scaleWithScreen;
				[controlView setNeedsDisplay];
			}];
			
		}];
		
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
#pragma mark MADDesignerSectionLayoutDelegate

- (void)sectionLayoutSettingsDidFinish:(MADDesignerSectionLayoutController *)controller {
	[self actionHideToolbox];
}

- (void)layoutSettings:(MADDesignerSectionLayoutController *)layoutSettings
		  newPageAfter:(BOOL)newPageAfter {
	
	NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
	private.parentContext = self.document.managedObjectContext;
	[private performBlock:^{
	
		RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
		RptqQuery *query =  database.hasQueries.anyObject;
		
		RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
															  withNumberOfGroups: query.hasQueryGroups.count];
		
		[section setProducesFormFeed: newPageAfter];
		if ([private hasChanges]) {
			NSError *error = NULL;
			BOOL saved = [private save:&error];
			if (!saved && error != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
			}
		}
	}];
	
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
	
	NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = self.document.managedObjectContext;
	NSDictionary <NSNumber *, MADDesignerSectionView *> *sectionViews = self.view.scroller.container.sectionViews;
	[private performBlock:^{
	
		RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
		RptqQuery *query =  database.hasQueries.anyObject;
		
		RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
															  withNumberOfGroups: query.hasQueryGroups.count];
		section.visibility = [NSNumber numberWithBool:isVisible];
		
		NSNumber *key = @(section.identifier);
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			MADDesignerSectionView *documentSectionView = sectionViews[key];
			documentSectionView.visible = isVisible;
		}];

		if ([private hasChanges]) {
			NSError *error = NULL;
			BOOL saved = [private save:&error];
			if (!saved && error != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
			}
		}
	}];
}

//FIXME: Unused... used to allow user to change the height of the sections.
- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = [database.hasQueries anyObject];
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
														  withNumberOfGroups: query.hasQueryGroups.count];

	UICollectionView *documentSectionView = [self getSectionViewForSectionID: section.identifier];
	CGSize collectionViewContentSize = [documentSectionView.collectionViewLayout collectionViewContentSize];
	[section setInterfaceHeight: collectionViewContentSize.height];
	
	if ([section.managedObjectContext hasChanges]) {
		NSError *error = NULL;
		BOOL saved = [section.managedObjectContext save:&error];
		if (!saved && error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		}
	}
	
	UICollectionView *collectionView = self.view.scroller.container.sectionViews[@(section.identifier)];
	[collectionView.backgroundView setNeedsDisplay];
	[documentSectionView.collectionViewLayout invalidateLayout];
	[section setInterfaceHeight: collectionViewContentSize.height];
	
	if ([section.managedObjectContext hasChanges]) {
		NSError *error = NULL;
		BOOL saved = [section.managedObjectContext save:&error];
		if (!saved && error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		}
	}
	
	[self.view setNeedsUpdateConstraints];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows {
	
	MADocument *doc = self.document;
	RptqDocument *document = doc.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
														  withNumberOfGroups: query.hasQueryGroups.count];
	
	BOOL insertNewSection = numberOfRows > section.numberOfRows;
	BOOL deleteLastSection = numberOfRows < section.numberOfRows;
	
	UICollectionView *documentSectionView = [self getSectionViewForSectionID: section.identifier];
	
	if (section.numberOfRows == (int64_t)numberOfRows) {
		// No change... do nothing
	} else if ((int64_t)numberOfRows > section.numberOfRows) {
		
		RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
																				inManagedObjectContext: doc.managedObjectContext];
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
															 [[NSMutableOrderedSet alloc] init];
		newRowToAppend.inSection = section;
		[hasRows addObject:newRowToAppend];
		section.hasRows = hasRows;
		
	} else if ((int64_t)numberOfRows < section.numberOfRows) {
		
		RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
		NSArray *hasRowsArray = section.hasRows.array;
		NSMutableOrderedSet *hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
															 [[NSMutableOrderedSet alloc] init];
		if ([hasRows count] > 0) {
			[hasRows.lastObject setInSection:nil];
			[hasRows removeObjectAtIndex:hasRows.count - 1];
			section.hasRows = hasRows;
			[rowToDelete setInSection:nil];
		}
	}
	
	section.numberOfRows = numberOfRows;
	NSManagedObjectID *sectionKey = section.objectID.copy;
	UICollectionView *collectionView = self.view.scroller.container.sectionViews[sectionKey];
	MADDesignerSectionBackground *backgroundView = (MADDesignerSectionBackground *)collectionView.backgroundView;
	[backgroundView setNumberOfRowsInBackground:numberOfRows];
	
	if ([doc.managedObjectContext hasChanges]) {
		NSError *error = NULL;
		[doc.managedObjectContext save:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		}
	}
	[doc updateChangeCount:UIDocumentChangeDone];
	[doc autosaveWithCompletionHandler:^(BOOL success) {
		if (insertNewSection) {
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)numberOfRows - 1];
			[documentSectionView insertSections:indexSet];
		} else if (deleteLastSection) {
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)numberOfRows];
			[documentSectionView deleteSections:indexSet];
		}
	}];
}

#pragma mark -
#pragma mark NSManagedObjectContextObjectsDidChangeNotification

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
	
	NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	
	for (NSManagedObject *updatedObject in updatedObjects) {
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
				} else if ([change isEqualToString:NSStringFromSelector(@selector(numberOfRows))]) {
					
				}
			}
		} else if ([updatedObject isKindOfClass:[RptqBorder class]]) {
			
		} else if ([updatedObject isKindOfClass:[RptqRect class]]) {
			
		} else if ([updatedObject isKindOfClass:[RptqNumericFormat class]]) {
			
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
#pragma mark NSManagedObjectContextDidSaveNotification

- (void)managedObjectContextDidSave:(NSNotification *)notification {
	NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	if (updatedObjects == nil) {
		os_log_error(GetDesignerLog(), "No updated objects in context save notification.");
		return;
	}
	for (NSManagedObject *object in updatedObjects) {
		if ([object isKindOfClass:[RptqDocumentElement class]]) {
			MADDesignerElementView *elementView = [self elementViewForManagedObject:(RptqDocumentElement *)object];
			[elementView updateForManagedObjectContent:notification.object];
		}
	}
}

#pragma mark - Menu Notifications

- (void)willHideMenuNotification:(NSNotification *)notification { }

- (void)didHideMenuNotification:(NSNotification *)notification {
	if (_lastMenuItemSelectRequiresElementView == NO) {
		MADDesignerElementView *lastElementViewToShowMenu = self.lastElementViewToShowMenu;
		if (lastElementViewToShowMenu) {
			[self deselectElementView: lastElementViewToShowMenu animated: YES];
			NSNumber *identifer = @(lastElementViewToShowMenu.identifier);
			[self.selectedElementIDs removeObject: identifer];
			(self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
		}
		self.lastElementViewToShowMenu = nil;
	}
	_lastMenuItemSelectRequiresElementView = NO;
}
- (void)didShowMenuNotification:(NSNotification *)notification { }
- (void)willShowMenuNotification:(NSNotification *)notification { }

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
				didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	// FIXME: Add ability to edit image fields.  84848422
	
	UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
	if (selectedImage == nil) {
		selectedImage = info[UIImagePickerControllerOriginalImage];
	}
	
	if (selectedImage != nil) {
		[self dismissViewControllerAnimated:YES completion:^{
			self.hidesStatusBar = NO;
		}];

		NSNumber *type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeImage];
		NSDictionary *defination;
		defination = [[NSDictionary alloc] initWithObjectsAndKeys:
					  type,           MTDocumentObjectDefinationType,
					  selectedImage,  MTDocumentObjectDefinationObject, nil];
		[self insertDocumentObjectWithDefination: defination];
	}
	
	[self setDisplayActive];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:NULL];
	[self setDisplayActive];
}

#pragma mark -
#pragma mark UIPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
															(UIPresentationController *)controller {
	return UIModalPresentationOverFullScreen;
}

- (UIViewController *)presentationController:(UIPresentationController *)controller
						viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
	
	UIViewController *result = nil;
	id presented = controller.presentedViewController;
	if (style != UIModalPresentationPopover && [presented isKindOfClass:[UINavigationController class]] == NO) {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
																					  target: self
																					  action: @selector(actionCancel:)];
		[controller.presentedViewController.navigationItem setLeftBarButtonItem: cancelButton
																	   animated: NO];
		controller.presentedViewController.view.backgroundColor = [UIColor clearColor];
		
		UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController: presented];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];
		result = navigation;
		
	} else if ([controller.presentedViewController isKindOfClass:[UINavigationController class]]) {
	
		if ([((UINavigationController *)controller.presentedViewController).topViewController
				isKindOfClass:[MADDesignerElementPickerViewController class]]) {
		
			UINavigationController *navigationController;
			navigationController = (UINavigationController *)controller.presentedViewController;

//???: Test one function, and uses another (topViewController)?
			if (navigationController.navigationItem.leftBarButtonItem == nil) {
				UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						target:self
																						action:@selector(actionCancel:)];
				[navigationController.topViewController.navigationItem setLeftBarButtonItem:cancel animated:NO];
			}
			
			UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
			visualEffectsView.frame = navigationController.view.bounds;
			visualEffectsView.autoresizingMask = MADViewAutoresizingFlexable();
			[navigationController.view insertSubview:visualEffectsView atIndex:0];
			result = navigationController;
		
		} else {
			result = controller.presentedViewController;
		}
		
	} else {
		result = controller.presentedViewController;
	}
	return result;
	
}

#pragma mark -
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
	popoverPresentationController.backgroundColor = nil;
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
	[self actionDismiss];
	[self setDisplayActive];
}

#pragma mark -
#pragma mark UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
	return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	return NO;
}

#pragma mark -
#pragma mark MADCellElement Delegate

- (MADPrintPageElementType)objectTypeRepresentedByCell:(MADCellElement *)cell {
	RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: cell.identifier
																	   fromObjectContext: _document.managedObjectContext];
	return element.type;
}

- (void)formatDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	[self deselectAllElementsAnimated:YES];
	_lastMenuItemSelectRequiresElementView = YES;
	
	__kindof MADDesignerElementView *elementView = [self.elementViewsDictionary objectForKey:@(cell.identifier)];
	[self selectElementView: elementView];
}

- (void)editDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	
	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	int64_t elementID = cell.identifier;
	private.parentContext = self.document.managedObjectContext;
	
	[private performBlock:^{
	
		RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: elementID
																				  fromObjectContext: private];
		RptqDocumentSection *section = documentObject.inSectionRow.inSection;
		MADDesignerSectionView *designerSectionView = [self getSectionViewForDocumentSection:section];
		int64_t designerSectionViewID = designerSectionView.identifier;
		section = [RptqDocumentSection newDocumentSectionWithIdentifier: designerSectionViewID
													  fromObjectContext: private];
		BOOL found = NO;
		
		NSOrderedSet *documentSectionHasRows = section.hasRows;
		for (RptqDocumentSectionRows *row in documentSectionHasRows) {
			
			NSMutableOrderedSet *hasObjects = row.hasObjects.mutableCopy;
			NSUInteger i = 0;
			for (RptqDocumentElement *object in hasObjects) {
				if (object.identifier == elementID) {
					found = YES;
					break;
				}
				i++;
			}
			
			if (found) {
				
				RptqDocumentElement *objectToEdit = hasObjects[i];
				
				switch (objectToEdit.type) {
						
					case MADPrintPageElementTypeAggregate: {
						dispatch_async(dispatch_get_main_queue(), ^{
							NSNumber *objectID  = @(objectToEdit.identifier);
							[self editDocumentObjectAggregateWithID: objectID
														   objectID: objectToEdit.objectID];
						});
						break;
					}
					
					case MADPrintPageElementTypeBarcode: {
						dispatch_async(dispatch_get_main_queue(), ^{
							NSNumber *objectID  = @(objectToEdit.identifier);
							[self editDocumentObjectBarcodeWithID: objectID];
						});
						break;
					}
					
					case MADPrintPageElementTypeImage: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectImage: objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeLabelDynamic: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectLabelDynamic:objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeLabelStatic: {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self editDocumentObjectLabelStatic:objectToEdit];
						});
						break;
					}
						
					case MADPrintPageElementTypeWhtiespace:
						break;
						
					default:
						break;
						
				}
			}
		}

		
	}];
	
}

#pragma mark MADCellElement Helpers

- (void)editDocumentObjectAggregateWithID:(NSNumber *)identifier
								 objectID:(NSManagedObjectID *)objectID {
	
	self.aggregateToEditObjectID = objectID.copy;
	_editAggregate = YES;

	MADDesignerViewController * __weak weakself = self;
	
	void (^updateAggregate)(void) = ^{
		
		MADDesignerViewController *strongself = weakself;
		if (!strongself) return;
		
		UIView *viewToEdit = [strongself.elementViewsDictionary objectForKey:identifier];
		UINavigationController *navigation = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeAggregateAdd];
		[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];

		MADocument *document = strongself.document;
		RptqDocumentElementAggregate *aggregateToEdit = [document.managedObjectContext objectWithID:objectID];
		
		MTDocumentObjectNewAggregateViewController *aggregateViewController = navigation.viewControllers.firstObject;
		aggregateViewController.document = document;
		aggregateViewController.aggregateDelegate = strongself;
		[aggregateViewController setAggregateObjectToEdit:aggregateToEdit];

		UIBarButtonItem *dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																				 target: strongself
																				 action: @selector(actionCancel:)];
		
		[aggregateViewController.navigationItem setRightBarButtonItem:dismiss animated:NO];
		[aggregateViewController.navigationItem setLeftBarButtonItem:nil animated:NO];
		
		navigation.modalPresentationStyle = UIModalPresentationPopover;
		navigation.preferredContentSize = sizePopoverFonts();
		
		UIPopoverPresentationController *popoverController;
		popoverController = navigation.popoverPresentationController;
		popoverController.delegate = strongself;
		popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
														toView: strongself.view.scroller.container];
		
		popoverController.sourceView = strongself.view.scroller.container;
		popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
		[strongself presentViewController:navigation animated:YES completion:nil];
		[strongself setDisplayInactive];
		
	};

	[[NSOperationQueue mainQueue] addOperationWithBlock:updateAggregate];
}

- (void)editDocumentObjectBarcodeWithID:(NSNumber *)objectID {
	
	self.barcodeToEditObjectID = objectID.copy;
	
	MADDesignerViewController * __weak weakself = self;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	
		MADDesignerViewController *strongself = weakself;
		if (!strongself) return;
		
		UIView *viewToEdit = [self.elementViewsDictionary objectForKey:objectID];

		MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
		barcodeViewController.document = strongself.document;
		barcodeViewController.delegate = strongself;
		barcodeViewController.preferredContentSize = sizePopoverFonts();
		barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
		barcodeViewController.bartcodeToEditObjectID = objectID.copy;

		UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
		popoverController.delegate = strongself;
		popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
														toView: strongself.view.scroller.container];
		popoverController.sourceView = strongself.view.scroller.container;
		popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
		[strongself presentViewController:barcodeViewController animated:YES completion:nil];
		[strongself setDisplayInactive];
	}];
	
}

- (void)editDocumentObjectBarcode:(RptqDocumentElement *)object {
	
	UIView *viewToEdit = [self.elementViewsDictionary objectForKey:@(object.identifier)];
	
	MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
	barcodeViewController.document = self.document;
	barcodeViewController.delegate = self;
	
	barcodeViewController.preferredContentSize = sizePopoverFonts();
	barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
	
	UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
													toView: self.view.scroller.container];
	popoverController.sourceView = self.view.scroller.container;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	[self presentViewController:barcodeViewController animated:YES completion:nil];
	[self setDisplayInactive];
}

- (void)editDocumentObjectImage:(RptqDocumentElement *)object {
	self.objectIdEditImage = object.objectID.copy;
}

- (void)editDocumentObjectLabelDynamic:(RptqDocumentElement *)object {
	
	self.objectIdEditDynamicLabel = @(object.identifier);
	
	UIView *viewToEdit = [self.view.scroller.container.sectionLabels objectForKey:self.objectIdEditDynamicLabel];
	
	MADQueryChooseFieldController *chooseFieldViewController;
	chooseFieldViewController = [MADQueryChooseFieldController newQueryBuilderChooseFieldViewController];
	chooseFieldViewController.document = self.document;
	chooseFieldViewController.delegate = self;
	
	chooseFieldViewController.modalPresentationStyle = UIModalPresentationPopover;
	chooseFieldViewController.preferredContentSize = sizePopoverFonts();
	
	UIPopoverPresentationController *popoverController;
	popoverController = chooseFieldViewController.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
													toView: self.view.scroller.container];
	popoverController.sourceView = self.view.scroller.container;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	[self presentViewController:chooseFieldViewController animated:YES completion:nil];
	[self setDisplayInactive];
}

- (void)editDocumentObjectLabelStatic:(RptqDocumentElement *)object {
	
	UIAlertController *alert;
	NSString *newText;
	
	newText = ((RptqDocumentElementLabel *)object).text.copy;
	
	void (^configureLabel)(UITextField *);
	configureLabel = ^(UITextField *textField) {
		textField.text = newText;
		textField.clearButtonMode = UITextFieldViewModeAlways;
	};

	void (^completion)(UIAlertAction *action, NSString *text) = ^(UIAlertAction *action, NSString *text) {
		((RptqDocumentElementLabel *)object).text = text.copy;
		if ([object.managedObjectContext hasChanges]) {
			NSError *error = NULL;
			BOOL saved = [object.managedObjectContext save:&error];
			if (!saved && error != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
			}
		}
	};
	
	alert = [MADAlertController newAlertControllerEditLabel: configureLabel
												 completion: completion];
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -
#pragma mark - MADViewControllerBarcodeDelegate

- (void)didUpdateBarcodeWithObjectID:(NSManagedObjectID *)barcodeObjectID
					   barcodeObject:(MTBarcode *)barcode
						withFieldOne:(NSManagedObjectID /* RptqQueryField */ *)fieldOne
						 andFieldTwo:(NSManagedObjectID /* RptqQueryField */ *)fieldTwo {
	
	UIManagedDocument *document = self.document;
	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = document.managedObjectContext;
	
	NSManagedObjectID *barcodeToEditObjectID = barcodeObjectID.copy;
	[private performBlock:^{
	
		RptqDocumentElementBarcode *barcodeToEdit = [private objectWithID:barcodeToEditObjectID];
		[barcodeToEdit updateWithBarcode: barcode field1ID: fieldOne field2ID: fieldTwo];
		if ([private hasChanges]) {
			NSError *error = NULL;
			[private save:&error];
			if (error != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
			}
		}
	}];
	[document updateChangeCount: UIDocumentChangeDone];
}

#pragma mark -
#pragma mark - MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType: (MTAggregateFunctionType)functionType
								inputType: (MTAggregateFunctionInputType)inputType
							  inputObject: (NSManagedObjectID *)objectID
								groupType: (MTAggregateGroupByType)groupType
							  groupNumber: (int32_t)groupNumber {
	UIManagedDocument *document = self.document;
	RptqDocumentElementAggregate *aggregateToEdit = [document.managedObjectContext objectWithID: self.aggregateToEditObjectID];
	[aggregateToEdit updateAggregateFunctionWithFunctionType: functionType
												   inputType: MTAggregateFunctionInputTypeField
												   groupType: groupType
										   aggregateObjectID: objectID
												 groupNumber: i32abs(groupNumber)];
	[document updateChangeCount: UIDocumentChangeDone];
}

#pragma mark -
#pragma mark - MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (NSManagedObjectID *)fieldID {

	NSManagedObjectContext *context = self.document.managedObjectContext;
	RptqQueryField *field = [context objectWithID: fieldID];
	RptqDocumentElementLabelDataField *documentObject = [RptqDocumentElementLabelDataField newDocumentElementWithIdentifier: field.identifier
																										  fromObjectContext: context];
	documentObject.referencesQueryField = field;
	if ([documentObject.managedObjectContext hasChanges]) {
		NSError *error = NULL;
		[documentObject.managedObjectContext save:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		}
	}
}

#pragma mark -
#pragma mark MADDesignerSectionLayoutLiquidDelegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView: (MADDesignerSectionView *)collectionView
				  cellForItemAtIndexPath: (NSIndexPath *)indexPath {
	
	MADocument *document = self.document;
	MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[@(collectionView.identifier)];
	
	__block MADSectionLayoutAttributes *attributes;
	[layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *object, BOOL *stop) {
		if (object.indexPath.section == indexPath.section &&
			object.indexPath.row == indexPath.row) {
			attributes = object;
			*stop = YES;
		}
	}];
	

	RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
																			  fromObjectContext: document.managedObjectContext];
	CGFloat contextScale = self.view.scroller.zoomScale * self.view.scroller.traitCollection.displayScale;
	NSString *resuseId = [MADCellElement reuseIdentifier];
	
	MADCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId forIndexPath:indexPath];
	cell.delegate = self;
	
	CGSize documentObjectSize = [documentObject sizeCalculated];
	CGRect cellBounds = CGRectMake(CGPointZero.x, CGPointZero.y, documentObjectSize.width, documentObjectSize.height);
	
	switch (documentObject.documentObjectType) {
		case MADPrintPageElementTypeFormula:
		case MADPrintPageElementTypeLabelStatic:
		case MADPrintPageElementTypeLabelDynamic:
		case MADPrintPageElementTypeAggregate:
		default: {
			
			NSArray *subviews = cell.contentView.subviews;
			for (id subview in subviews) {
				[subview removeFromSuperview];
			}
			int64_t identifier = documentObject.identifier;
			
			//cell.backgroundColor = [UIColor clearColor];
			cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
			
			MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
			NSNumber *elementViewIdentifier = @(identifier);
			[self.elementViewsDictionary setObject: elementView
											forKey: elementViewIdentifier];
			
			UIGestureRecognizer *panGesture, *pinchGesture;
			panGesture = [MADPanGestureRecognizer newPanGestureRecognizerElement: self
																		  action: @selector(handlePanPiece:)
																		delegate: self];
			[self.view.scroller.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
			[elementView addGestureRecognizer:panGesture];

			pinchGesture = [MADPinchGestureRecognizer newPinchGestureRecognizerElement: self
																				action: @selector(handlePinchPiece:)
																			  delegate: self];

			[self.view.scroller.pinchGestureRecognizer requireGestureRecognizerToFail:pinchGesture];
			[elementView addGestureRecognizer:pinchGesture];
			
			if (cell.frame.origin.x < 0.0f || cell.frame.origin.y < 0.0f) {
				cell.frame = cellBounds;
			} else {
				cell.bounds = cellBounds;
			}
			cell.identifier = documentObject.identifier;
			
			elementView.userInteractionEnabled = YES;
			cell.userInteractionEnabled = YES;
			cell.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.80];
			cell.contentView.backgroundColor = [[UIColor magentaColor] colorWithAlphaComponent:.50];
			elementView.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:.30];
			
			NSNumber *identifierNumber = @(identifier);
			if ([self.selectedElementIDs containsObject: identifierNumber]) {
				[self.view.scroller.container applyBorderToView:elementView];
			}
			
			[cell addElementView:elementView];
			
			if (_identifierJustDisplayed != -1) {
				
				if (_identifierJustDisplayed == identifier) {
					__typeof(self) __weak wself = self;
					if ([elementView conformsToProtocol:@protocol(MADViewAnimationProtocol)]) {
						//[elementView flash:^(BOOL finished) {
						//    if (finished) {
								typeof(self) sself = wself;
								if (sself) {
									sself->_identifierJustDisplayed = -1;
								}
						//    }
						//}];
					}
				}
				
			}
			
			if (cell) {
				cell.contentScaleFactor = contextScale;
				(cell.contentView).contentScaleFactor = contextScale;
			}
			
			elementView.contentScaleFactor = contextScale;
			break;
		}
	}
	return cell;
}

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView
		   viewForSupplementaryElementOfKind: (NSString *)kind
								 atIndexPath: (NSIndexPath *)indexPath {
	
	MTCollectionReuseableViewDefault *result = nil;
	
	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
		label.text = NSLocalizedString(@"Header", @"Header");
		[result addSubview:label];
	} else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
		label.text = NSLocalizedString(@"Footer", @"Footer");
		[result addSubview:label];
	} else {
		result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
													withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
														   forIndexPath: indexPath];
	}
	return result;
}

- (NSInteger)collectionView: (MADDesignerSectionView *)collectionView numberOfItemsInSection: (NSInteger)section {
	if (collectionView == nil) return 0;
	MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
	return (NSInteger)layoutManager.items.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView: (UICollectionView *)collectionView willDisplayCell: (MADManagedObjectCollectionViewCell *)cell forItemAtIndexPath: (NSIndexPath *)indexPath {
	
	__kindof MADDesignerElementView *elementView = nil;

	for (UIView *view in cell.contentView.subviews) {
		if ([view isKindOfClass:[MADDesignerElementView class]]) {
			elementView = (MADDesignerElementView *)view;
			break;
		}
	}

	if (cell.frame.origin.x < 0.0f || cell.frame.origin.y < 0.0f) {
		cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, cell.frame.size.width, cell.frame.size.height);
	}
	if (elementView) {
		[self.visibleElementViews addObject:elementView];
	}
	[self adjustPassthroughViews];
}

- (void)collectionView: (UICollectionView *)collectionView
  didEndDisplayingCell: (MADManagedObjectCollectionViewCell *)cell
	forItemAtIndexPath: (NSIndexPath *)indexPath {
	
	NSSet <__kindof MADDesignerElementView *> *elementViewSet;
	
	BOOL (^predicate)(id obj, BOOL *stop) = ^BOOL(__kindof MADDesignerElementView * _Nonnull obj, BOOL * _Nonnull stop) {
		if (obj.identifier == cell.identifier) {
			*stop = YES;
			return YES;
		} else {
			return NO;
		}
	};
	elementViewSet = [_visibleElementViews objectsPassingTest:predicate];
	
	[_visibleElementViews minusSet:elementViewSet];
	[self adjustPassthroughViews];
	
}

- (void)collectionView:(UICollectionView *)collectionView
	didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
					 forElementOfKind:(NSString *)elementKind
						  atIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath { }
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath { }
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath { }
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark -
#pragma mark MADReportSectionDelegate Protocol

- (void)designView:(MADDesignerLayoutDesignView *)designView handleTapStray:(UITapGestureRecognizer *)sender {
	if (sender.state != UIGestureRecognizerStateEnded) return;
	if (self.presentedViewController != nil) {
		[self actionHideToolbox];
	}
}

- (void)designView:(MADDesignerLayoutDesignView *)designView handleTapLabel:(UITapGestureRecognizer *)sender {
	
	if (sender.state != UIGestureRecognizerStateEnded) return;
	
	MADDesignerSectionLabel *label = (MADDesignerSectionLabel *)sender.view;
	[self dismissToolboxPresentationIfOpen];
	
	NSSet *selectedElementViews = [self selectedElementViews];
	
	BOOL hideToolbox = NO;
	if (selectedElementViews.count >= 1) {
		hideToolbox = YES;
	}
	
	self.viewControllerToolbox.document = self.document;
	
	if (label.selected) {
		[label normalView];
		hideToolbox = YES;
	} else {
		[self deselectAllElementsAnimated:YES];
		self.lastSelectedSectionControlPanel = label.tag;
		self.lastSelectedLabel = label;
		RptqDocumentSection *section = [self sectionForLabelTag:label.tag];
		MADDesignerSectionView *superView = [self getSectionViewForDocumentSection: section];
		superView.selected = YES;
		[label dimView];
		[_viewControllerSectionLayoutSettings updateDisplay:section.height
												 visibility:section.visibility
										   producesFormFeed:section.producesFormFeed
											   numberOfRows:section.numberOfRows];
		UIEdgeInsets hs = _viewControllerSectionLayoutSettings.tableView.horizontalScrollIndicatorInsets;
		UIEdgeInsets vs = _viewControllerSectionLayoutSettings.tableView.verticalScrollIndicatorInsets;
		_viewControllerSectionLayoutSettings.tableView.contentInset = UIEdgeInsetsMake(vs.top, hs.left, vs.bottom, hs.right);
		_viewControllerSectionLayoutSettings.tableView.verticalScrollIndicatorInsets = vs;
		_viewControllerSectionLayoutSettings.tableView.horizontalScrollIndicatorInsets = hs;
		[self actionShowSectionSettingsFromLabel:label];
		[self setDisplayInactive];
	}
	
	if (hideToolbox) {
		[self actionHideToolbox];
	}
}

#pragma mark -
#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
	[self setDisplayActive];
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark MADElementPickerProtocol

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
	[self setDisplayActive];
	[self insertDocumentObjectWithDefination: @{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort:MADPrintPageElementTypeLabelDynamic],
		MTDocumentObjectDefinationObject: field.objectID,
	}];
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
											   inputType:(MTAggregateFunctionInputType)inputType
											 inputObject:(NSManagedObjectID *)inputObject
											   groupType:(MTAggregateGroupByType)groupType
											 groupNumber:(NSNumber *)groupNumber {
	[self setDisplayActive];
	NSDictionary *documentObject = @{
		MTDocumentObjectDefinationAggregateType: [NSNumber numberWithShort: functionType],
		MTDocumentObjectDefinationAggregatePivotNumber: groupNumber,
		MTDocumentObjectDefinationAggregatePivotType: [NSNumber numberWithShort: groupType],
		MTDocumentObjectDefinationAggregateObjectId: inputObject,
		MTDocumentObjectDefinationAggregateFunctionInputType: [NSNumber numberWithShort: inputType],
	};

	[self insertDocumentObjectWithDefination: @{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort: MADPrintPageElementTypeAggregate],
		MTDocumentObjectDefinationObject: documentObject,
	}];
	self.hidesStatusBar = NO;
}


- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
	[self setDisplayActive];
	[self insertDocumentObjectWithDefination:@{
		MTDocumentObjectDefinationType: [NSNumber numberWithShort: MADPrintPageElementTypeLabelStatic],
		MTDocumentObjectDefinationObject: labelText,
	}];
}

#pragma mark -
#pragma mark Gesture Recognizer Delegate

/*
	Simultaneously    Require       Should be required      Delays Touches
	recognize    failure of ___    to fail by ___
	-------------------------------------------------------------------------
	Pan Backgournd              -   Scroll designer -   Vertical        - YES
	Pan Section View            -   Scroll section  -   Horizontal      - YES
	Pan Element View            -   Move element                        -  NO
 
	Single Tap Background       -   Tap away                            -  NO   (...everything else)
	Single Tap Section View     -   Tap away                            -  NO   (...everything else)
	Single Tap Element View     -   Select element, deselect sections   -  NO   (pan element view)
	Single Tap Section Label    -   Select section, deselect elements   -  NO
 
	Double Tap Background       -   Zoom                                -  NO
	Pinch Background            -   Zoom                                -  NO
	Pinch Element View          -   Resize                              -  NO
 
 */

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
	   shouldReceiveTouch: (UITouch *)touch {
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	
	BOOL panGesture = [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
	BOOL elementView = [gestureRecognizer.view isKindOfClass:[MADDesignerElementView class]];
	BOOL simultaneously = panGesture && !elementView;
	if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
		simultaneously = NO;
	}
	//Simultaneus if pan gesture that is not attached to element view
	return simultaneously;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return YES;
}

#pragma mark -
#pragma mark Actions

- (void)edit:(id)sender { }

#pragma mark -
#pragma mark MADDesignerSectionLayoutLiquidDelegate

- (void)collectionView: (MADDesignerSectionView *)collectionView
		 prepareLayout: (UICollectionViewLayout *)collectionViewLayout {
	MADocument *document = self.document;
	MADSectionLayoutManager *layoutManager;
	NSNumber *identifier = @(collectionView.identifier);
	layoutManager = document.sectionLayoutManagers[identifier];
	NSManagedObjectContext *objectContext = document.managedObjectContext;
	RptqDocumentElement *documentObject;
	
	for (MADSectionLayoutAttributes *attributes in layoutManager.items.allValues) {
		documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
															 fromObjectContext: objectContext];
		[documentObject setOriginPoint:attributes.frame.origin];
	}
}

- (MADSectionLayoutAttributes *)collectionView: (MADDesignerSectionView *)collectionView
										layout: (UICollectionViewLayout *)collectionViewLayout
			layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
	
	MADSectionLayoutManager *layoutManager;
	NSNumber *identifier = @(collectionView.identifier);
	layoutManager = self.document.sectionLayoutManagers[identifier];
	__block MADSectionLayoutAttributes *item;
	[layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id key,
															 MADSectionLayoutAttributes *object,
															 BOOL *stop) {
		if (object.indexPath.item == indexPath.item &&
			object.indexPath.section == indexPath.section) {
			item = object;
			*stop = YES;
		}
	}];
	return item;
	
}

- (NSUInteger)numberOfItemsInSection: (NSUInteger)section
					ofCollectionView: (MADDesignerSectionView *)collectionView {
	MADSectionLayoutManager *layoutManager;
	NSNumber *identifier = @(collectionView.identifier);
	layoutManager = self.document.sectionLayoutManagers[identifier];
	return layoutManager.items.count;
}

- (NSArray *)collectionView: (MADDesignerSectionView *)collectionView
		attributesForLayout: (UICollectionViewLayout *)collectionViewLayout {
	MADSectionLayoutManager *layoutManager;
	NSNumber *identifier = @(collectionView.identifier);
	layoutManager = self.document.sectionLayoutManagers[identifier];
	return layoutManager.items.allValues;
}

- (CGSize)collectionView: (MADDesignerSectionView *)collectionView
		   sizeForLayout: (UICollectionViewLayout *)collectionViewLayout {
	MADSectionLayoutManager *layoutManager;
	NSNumber *identifier = @(collectionView.identifier);
	layoutManager = self.document.sectionLayoutManagers[identifier];
	return layoutManager.size;
}

#pragma mark -
#pragma mark Gesture Recognizer Handlers

- (void)handlePinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
	
	MADDesignerElementView *piece = ((MADDesignerElementView *)gestureRecognizer.view);
	RptqDocumentElement *element;
	element = [RptqDocumentElement newDocumentElementWithIdentifier: piece.identifier
												  fromObjectContext: _document.managedObjectContext];
	
	if (gestureRecognizer.numberOfTouches > 1) {
		CGPoint p1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
		CGPoint p2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
		MADCompassDirection direction = MADSpecificDirectionOfDegrees(CGAngleBetweenTwoPoints(p1, p2));
		struct MADResizeAspect resizeAspect = MADResizeTypeForDirection(direction);

		switch (resizeAspect.direction) {

			case horizontal:
				[element setSizeWidth:(float)(element.sizeContentView.width * gestureRecognizer.scale)];
				break;

			case vertical:
				[element setSizeHeight:(float)(element.sizeContentView.height * gestureRecognizer.scale)];
				break;
				
			default: {
				CGSize s = element.sizeContentView;
				[element setSizeWidth:(float)(s.width * gestureRecognizer.scale)
							   height:(float)(s.height * gestureRecognizer.scale)];
				break;
			}
		
		}

	}
	gestureRecognizer.scale = 1.0000f;
	if ([element.managedObjectContext hasChanges]) {
		NSError *error = NULL;
		[element.managedObjectContext save:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, error);
		}
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
			
			// Select a unselected element
			[self.promptManager addString: elementView.textRepresentation];
			[self displayPrompt];
			
			if (self.selectedElementIDs.count == 1) {    // Show toolbox if we are selecting the first item.
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
				
				[self actionHideToolbox];         // Hide toolbox location
				
			} else {
				
				[self adjustToolboxLocation];
				[self setDisplayInactive];
			}
		}
	}
}

#pragma mark -
#pragma mark Save after Unwind from Modal View Controller

- (void)saveStaticLabel:(MTDocumentObjectNewStaticLabelViewController *)viewController {
	[self insertDocumentObjectNewLabel: viewController.textField.text];
	[self scrollToDetailSectionView];
}

- (void)saveWhiteSpace {
	NSNumber *type;
	NSDictionary *options;

	type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeWhtiespace];
	options = [[NSDictionary alloc] initWithObjectsAndKeys:
											type, MTDocumentObjectDefinationType, nil];
											
	[self insertDocumentObjectWithDefination: options];
	[self scrollToDetailSectionView];
}

- (void)saveDynamicLabel:(MADQueryChooseFieldController *)viewController {
	
	MADQueryChooseFieldController *dynamicFieldController;
	dynamicFieldController = (MADQueryChooseFieldController *)viewController;
 
	NSManagedObjectID *objectID = dynamicFieldController.queryFieldID.copy;

	NSNumber *keyDynamic = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeLabelDynamic];
	NSDictionary *definations = [[NSDictionary alloc] initWithObjectsAndKeys:
									keyDynamic, MTDocumentObjectDefinationType,
									objectID, MTDocumentObjectDefinationObject, nil];
	
	[self insertDocumentObjectWithDefination: definations];
	
	[self scrollToDetailSectionView];
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
	
	if (_editAggregate && _aggregateToEditObjectID != nil) {
		
		if (viewController.fieldObjectID != nil) {
			UIManagedDocument *document = self.document;
			RptqDocumentElementAggregate *aggregateToEdit;
			aggregateToEdit = [document.managedObjectContext objectWithID: _aggregateToEditObjectID];
			[aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
																inputType: MTAggregateFunctionInputTypeField
																groupType: viewController.aggregateGroupByType
														aggregateObjectID: viewController.fieldObjectID
															  groupNumber: viewController.groupTypeSectionNumber];
			[document updateChangeCount: UIDocumentChangeDone];
		}
		
	} else {
		if (viewController.fieldObjectID != nil) {
		
			NSNumber *groupNumber;
			groupNumber = [[NSNumber alloc] initWithInteger:viewController.groupTypeSectionNumber];
			
			[self insertDocumentObjectNewAggregateFunctionWithType: viewController.aggregateFunctionType
														 inputType: MTAggregateFunctionInputTypeField
													   inputObject: viewController.fieldObjectID
														 groupType: viewController.aggregateGroupByType
													   groupNumber: groupNumber];
			
		}
	}
	[self scrollToDetailSectionView];
}

- (void)saveBarcodeLabel:(MTViewControllerBarcode *)viewController {
	
	if (_objectIdEditBarcode  != nil) {
		UIManagedDocument *document = self.document;
		MTBarcode *barcode = viewController.barcode;
		
		NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
		RptqDocumentElementBarcode *object;
		object = [RptqDocumentElementBarcode newDocumentElementWithIdentifier: _objectIdEditBarcode.longLongValue
															fromObjectContext: managedObjectContext];

		[object updateWithBarcode: barcode
						 field1ID: viewController.queryField1ID
						 field2ID: viewController.queryField2ID];
		[document updateChangeCount: UIDocumentChangeDone];
		_objectIdEditBarcode = nil;
		
	} else {
		
		NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
		NSNumber *type = [[NSNumber alloc] initWithShort: MADPrintPageElementTypeBarcode];
		defination[MTDocumentObjectDefinationType] = type;
		defination[MTDocumentObjectDefinationObject] = viewController.barcode;
		
		NSManagedObjectID *queryField1ID = viewController.queryField1ID;
		if (queryField1ID != nil) {
			defination[MTDocumentObjectDefinationField1] = queryField1ID.copy;
		}
		
		NSManagedObjectID *queryField2ID = viewController.queryField2ID;
		if (queryField2ID != nil) {
			defination[MTDocumentObjectDefinationField2] = queryField2ID.copy;
		}
		[self insertDocumentObjectWithDefination: defination];
		
	}
	[self scrollToDetailSectionView];
}

#pragma mark -
#pragma mark Helpers

- (BOOL)elementViewIsSelected:(MADDesignerElementView *)elementView {
	NSNumber *elementViewIdentifier = @(elementView.identifier);
	return [self.selectedElementIDs containsObject:elementViewIdentifier];
}

- (void)adjustContextOffsetForToolboxWithToolboxType:(MTToolboxType)toolboxType {
	switch (toolboxType) {
		case MTToolboxTypeSection:
			[self adjustContentOffsetForLastSelectedSectionControlPanel];
			break;
		case MTToolboxTypeElement:
			[self adjustContentOffsetForSelectedElements];
			break;
		default:
			break;
	}
}

- (void)adjustContentOffsetForSelectedElements {
	if (_toolboxTransitioningDelegate.presentationController.presentedViewController != nil && [_toolboxTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		CGRect frame = ((MADToolboxTransitioningDelegate *)_toolboxTransitioningDelegate).presentationController.presentedViewController.view.frame;
		CGRect bounds = [self.view.scroller positionForRectOfInterest: [self rectForSelectedElements]
													withPresentedRect: frame
														containerSize: self.view.frame.size
														   adjustment: self.view.safeAreaInsets.top];
		[self.view.scroller.container repositionSectionViews:bounds];
	}
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanel {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqQuery *query = document.defaultDatabase.defaultQuery;
	RptqDocumentSection *documentSection;
	documentSection = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
											 withNumberOfGroups: query.hasQueryGroups.count];

	
	UIView *selectedSectionView = [self getSectionViewForDocumentSection:documentSection];
	if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
		[self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
		CGRect presentedRect = ((MADToolboxTransitioningDelegate *)self.settingsTransitioningDelegate).
		presentationController.presentedViewController.view.frame;
		CGRect position = [self.view.scroller positionForRectOfInterest: selectedSectionView.frame
													  withPresentedRect: presentedRect
														  containerSize: self.view.frame.size
															 adjustment: self.view.safeAreaInsets.top];
		[self.view.scroller.container repositionSectionViews:position];
	}
}

- (void)selectElementView:(__kindof MADDesignerElementView *)elementView {
	if (self.view.scroller.container.selectedSections.count > 0) {
		[self.view.scroller.container removeBorderFromAllSectionViews];
	} else {
		
		NSNumber *key = @(elementView.identifier);
		[self.selectedElementIDs addObject: key];
		
		[self.view.scroller.container applyBorderToView:elementView];
		
		self.viewControllerToolbox.document = self.document;
		self.viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
	}
}

- (void)deselectElementView:(MADDesignerElementView *)elementView
				   animated:(BOOL)animated {
	[self.view.scroller.container removeBorderFromView: elementView];
	NSArray <UIView *> *passThroughViewsArray = self.popoverToolbox.passthroughViews;
	if (passThroughViewsArray != nil) {
		NSMutableSet <UIView *>  * _Nullable passThroughViewsSet = [[NSMutableSet alloc] initWithArray: passThroughViewsArray];
		[passThroughViewsSet removeObject: elementView];
		self.popoverToolbox.passthroughViews = passThroughViewsSet.allObjects;
	}
}

- (RptqDocumentSection *)sectionForLabelTag:(NSInteger)tag {
	RptqDocument *document = self.document.activeDocumentModel;
	RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
	RptqQuery *query = database.hasQueries.anyObject;
	RptqDocumentSection *section;
	section = [document documentSectionForSelectedIndex: (NSUInteger)_lastSelectedSectionControlPanel
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
	for (id elementView in subviews) {
		if ([elementView isKindOfClass:[MADDesignerElementView class]]) {
			result = elementView;
			break;
		}
	}
	return result;

}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {
	
	[self setDisplayActive];
	
	MADocument *document = self.document;
	RptqDocument *rptqDocument = document.activeDocumentModel;
	
	MADDesignerSectionView *collectionView;
	MADSectionLayoutManager *layoutManager;

	collectionView = [self getSectionViewForDocumentSection: rptqDocument.hasDetailSection];
	NSNumber *identifier = [[NSNumber alloc] initWithLongLong:collectionView.identifier];
	layoutManager = document.sectionLayoutManagers[identifier];
	
	NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
	MADDesignerViewController * __weak weakself = self;
	[collectionView performBatchUpdates:^{

		RptqDocument *bgRptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: managedObjectContext];
		RptqDocumentSection *bgSection = rptqDocument.hasDetailSection;
		
		MADDesignerViewController * sself = weakself;
		
		NSIndexPath *path;
		NSArray *indexPathsInserted;
		MADSectionLayoutAttributes *layoutAttribute;
		RptqDocumentElement *element = [bgRptqDocument addDocumentObject: documentObjectDefination
													managedObjectContext: managedObjectContext];

		NSArray *objects = [[NSArray alloc] initWithObjects:element, nil];

		NSError * __autoreleasing error = NULL;
		if (![managedObjectContext obtainPermanentIDsForObjects: objects
														  error: &error]) {
			os_log_error(OS_LOG_DEFAULT, "Error getting permanent IDs: %s" , error.localizedDescription.UTF8String);
		}
		
		path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
								   inSection: 0];
		
		sself->_identifierJustDisplayed = element.identifier;
		
		layoutAttribute.frame = [element elementViewFrameDesignerFrameCalculated];
		
		indexPathsInserted = [[NSArray alloc] initWithObjects: path, nil];
		[bgSection addDocumentObject: element
					   withDropPoint: layoutAttribute.frame.origin
				managedObjectContext: managedObjectContext];
		
		[collectionView insertItemsAtIndexPaths: indexPathsInserted];

		if ([managedObjectContext hasChanges]) {
			NSError *saveError = NULL;
			[managedObjectContext save:&saveError];
			if (saveError != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
			}
		}

		layoutAttribute = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
		layoutAttribute.objectID = element.identifier;
		
		[layoutManager addItem:layoutAttribute];
		[layoutManager layout];

	} completion:^(BOOL finished) {
		typeof(self) strongself = weakself;
		MADocument *doc = strongself.document;
		[strongself.view.scroller.container setNeedsUpdateConstraints];
		[doc updateChangeCount: UIDocumentChangeDone];
		[doc autosaveWithCompletionHandler:^(BOOL success) { }];
	}];
}

- (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell {
	int64_t cellIdentifier = cell.identifier;
	NSNumber *objectId = @(cell.identifier);
	
	MADocument *document;
	NSArray *elements;
	__kindof RptqDocumentElement *element;
	MADDesignerSectionView *sectionView;
	MADSectionLayoutManager *layoutManager;
	MADSectionLayoutAttributes *itemToRemove;
	
	document = _document;
	NSFetchRequest <__kindof RptqDocumentElement *> *fetchElement;
	fetchElement = [RptqDocumentElement fetchRequestElement:cell.identifier];
	NSError *error = nil;
	elements = [self.document.managedObjectContext executeFetchRequest: fetchElement
																 error: &error];
	if (error != nil) {
		os_log_error(GetDesignerLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
	}

	element  = elements.firstObject;
	sectionView = [self getSectionViewForDocumentSection:element.inSectionRow.inSection];
	NSNumber *sectionIdentifier = [[NSNumber alloc] initWithLongLong:sectionView.identifier];
	layoutManager = document.sectionLayoutManagers[sectionIdentifier];
	itemToRemove = (layoutManager.items)[objectId];
		
	[sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
	
		MADocument *maDocument = self.document;
		[maDocument removeDocumentObjectWithObjectID: cellIdentifier];
	
	} animationComplete:^(BOOL complete) {

		if (complete) {
			[self.view.scroller.container invalidateIntrinsicContentSize];
			[self.view setNeedsUpdateConstraints];
		}
		
	} completion:^() {

		[self redrawAllElementViewsInCollectionView:sectionView];
		RptqDocumentElement *elementB = [RptqDocumentElement newDocumentElementWithIdentifier:cellIdentifier
																			fromObjectContext:document.managedObjectContext];
		[document.managedObjectContext deleteObject:elementB];
		if ([document.managedObjectContext hasChanges]) {
			NSError *saveError = NULL;
			[document.managedObjectContext save:&saveError];
			if (saveError != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
			}
		}
	}];
}

- (CGRect)rectForSelectedElements {
	NSSet <UIView *> *views = [self selectedElementViews];
	return [self.view.scroller.container popoverRectForSelectedViews:views];
}

- (void)adjustContextOffsetForOpenPopover {
	if ([self padLike]) {
		if (_sectionSettingsVisible &&
			self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
			
			[self adjustSettingsLocation];
			
		} else if (_toolboxVisible &&
				   self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
			
			[self adjustToolboxLocation];
			
		}
	}
}

- (void)adjustPassthroughViews {
	
	if (_sectionSettingsVisible) {
		self.settingsTransitioningDelegate.passthroughContainers =  self.view.scroller.container.passthroughContainers;
		self.settingsTransitioningDelegate.passthroughViews =       [self passthroughViews];
		self.settingsTransitioningDelegate.passthroughContainer =   self.view.scroller;
	} else if (_toolboxVisible) {
		self.toolboxTransitioningDelegate.passthroughContainers =   self.view.scroller.container.passthroughContainers;
		self.toolboxTransitioningDelegate.passthroughViews =        [self passthroughViews];
		self.toolboxTransitioningDelegate.passthroughContainer =    self.view.scroller;
	}
	
}

- (void)dismissSectionPresentationIfOpen {
	if (_sectionSettingsVisible && self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
		_sectionSettingsVisible = NO;
		[self dismissViewControllerAnimated: YES completion: NULL];
		[self.view.scroller.container removeBorderFromAllSectionViews];

		__strong MADocument *document = self.document;
		if ([document.managedObjectContext hasChanges]) {
			NSError *saveError = NULL;
			[document.managedObjectContext save:&saveError];
			if (saveError != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
			}
		}
	}
}

- (void)dismissToolboxPresentationIfOpen {
	if (_toolboxVisible &&
		self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
		_toolboxVisible = NO;
		[self dismissViewControllerAnimated: YES completion: NULL];
		[self deselectAllElementsAnimated:YES];
		
		__strong MADocument *document = self.document;
		if ([document.managedObjectContext hasChanges]) {
			NSError *saveError = NULL;
			[document.managedObjectContext save:&saveError];
			if (saveError != nil) {
				os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
			}
		}
	}
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
	}];
	[self.view.scroller.container bringSubviewToFront: piece];

	int64_t pieceID = piece.identifier;

	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = _document.managedObjectContext;
	
	MADDesignerViewController __weak *weakself = self;
	[private performBlockAndWait:^{
		MADDesignerViewController *strongself = weakself;
		if (!strongself) return;
		
		RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: pieceID
																				  fromObjectContext: private];
		NSNumber *sectionIdentifier = @(documentObject.inSectionRow.inSection.identifier);

		MADDesignerViewController __weak *weakself1 = strongself;
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		   
			MADDesignerViewController *strongself1 = weakself1;
			
			MADDesignerSectionView *sectionView = strongself1.view.scroller.container.sectionViews[sectionIdentifier];
			CGRect b = [strongself1.view convertRect:piece.frame fromView:sectionView];
			piece.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, b.size.width, b.size.height);
			[strongself1.view addSubview: piece];
			
			[UIView animateWithDuration:0.2 animations:^{
				piece.alpha = 0.8;
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
		
	}];
}

- (void)endPanPieceWithGesture:(UIPanGestureRecognizer *)gesture {

	MADDesignerElementView *piece = (MADDesignerElementView *)gesture.view;
	//NSNumber *pieceObjectIdTag = @(piece.identifier);
	int64_t pieceIdentifier = piece.identifier;
	MADDesignerSectionView *sectionView = nil;

	for (UIView *subview in self.view.scroller.container.subviews) {
		if ([subview isKindOfClass:[MADDesignerSectionView class]]) {
			CGPoint location = [self.view convertPoint:gesture.view.frame.origin toView:subview];
			if ([subview pointInside:location withEvent:nil]) {
				piece.transform = CGAffineTransformIdentity;
				piece.alpha = 1.0000f;
				sectionView = (MADDesignerSectionView *)subview;
				break;
			}
		}
	}
	
	//Section not found, so add to the first one.
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
		NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		private.parentContext = self.document.managedObjectContext;
		[private performBlockAndWait:^{

			RptqDocumentSection *documentSection;
			documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																  fromObjectContext:private];
			NSNumber *documentSectionKey = @(documentSection.identifier);
			CGFloat documentSectionHeight = documentSection.height;
			
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
				[self.view.scroller.container updateSection:documentSectionKey height:documentSectionHeight];
				[self.view setNeedsUpdateConstraints];
				
				MADSectionLayoutManager *layoutManager;
				layoutManager = self.document.sectionLayoutManagers[sectionViewObjectIdTag];
				NSIndexPath *path;
				path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
										   inSection: 0];
				[sectionView insertItemAtIndex:path update:^(){
					
					MADSectionLayoutAttributes *la = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
					la.objectID = pieceIdentifier;
					
					NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;

					RptqDocumentSection *documentSectionBlock;
					RptqDocumentElement *documentObject;

					documentSectionBlock = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																			   fromObjectContext:managedObjectContext];
					documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: pieceIdentifier
																		 fromObjectContext: managedObjectContext];

					
					CGSize documentObjectSize = [documentObject sizeCalculated];
					
					la.frame = CGRectMake(locationInSection.x, locationInSection.y, documentObjectSize.width, documentObjectSize.height);
					[layoutManager addItem:la];
					[layoutManager layout];
					[piece removeFromSuperview];
					
					[documentSectionBlock addDocumentObject: documentObject
											  withDropPoint: locationInSection
									   managedObjectContext: managedObjectContext];

					if ([managedObjectContext hasChanges]) {
						NSError *saveError = NULL;
						BOOL saved = [managedObjectContext save:&saveError];
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
					
					NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
					

					RptqDocumentSection *sectionBlock;
					sectionBlock = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
																	   fromObjectContext:managedObjectContext];

					CGFloat sectionViewIntrinsicContentSizeHeight = [sectionView intrinsicContentSize].height;
					sectionBlock.height = sectionViewIntrinsicContentSizeHeight;
					if ([managedObjectContext hasChanges]) {
						NSError *saveError = NULL;
						BOOL saved = [managedObjectContext save:&saveError];
						if (!saved && saveError != nil) {
							os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
						}
					}
					[self redrawAllElementViewsInCollectionView:sectionView];
					[self.view setNeedsLayout];
					
					
				}];
			}];
		}];
	}
	[self setScrollersEnabled: YES];
	[piece setNeedsDisplay];
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		UIView *piece = gestureRecognizer.view;
		CGPoint locationInView = [gestureRecognizer locationInView:piece];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.view.scroller.container];
		locationInSuperview = [self.view.scroller.container convertPoint:locationInSuperview toView:self.view];
		piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
		piece.center = locationInSuperview;
	}
}

#pragma mark -
#pragma mark Display Helpers

- (void)relayoutSectionView:(MADDesignerSectionView *)documentSectionView {
	
	NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = self.document.managedObjectContext;
	
	int64_t objectIdentifier = documentSectionView.identifier;
	__block CGFloat height;

	[private performBlockAndWait:^{
		RptqDocumentSection *documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier: objectIdentifier
																				   fromObjectContext: private];
		height = documentSection.height;
	}];
	
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

/*
- (NSSet *)elementViews {
	
	RptqDocumentSectionEnumerator *sectionEnumerator;
	RptqDocument *activeDocumentModel = self.document.activeDocumentModel;
	sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument: activeDocumentModel];
	NSMutableSet *results = [[NSMutableSet alloc] init];
	
	MADDesignerSectionView *documentSectionView;
	RptqDocumentSection *documentSection;
	for (documentSection in sectionEnumerator) {
		documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier];

		NSInteger numberOfItemsInSection,
				  numberOfSections = documentSectionView.numberOfSections,
				  section,
				  item;
		
		for (section = 0; section < numberOfSections; section++) {
		
			numberOfItemsInSection = [documentSectionView numberOfItemsInSection:section];
			
			MADDesignerElementView *elementView;
			NSIndexPath *path;
			for (item = 0; item < numberOfItemsInSection; item++) {
				
				path = [NSIndexPath indexPathForItem:item inSection:section];
				elementView = [self elementViewAtIndexPath: path
										  inCollectionView: documentSectionView];
				if (elementView != nil) [results addObject:elementView];
			}
			
		}
	}
	return results;
}
*/
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
			if (((MADDesignerSectionView *)subview).tag == identifier) {
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
		
		//Try quick hash method...
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
	return self.view.scroller.container.sectionViews[@(sectionID)];
}

- (MADDesignerSectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)section {
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
	/*UITabBarController *tabBarController = self.tabBarController;
	if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
		tabBarController.navigationItem.prompt = self.promptManager.prompt.copy;
	} else {
		if (tabBarController.navigationItem.prompt != nil) {
			tabBarController.navigationItem.prompt = nil;
		}
	}*/
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

- (void)adjustSettingsLocation {
	self.settingsTransitioningDelegate.sourceRect = self.lastSelectedLabel.frame;
}

- (void)adjustToolboxLocation {
	self.toolboxTransitioningDelegate.sourceRect = self.rectForSelectedElements;
	self.viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
}

#pragma mark -
#pragma mark NSNotificationCenter Helpers

- (void)addObservers {
	MADocument *document = self.document;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidChange:)
												 name: NSManagedObjectContextObjectsDidChangeNotification
											   object: document.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(managedObjectContextDidSave:)
												 name: NSManagedObjectContextDidSaveNotification
											   object: document.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(didHideMenuNotification:)
												 name: UIMenuControllerDidHideMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(willHideMenuNotification:)
												 name: UIMenuControllerWillHideMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(didShowMenuNotification:)
												 name: UIMenuControllerDidShowMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(willShowMenuNotification:)
												 name: UIMenuControllerWillShowMenuNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(documentStateChanged)
												 name: UIDocumentStateChangedNotification
											   object: document];
}

- (void)removeObservers {
	
	MADocument *document = self.document;
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextObjectsDidChangeNotification
												  object: document.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSManagedObjectContextDidSaveNotification
												  object: document.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerDidHideMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerDidShowMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerWillHideMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIMenuControllerWillShowMenuNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIDocumentStateChangedNotification
												  object: document];
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionDone:(id)sender {
	__strong MADocument *document = self.document;
	if ([document.managedObjectContext hasChanges]) {
		NSError *saveError = NULL;
		[document.managedObjectContext save:&saveError];
		if (saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
	if (![self dismissAllPopovers]) {
		[self.delegate viewControllerDidFinish:nil];
	} else {
		[self deselectAllElementsAnimated:YES];
	}
}

- (IBAction)actionAdd:(id)sender {
	UINavigationController *navigation = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeElementPicker];
	[MADThemeManager applyAppearanceToNavigationController:navigation traitCollection:self.traitCollection];

	MADDesignerElementPickerViewController *pickerController = (MADDesignerElementPickerViewController *)navigation.topViewController;
	pickerController.objectSelectorDelegate = self;
	pickerController.document = self.document;
	
	navigation.modalPresentationStyle = UIModalPresentationPopover;
	navigation.preferredContentSize = sizePopoverDefault();
	
	UIPopoverPresentationController *popoverController = navigation.popoverPresentationController;
	popoverController.delegate = self;
	popoverController.barButtonItem = sender;
	popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
	
	[self presentViewController: navigation animated: YES completion:^{
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, pickerController);
	}];
	[self setDisplayInactive];
	
}

- (IBAction)actionCancel:(id)sender {
	self.hidesStatusBar = NO;
	[self dismissViewControllerAnimated:YES completion:^{
		[self setDisplayActive];
	}];
}

- (IBAction)actionDismiss {
	[self deselectAllElementsAnimated:YES];
	__strong MADocument *document = self.document;
	if ([document.managedObjectContext hasChanges]) {
		NSError *saveError = NULL;
		[document.managedObjectContext save:&saveError];
		if (saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
}

- (IBAction)actionHideToolbox {
	self.hidesStatusBar = NO;

	typeof(self) __weak weakself = self;
	[self dismissViewControllerAnimated:YES completion:^{
		MADDesignerViewController *sself = weakself;
		if (sself) {
			[sself actionDismiss];
			[sself setDisplayActive];
		}
	}];
}

- (IBAction)actionShowToolbox {
	
	_toolboxVisible = YES;
	_sectionSettingsVisible = NO;
	
	self.toolboxTransitioningDelegate.sourceView = self.view.scroller.container;
	self.toolboxTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
	self.toolboxTransitioningDelegate.popoverPresentationControllerDelegate = self;
	self.toolboxTransitioningDelegate.container = self.view.scroller.container;
	self.toolboxTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
	self.toolboxTransitioningDelegate.passthroughViews = [self passthroughViews];
	self.toolboxTransitioningDelegate.passthroughContainer = self.view.scroller;
	
	self.viewControllerToolbox.clearsBackground = [self padLike];
	self.viewControllerToolbox.document = self.document;
	[self adjustToolboxLocation];
	
	[self presentViewController: self.navigationControllerToolbox animated: YES completion: ^{
		[self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeElement];
	}];
	
}

- (IBAction)actionShowSectionSettingsFromLabel:(UILabel *)label {
	
	_toolboxVisible = NO;
	self.settingsTransitioningDelegate.sourceRect = label.frame;
	self.settingsTransitioningDelegate.sourceView = self.view.scroller.container;
	self.settingsTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
	self.settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;
	self.settingsTransitioningDelegate.container = self.view.scroller.container;
	self.settingsTransitioningDelegate.passthroughContainers = self.view.scroller.container.passthroughContainers;
	self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
	self.settingsTransitioningDelegate.passthroughContainer = self.view.scroller;
	
	if (_sectionSettingsVisible == NO) {
		_sectionSettingsVisible = YES;
		[self adjustPassthroughViews];
		[self presentViewController: self.navigationControllerSectionLayoutSettings animated: YES completion: ^{
			[self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
		}];
	} else {
		[self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
	}
	
}

#pragma mark -
#pragma mark Convenience

- (BOOL)padLike {
	return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
		   self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

- (NSSet <__kindof UIView *> *)passthroughViews {
	NSSet <MADDesignerSectionView *> *sectionViews = self.view.scroller.container.passthroughContainers;
	NSMutableSet <__kindof UIView *> *sectionLabels = [[NSMutableSet alloc] initWithCapacity:sectionViews.count];
	for (MADDesignerSectionView *view in sectionViews) {
		[sectionLabels addObject:view.sectionLabel];
	}
	[sectionLabels unionSet:sectionViews];
	[sectionLabels unionSet:self.visibleElementViews];
	return sectionLabels;
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)section {
	return self.view.scroller.container.sectionLabels[@(section.identifier)];
}

@end
