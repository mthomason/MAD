//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController.h"
#import "MADViewControllerBarcodeDelegate.h"

#import <math.h>

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

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSManagedObjectContext.h>

#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADResizeAspect.h>

#import <MADCocoaExtensions/MADAlertController.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <MAD/MADReportSectionsEnumerator.h>
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
#import <MAD/madmath.h>

#import "MADTabBarController.h"

#import "MADRulerView.h"

#import "MADDesignerElementView.h"
#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"

#import "MADDesignerElementPickerViewController.h"

#import "MADCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"

#import "MADDesignerSectionLayoutLiquid.h"
#import "MADDesignerSectionLayoutController.h"
#import "MADDesignerSectionBackground.h"

#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"

#import "MADPopoverBackgroundView.h"

#import "MADToolboxPresentationController.h"

#import "MADDesignerStatusLabel.h"
#import "MADBackgroundScrollView.h"
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
#import "UIView+Extras.h"

#import "MADManagedObjectViewProtocol.h"
#import "MADCellElementDelegate.h"

#import "MTViewControllerBarcode.h"

#import "MADElementPickerProtocol.h"

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
static const CGFloat MTReportDesignerSectionLabelHeight         = 20.0000f;
static const CGFloat MTReportDesignerBorderPaddingSides         =  8.0000f;
static const CGFloat MTReportDesignerBorderPaddingDetail        =  3.0000f;
static const CGFloat MTReportDesignerBorderPaddingVertical      =  3.0000f;
static const CGFloat MTReportDesignerBufferPaddingVertical      =  2.0000f;
static const CGFloat MTReportDesignerSectionLabelPaddingRight   =  8.0000f;

static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView);
static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView) {
    return scrollView.contentSize.width * 0.5000f +
            MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5000f, 0.0000f);
}

static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView);
static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView) {
    return scrollView.contentSize.height * 0.5000f +
            MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5000f, 0.0000f);
}

static inline CGFloat DetailDisplayFrameOriginX(CGFloat width);
static inline CGFloat DetailDisplayFrameOriginX(CGFloat width) {
    return width - MADSizeWidthViewDetailDisplay - MTReportDesignerBorderPaddingDetail;
}

static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop);
static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop) {
    return CGPointZero.y + marginTop + MTReportDesignerBorderPaddingDetail;
}

static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect);
static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect) {
    return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.width,
                            CGSizeZero.height,
                            presentedRect.size.width - MTReportDesignerBorderPaddingSides);
}

static const inline CGSize sizePopoverDefault();
static const inline CGSize sizePopoverDefault() {
    return CGSizeMake(MADDefaultsPopooverWidth, 320.0000f);
}

static const inline CGSize sizePopoverFonts();
static const inline CGSize sizePopoverFonts() {
    return CGSizeMake(MADDefaultsPopooverWidth, MADDefaultsPopooverHeight);
}

@interface MADDesignerViewController()
    <MADViewControllerBarcodeDelegate,
        MTViewControllerAggregateDelegate,
        MADCellElementDelegate,
        MADDesignerSectionLayoutLiquidDelegate,
        MADElementPickerProtocol,
        MADViewControllerStandardProtocol,
        MADDesignerSectionLayoutDelegate,
        MADQueryChooseFieldProtocol,
        UIPopoverPresentationControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        UINavigationControllerDelegate,
        UIScrollViewDelegate,
        UIImagePickerControllerDelegate>

    @property (nonatomic, strong) IBOutlet MADBackgroundScrollView *scroller;

    @property (nonatomic, strong) NSMutableSet <MADDesignerElementView *> *visibleElementViews;
    @property (nonatomic, strong) NSSet <MADDesignerSectionView *> *passthroughContainers;
    @property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedElementIDs;

    @property (nonatomic, strong) NSArray <MADDesignerSectionView *> *sectionViewsArray;

    @property (nonatomic, strong) NSDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    @property (nonatomic, strong) NSDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionControlViewsDictionary;
    @property (nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerElementView *> *elementViewsDictionary;

    @property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerScrollViewConstraints;
    @property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerContentViewConstraints;
    @property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer;
    @property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder;
    @property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer;

    @property (nonatomic, strong) NSMutableDictionary <NSNumber *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;

    @property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView;
    @property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedElements;
    @property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedSections;

    @property (nonatomic, weak) MADDesignerElementView *lastElementViewToShowMenu;

    @property (nonatomic, strong) MADToolboxTransitioningDelegate *toolboxTransitioningDelegate;
    @property (nonatomic, strong) MADToolboxTransitioningDelegate *settingsTransitioningDelegate;

    @property (nonatomic, strong) NSNumberFormatter *numberFormatterPercentage;

    @property (nonatomic, strong) MADRulerView *ruler;
    @property (nonatomic, strong) MADDesignerStatusLabel *statusLabelZoomScale;
    @property (nonatomic, strong) MADPromptManager *promptManager;

    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerWidth;
    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;

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
    @property (nonatomic, strong) NSSet <UIGestureRecognizer *> *tapSectionLabels;
    @property (nonatomic, weak) UILabel *lastSelectedLabel;

    @property (nonatomic, weak) UIBarButtonItem *undoButton;

@end

@implementation MADDesignerViewController {
    int64_t _identifierJustDisplayed;
    CGFloat _zoomScaleRestore;
    BOOL _editAggregate;
    BOOL _toolboxVisible;
    BOOL _sectionSettingsVisible;
    BOOL _insetsSetup;
    BOOL _shownAndHidden;
    BOOL _lastMenuItemSelectRequiresElementView;
    CGRect _boundsOnDisappear;
}

@synthesize document = _document;
@synthesize title = _title;

#pragma mark -
#pragma mark Static Helpers

+ (NSString *)Title {
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
}

#pragma mark -
#pragma mark MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:@"UIBarButtonItemMadDesigner8"];
}

+ (instancetype)newDesignerViewController:(MADocument *)document {
    NSString *MADDesignerStoryboardID = @"MADIdentifierStoryboardDesignerViewController";
    id bundle = [NSBundle mainBundle];
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:@"MADDesigner" bundle:bundle];
    id controller = [storyboard instantiateViewControllerWithIdentifier:MADDesignerStoryboardID];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    
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
                 fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return action == @selector(unwindToDesigner:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToDesigner:) ?
            self : [super viewControllerForUnwindSegueAction: action
                                          fromViewController: fromViewController
                                                  withSender: sender];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView;
        borderAppliedToView = [[NSMutableDictionary alloc] init];
        self.borderAppliedToView = borderAppliedToView;
        _identifierJustDisplayed = -1;

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

- (void)loadView {
    [super loadView];

    void (^initalizeScroller)(MADBackgroundScrollView *) = ^(MADBackgroundScrollView *scroller) {
        scroller.scrollsToTop              = YES;
        scroller.scrollEnabled             = YES;
        scroller.userInteractionEnabled    = YES;
        scroller.indicatorStyle            = UIScrollViewIndicatorStyleDefault;
        scroller.maximumZoomScale          = 4.0000f;
        scroller.minimumZoomScale          = 0.3000f;
        scroller.bouncesZoom               = NO;
        scroller.opaque = NO;
        scroller.backgroundColor = [UIColor clearColor];
        scroller.container.opaque = NO;
        scroller.container.backgroundColor = [UIColor clearColor];
    };

    _boundsOnDisappear = CGRectZero;
    _zoomScaleRestore = -1.0000f;
    _shownAndHidden = NO;
    _editAggregate = NO;
    
    _insetsSetup = NO;
    _toolboxVisible = NO;
    _sectionSettingsVisible = NO;
    initalizeScroller(self.scroller);

}

- (MADDesignerStatusLabel *)statusLabelZoomScale {
    if (_statusLabelZoomScale == nil) {
        MADDesignerStatusLabel *detailDisplay;
        detailDisplay = [[MADDesignerStatusLabel alloc] initWithFrame: CGRectZero];
        detailDisplay.frame = [self detailDisplayFrame];
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

- (MADRulerView *)ruler {
    if (_ruler == nil) {
        MADRulerView *ruler;
        ruler = [[MADRulerView alloc] initWithFrame:CGRectZero];
        _ruler = ruler;
    }
    return _ruler;
}

- (MADToolboxTransitioningDelegate *)toolboxTransitioningDelegate {
    if (_toolboxTransitioningDelegate == nil) {
        MADToolboxTransitioningDelegate *delegate;
        delegate = [[MADToolboxTransitioningDelegate alloc] init];
        _toolboxTransitioningDelegate = delegate;
    }
    return _toolboxTransitioningDelegate;
}

- (MADToolboxTransitioningDelegate *)settingsTransitioningDelegate {
    if (_settingsTransitioningDelegate == nil) {
        MADToolboxTransitioningDelegate *delegate;
        delegate = [[MADToolboxTransitioningDelegate alloc] init];
        _settingsTransitioningDelegate = delegate;
    }
    return _settingsTransitioningDelegate;
}

- (UINavigationController *)navigationControllerToolbox {
    if (_navigationControllerToolbox == nil) {
        UINavigationController *navigation;
        navigation = [MADNavigationController newNavigationController: MADNavigationControllerTypeToolbox];
        navigation.transitioningDelegate = self.toolboxTransitioningDelegate;
        navigation.modalPresentationStyle = UIModalPresentationCustom;
        navigation.preferredContentSize = sizePopoverDefault();
        _navigationControllerToolbox = navigation;
    }
    return _navigationControllerToolbox;
}

- (UINavigationController *)navigationControllerSectionLayoutSettings {
    if (_navigationControllerSectionLayoutSettings == nil) {
        UINavigationController *navigationController;
        navigationController = [[UINavigationController alloc] initWithRootViewController: self.viewControllerSectionLayoutSettings];
        navigationController.transitioningDelegate = self.settingsTransitioningDelegate;
        navigationController.modalPresentationStyle = UIModalPresentationCustom;
        navigationController.preferredContentSize = CGSizeMake(MADDefaultsPopooverWidth, 100.0000f);
        _navigationControllerSectionLayoutSettings = navigationController;
    }
    return _navigationControllerSectionLayoutSettings;
}

- (MADToolboxViewController *)viewControllerToolbox {
    if (_viewControllerToolbox == nil) {
        MADToolboxViewController *viewControllerToolbox;
        viewControllerToolbox = (MADToolboxViewController *)self.navigationControllerToolbox.topViewController;
        viewControllerToolbox.clearsBackground = [self padLike];
        viewControllerToolbox.document = _document;
        viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
        
        _toolboxTransitioningDelegate.popoverPresentationControllerDelegate = self;
        _toolboxTransitioningDelegate.passthroughContainer = self.scroller;
        
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
    
    NSArray <NSLayoutConstraint *> *constraints;
    constraints = self.scroller.container.constraints;
    if (constraints.count > 0) {
        [self.scroller.container removeConstraints:constraints];
    }
    
    constraints = self.scroller.constraints;
    if (constraints.count > 0) {
        [self.scroller removeConstraints:constraints];
    }
    constraints = nil;
    
    UITapGestureRecognizer *tapGestureDoubleTap = self.scroller.doubleTapToZoom;
    tapGestureDoubleTap.delegate =  self;
    
    UIGestureRecognizer *tap;
    tap = [MADTapGestureRecognizer newTapGestureRecognizerStrayTouchWithTarget: self
                                                                        action: @selector(handleStrayTouch:)
                                                                      delegate: self];
    [tap requireGestureRecognizerToFail:tapGestureDoubleTap];
    [self.scroller addGestureRecognizer:tap];
    self.strayTouchGesture = tap;
    
    self.scroller.delegate = self;
    
    self.scroller.container.backgroundColor =   [UIColor greenColor];
    self.scroller.backgroundColor =             [UIColor blueColor];

    NSLayoutConstraint *constraintContentLeft, *constraintContentRight, *viewScrollerTop,
                       *constraintContentTop, *constraintScrollerBottom, *constraintWidth;
    
    constraintContentLeft = [MADLayoutConstraint newLayoutConstraintView: self.view
                                                           containerLeft: self.scroller.container];
    
    constraintContentRight = [MADLayoutConstraint newLayoutConstraintView: self.view
                                                           containerRight: self.scroller.container];
    
    constraintContentTop = [MADLayoutConstraint newLayoutConstraintView: self.scroller
                                                           containerTop: self.scroller.container];
    constraintScrollerBottom = [MADLayoutConstraint newLayoutConstraintScroller: self.scroller
                                                                         bottom: self.bottomLayoutGuide];
    constraintWidth = [MADLayoutConstraint newLayoutConstraintContent: self.scroller.container
                                                                width: self.view.frame.size.width / self.scroller.zoomScale];
    
    constraintContentLeft.priority = 999;
    constraintContentRight.priority = 999;

    viewScrollerTop = [MADLayoutConstraint newLayoutConstraintViewScrollerTop: self.scroller
                                                                         view: self.topLayoutGuide];

    constraints = [[NSArray alloc] initWithObjects: constraintContentLeft,
                                                    constraintContentRight,
                                                    constraintContentTop,
                                                    constraintScrollerBottom,
                                                    constraintWidth,
                                                    viewScrollerTop, nil];
    [self.view addConstraints:constraints];

    self.layoutConstraintContainerWidth = constraintWidth;

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%@", self.document.undoManager.undoMenuItemTitle);
    NSLog(@"Keypath: %@", keyPath);
    NSLog(@"Object: %@", object);
    NSLog(@"Change: %@", change);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MADocument *maDocument = self.document;
    NSLog(@"%@", maDocument.undoManager.undoMenuItemTitle);
    //NSString *keyPath = [MADDesignerViewController keyPathDocumentUndoTitle];
    //[self addObserver:self
    //       forKeyPath:keyPath
    //          options:NSKeyValueObservingOptionNew context:nil];
    
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:NO];
        [self displayPrompt];
        [UIView setAnimationsEnabled:YES];
    }

    [self addObservers];
    
    MADBackgroundScrollView *scroller = _scroller;

    _lastMenuItemSelectRequiresElementView = NO;
    _zoomScaleRestore = scroller.zoomScale;
    [scroller setZoomScale: 1.0000f animated: NO];

    RptqDocument *document = [maDocument activeDocumentModel];

    MADReportSectionsEnumerator *reportSectionsEnumerator;
    reportSectionsEnumerator = [[MADReportSectionsEnumerator alloc] initWithDocument:document];
    
    NSInteger sectionCounter = 0;
    NSUInteger numberOfSections = reportSectionsEnumerator.count;
    
    [scroller.container addSubview:self.ruler];
    
    [self.view addSubview:self.statusLabelZoomScale];
    [self updateDisplayDetailZoomValue];
    
    NSArray <NSLayoutConstraint *> *rulerConstraints, *rulerSideConstraints;
    rulerConstraints = [MADLayoutConstraint constraintForRuler: self.ruler
                                                     designer: scroller.container
                                                    marginTop: MTReportDesignerBorderPaddingVertical
                                                        heigh: MTReportDesignerRulerHeight].copy;
    
    rulerSideConstraints = [MADLayoutConstraint constraintForRuler: self.ruler
                                                         designer: scroller.container
                                                       sideMargin: MTReportDesignerBorderPaddingSides].copy;
    
    NSMutableArray <NSNumber *> *reportSectionKeyTracker;
    
    NSMutableArray <NSLayoutConstraint *> *scrollerLayoutConstraints,
                                          *viewDidAppearDesignerContentViewConstraints,
                                          *constraintsSectionsSidesBorder,
                                          *constraintSectionLabelHeightContainer,
                                          *constraintsSectionsVerticalBuffer;
    
    NSMutableArray <MADDesignerSectionView *> *sectionViewsArray;
    NSMutableDictionary <NSNumber *, NSLayoutConstraint *> *constraintsReportSectionHeight;

    reportSectionKeyTracker = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    scrollerLayoutConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 6];
    viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 5];
    constraintsSectionsSidesBorder = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 2];
    constraintSectionLabelHeightContainer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    constraintsSectionsVerticalBuffer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    sectionViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    constraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    
    NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionControlViewsDictionary;

    sectionViewsDictionary          = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    sectionControlViewsDictionary   = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];

    NSMutableSet <MADDesignerSectionView *> *passthroughContainers;
    passthroughContainers = [[NSMutableSet alloc] initWithCapacity:numberOfSections];

    [constraintsSectionsSidesBorder addObjectsFromArray:rulerSideConstraints];
    
    [scrollerLayoutConstraints addObjectsFromArray:rulerConstraints];
    [scrollerLayoutConstraints addObjectsFromArray:rulerSideConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight +
                                                 MTReportDesignerBorderPaddingVertical;
    
    CGFloat borderWidthThin = [UIView borderWidthThin];
    NSLayoutConstraint *constraintViewTop,
                       *constraintView,
                       *constraintLabelRight,
                       *constraintLabelBottom,
                       *constraintLabel,
                       *constraintViewLeft,
                       *constraintViewRight;
    NSArray *collectionViewConstraints, *sectionViewLabelConstraints;
    UIGestureRecognizer *strayTouchGesture = self.strayTouchGesture;

    NSMutableSet *tapSectionLabels = [[NSMutableSet alloc] init];
    NSNumber *reportSectionKey;
    MADDesignerSectionView *sectionView;
    MADDesignerSectionLabel *sectionViewLabel;
    UIGestureRecognizer *tapGestureRecognizer;
    NSString *localizedDisplayName;
    for (MADReportSection *reportSection in reportSectionsEnumerator) {
        
        reportSectionKey = @(reportSection.identifier);
        
        sectionHeights += (MTReportDesignerBufferPaddingVertical + reportSection.height);
        
        sectionView = [MADDesignerSectionView newDesignerSectionView: reportSection
                                                            delegate: self];
        sectionView.delegate = self;
        sectionView.dataSource = self;
        sectionView.layer.borderWidth = borderWidthThin;
        sectionView.showsVerticalScrollIndicator = YES;
        
        ((MADDesignerSectionLayoutLiquid *)sectionView.collectionViewLayout).tag = sectionCounter;
        localizedDisplayName = [reportSection localizedDisplayName];
        sectionViewLabel = [[MADDesignerSectionLabel alloc] initWithText:localizedDisplayName];
        
        tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerSectionToggleWithTarget:self
                                                                                                action:@selector(handleToggleSectionControlPanel:)
                                                                                              delegate:self];
        [tapSectionLabels addObject:tapGestureRecognizer];
        [strayTouchGesture requireGestureRecognizerToFail:tapGestureRecognizer];
        [sectionViewLabel addGestureRecognizer: tapGestureRecognizer];
        
        sectionViewLabel.tag = sectionCounter;
        
        NSNumber *key;
        UIView *constraintItem;
        
        key = reportSectionKeyTracker.lastObject;
        constraintItem = sectionCounter == 0 ? self.ruler :
                                               sectionViewsDictionary[key];
        
        constraintViewTop = [MADLayoutConstraint newLayoutConstraintViewTop: constraintItem
                                                                viewBottom: sectionView
                                                                   padding: MTReportDesignerBufferPaddingVertical];
        
        constraintView = [MADLayoutConstraint newLayoutConstraintView: sectionView
                                                              height: reportSection.height];
        
        constraintLabelRight = [MADLayoutConstraint newLayoutConstraintLabelRight: sectionViewLabel
                                                                       container: sectionView
                                                                         padding: MTReportDesignerSectionLabelPaddingRight];
        
        constraintLabelBottom = [MADLayoutConstraint newLayoutConstraintLabelBottom: sectionViewLabel
                                                                         container: sectionView
                                                                           padding: MTReportDesignerBufferPaddingVertical];
        constraintLabel = [MADLayoutConstraint newLayoutConstraintLabel: sectionViewLabel
                                                              toHeight: MTReportDesignerSectionLabelHeight];
        
        constraintViewLeft = [MADLayoutConstraint newLayoutConstraintViewLeft:sectionView
                                                                     content:scroller.container
                                                                     padding:MTReportDesignerBorderPaddingSides];
        
        constraintViewRight = [MADLayoutConstraint newLayoutConstraintViewRight:sectionView
                                                                       content:scroller.container
                                                                       padding:MTReportDesignerBorderPaddingSides];
        
        collectionViewConstraints = [[NSArray alloc] initWithObjects: constraintViewLeft,
                                     constraintViewRight, nil];
        
        sectionViewLabelConstraints = [[NSArray alloc] initWithObjects: constraintViewTop,
                                       constraintView,
                                       constraintLabelRight,
                                       constraintLabelBottom,
                                       constraintLabel, nil];
        
        [viewDidAppearDesignerContentViewConstraints addObjectsFromArray:sectionViewLabelConstraints];
        
        
        [constraintsSectionsVerticalBuffer addObject: constraintViewTop];
        [constraintSectionLabelHeightContainer addObject: constraintLabel];
        
        [constraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];
        
        [scrollerLayoutConstraints addObjectsFromArray:collectionViewConstraints];
        
        constraintsReportSectionHeight[@(sectionView.identifier)] = constraintView;
        
        sectionViewsDictionary[reportSectionKey] = sectionView;
        sectionControlViewsDictionary[reportSectionKey] = sectionViewLabel;
        
        [reportSectionKeyTracker addObject:reportSectionKey];
        [sectionViewsArray addObject:sectionView];
        
        sectionCounter++;
        
        [scroller.container addSubview:sectionView];
        [scroller.container addSubview:sectionViewLabel];
        
        [passthroughContainers addObject:sectionView];
        
        sectionView.sectionLabel = sectionViewLabel;
    }
    
    [reportSectionKeyTracker removeAllObjects];
    self.tapSectionLabels = tapSectionLabels;
    self.layoutConstraintsSectionsVerticalBuffer = constraintsSectionsVerticalBuffer;

    self.layoutConstraintsReportSectionHeight = constraintsReportSectionHeight;
    self.sectionViewsDictionary = sectionViewsDictionary;
    self.sectionControlViewsDictionary = sectionControlViewsDictionary;

    self.layoutConstraintsSectionsSidesBorder = constraintsSectionsSidesBorder;
    self.layoutConstraintSectionLabelHeightContainer = constraintSectionLabelHeightContainer;
    self.passthroughContainers = passthroughContainers;
    self.sectionViewsArray = sectionViewsArray;
    
    sectionHeights += MTReportDesignerBorderPaddingVertical;
    
    NSLayoutConstraint *constraintContentViewHeight;
    constraintContentViewHeight = [MADLayoutConstraint newLayoutConstraintView: scroller.container
                                                                       height: sectionHeights];

    [scrollerLayoutConstraints addObject:constraintContentViewHeight];

    self.layoutConstraintDesignerContentViewHeight = constraintContentViewHeight;
    
    
    NSLayoutConstraint *constraintToScollerBottom;
    constraintToScollerBottom = [MADLayoutConstraint newLayoutConstraintView: scroller.container
                                                                   containerBottom: scroller];
    
    [scrollerLayoutConstraints addObject:constraintToScollerBottom];
    
    [self.scroller addConstraints: scrollerLayoutConstraints];
    [self.scroller.container addConstraints: viewDidAppearDesignerContentViewConstraints];
    
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    self.viewDidAppearDesignerScrollViewConstraints = scrollerLayoutConstraints;
    [self.view addSubview:self.scroller];
    [self.scroller setNeedsLayout];
    
    UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc] initWithTitle: @"Undo"
                                                                    style: UIBarButtonItemStylePlain
                                                                   target: self
                                                                   action: @selector(undo)];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self setToolbarItems:@[toolbarItem] animated:NO];
    self.undoButton = toolbarItem;

}

- (void)undo {
    [self.document.undoManager undo];
    NSLog(@"Undo");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_insetsSetup == NO) _insetsSetup = YES;
    
    [self setScrollersEnabled:YES];
    
    if (_shownAndHidden && _zoomScaleRestore > 1.0001) {
        [self.scroller setZoomScale:_zoomScaleRestore animated:NO];
        [self handledScrollViewDidEndZooming: nil withView: nil atScale: self.scroller.zoomScale];
        [self.scroller scrollRectToVisible:_boundsOnDisappear animated:NO];
    }
    [self.scroller flashScrollIndicators];
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
}

+ (NSString *)keyPathDocument {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(document));
    return key;
}

+ (NSString *)keyPathDocumentRedoTitle {
    static NSString *key = nil;
    if (key == nil) {
        NSString *keyPathDocument = [self keyPathDocument];
        NSString *keyPathUndoManager = NSStringFromSelector(@selector(undoManager));
        NSString *keyPathRedoMenuItemTitle = NSStringFromSelector(@selector(redoMenuItemTitle));
        key = [keyPathDocument stringByAppendingString:@"."];
        key = [key stringByAppendingString:keyPathUndoManager];
        key = [key stringByAppendingString:@"."];
        key = [key stringByAppendingString:keyPathRedoMenuItemTitle];
    }
    return key;
}

+ (NSString *)keyPathDocumentUndoTitle {
    static NSString *key = nil;
    if (key == nil) {
        NSString *keyPathDocument = [self keyPathDocument];
        NSString *keyPathUndoManager = NSStringFromSelector(@selector(undoManager));
        NSString *keyPathUndoMenuItemTitle = NSStringFromSelector(@selector(undoMenuItemTitle));
        key = [keyPathDocument stringByAppendingString:@"."];
        key = [key stringByAppendingString:keyPathUndoManager];
        key = [key stringByAppendingString:@"."];
        key = [key stringByAppendingString:keyPathUndoMenuItemTitle];
    }
    return key;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _boundsOnDisappear = self.scroller.bounds;
    [self.statusLabelZoomScale removeFromSuperview];
    NSString *keyPath = [MADDesignerViewController keyPathDocumentUndoTitle];
    [self removeObserver:self forKeyPath:keyPath];
    [self setToolbarItems:@[] animated:animated];
    self.undoButton = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSArray *subviews = self.scroller.container.subviews;
    for (id view in subviews) {
        if ([view isKindOfClass:[MADDesignerSectionView class]]) {
            [((MADDesignerSectionView *)view).sectionLabel removeFromSuperview];
        }
        [view removeFromSuperview];
    }
    
    [self.scroller removeConstraints:self.viewDidAppearDesignerScrollViewConstraints];
    [self.scroller.container removeConstraints:self.viewDidAppearDesignerContentViewConstraints];
    
    [self.elementViewsDictionary removeAllObjects];
    [self.visibleElementViews removeAllObjects];
    [self.viewDidAppearDesignerContentViewConstraints removeAllObjects];
    [self.viewDidAppearDesignerScrollViewConstraints removeAllObjects];
    [self.layoutConstraintsSectionsSidesBorder removeAllObjects];
    [self.layoutConstraintsSectionsVerticalBuffer removeAllObjects];
    [self.layoutConstraintsReportSectionHeight removeAllObjects];
    
    _shownAndHidden = YES;
    [self.document saveContext];
    [self removeObservers];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIEdgeInsets insets;
    
    // FIXME: This is not choosing the correct scroll inset...
    
    if (self.toolboxTransitioningDelegate.presentationController.presentedView.superview != nil &&
        self.presentedViewController.childViewControllers.count > 0 &&
        self.toolboxTransitioningDelegate.presentationController != nil &&
        !(self.presentingViewController.traitCollection.verticalSizeClass ==
                                                            UIUserInterfaceSizeClassCompact)) {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                  CGSizeZero.width,
                                  self.toolboxTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height,
                                  CGSizeZero.width);
        
    } else if (self.settingsTransitioningDelegate.presentationController.presentedView.superview != nil &&
               self.presentedViewController.childViewControllers.count > 0 &&
               self.settingsTransitioningDelegate.presentationController != nil &&
               !(self.presentingViewController.traitCollection.verticalSizeClass ==
                                                                UIUserInterfaceSizeClassCompact)) {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                  CGSizeZero.width,
                                  self.settingsTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height,
                                  CGSizeZero.width);
        
    } else {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
        
    }
    
    self.scroller.contentInset = insets;
    self.scroller.scrollIndicatorInsets = insets;
    
    self.statusLabelZoomScale.frame = [self detailDisplayFrame];
    [self.viewControllerSectionLayoutSettings.view setNeedsLayout];
    [self.ruler setNeedsDisplay];
    
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
        
        
        for (UICollectionView *sectionView in self.sectionViewsDictionary.objectEnumerator) {
            sectionView.contentInset = UIEdgeInsetsMake(CGSizeZero.height,
                                                        CGSizeZero.width,
                                                        CGSizeZero.height,
                                                        presentedRect.size.width - MTReportDesignerBorderPaddingSides);
            sectionView.scrollIndicatorInsets = sectionView.contentInset;
        }
        
    } else {
        for (UICollectionView *sectionView in self.sectionViewsDictionary.objectEnumerator) {
            sectionView.contentInset = UIEdgeInsetsZero;
            sectionView.scrollIndicatorInsets = UIEdgeInsetsZero;
        }
    }
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
   
    CGFloat zoomscale = self.scroller.zoomScale;
    CGFloat ratio = self.view.frame.size.width / zoomscale;
    //if (!isinf(ratio) && !isnan(ratio)) {
        self.layoutConstraintContainerWidth.constant = ratio;

        CGFloat borderPaddingSides = MTReportDesignerBorderPaddingSides / zoomscale;
        
        void (^calculateBorder)(NSLayoutConstraint *, NSUInteger, BOOL *);
        void (^calculateVerticalBuffer)(NSLayoutConstraint *, NSUInteger, BOOL *);
        void (^calculateLabelHeight)(NSLayoutConstraint *, NSUInteger, BOOL *);
        
        calculateBorder = ^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
            constraint.constant = constraint.constant > 0 ? borderPaddingSides : -borderPaddingSides;
        };
        
        calculateVerticalBuffer = ^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
            constraint.constant = constraint.constant > 0 ?
            MTReportDesignerBufferPaddingVertical :
            -MTReportDesignerBufferPaddingVertical;
        };
        
        calculateLabelHeight = ^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
            constraint.constant = MTReportDesignerSectionLabelHeight / zoomscale;
        };
        
        [self.layoutConstraintsSectionsSidesBorder enumerateObjectsUsingBlock:calculateBorder];
        [self.layoutConstraintsSectionsVerticalBuffer enumerateObjectsUsingBlock:calculateVerticalBuffer];
        [self.layoutConstraintSectionLabelHeightContainer enumerateObjectsUsingBlock:calculateLabelHeight];
        
        self.layoutConstraintDesignerContentViewHeight.constant = [self designerContentViewSize].height;
    //}
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
        MADocument *document = self.document;
        [(segue.destinationViewController) setDocument: document];
    }
    
}

- (BOOL)prefersStatusBarHidden {
    return self.hidesStatusBar ||
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) {
            [self.view setNeedsDisplay];
        };
    } else {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) { };
    }
    [coordinator animateAlongsideTransition: transition
                                 completion: ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self adjustContextOffsetForOpenPopover];
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

- (NSMutableSet <NSNumber *> *)selectedElements {
    if (!_selectedElements) {
        NSMutableSet *selectedElements = [[NSMutableSet alloc] init];
        _selectedElements = selectedElements;
    }
    return _selectedElements;
}

- (NSMutableSet <NSNumber *> *)selectedSections {
    if (!_selectedSections) {
        NSMutableSet *selectedSections = [[NSMutableSet alloc] init];
        _selectedSections = selectedSections;
    }
    return _selectedSections;
}

- (NSMutableSet <NSNumber *> *)selectedElementIDs {
    if (!_selectedElementIDs) {
        NSMutableSet <NSNumber *> *selectedElementIDs;
        selectedElementIDs = [[NSMutableSet alloc] init];
        _selectedElementIDs = selectedElementIDs;
    }
    return _selectedElementIDs;
}

- (NSMutableSet <MADDesignerElementView *> *)visibleElementViews {
    if (!_visibleElementViews) {
        NSMutableSet <MADDesignerElementView *> *visibleElementViews;
        visibleElementViews = [[NSMutableSet alloc] init];
        _visibleElementViews = visibleElementViews;
    }
    return _visibleElementViews;
}

- (NSMutableDictionary <NSNumber *, MADDesignerElementView *> *)elementViewsDictionary {
    if (!_elementViewsDictionary) {
        NSMutableDictionary <NSNumber *, MADDesignerElementView *> *elementViewsDictionary;
        elementViewsDictionary = [[NSMutableDictionary alloc] init];
        _elementViewsDictionary = elementViewsDictionary;
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
    if ([scrollView isEqual:self.scroller]) {
        [self.statusLabelZoomScale show];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    if ([scrollView isEqual:self.scroller]) {
        
        [self updateDisplayDetailZoomValue];
        self.statusLabelZoomScale.frame = [self detailDisplayFrame];
        
        [self.ruler setNeedsDisplay];
        
        @autoreleasepool {
            UIFontDescriptor *captionFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
            
            UIFont *font = [UIFont fontWithDescriptor: captionFontDescriptor
                                                 size: captionFontDescriptor.pointSize / scrollView.zoomScale];
            NSDictionary *attributes;
            attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
            NSArray <MADDesignerSectionLabel *> *sectionControlViewsArray = self.sectionControlViewsDictionary.allValues;
            MADDesignerSectionLabel *controlView;
            CGRect controlViewTextBounds;
            for (controlView in sectionControlViewsArray) {
                controlViewTextBounds = [controlView.text boundingRectWithSize: controlView.bounds.size
                                                                       options: (NSStringDrawingOptions)-1
                                                                    attributes: attributes
                                                                       context: nil];
                
                controlView.preferredMaxLayoutWidth = controlViewTextBounds.size.width / scrollView.zoomScale;
                controlView.font = font;
                controlView.scale = self.scroller.zoomScale;
                controlView.contentScaleFactor =  scrollView.zoomScale * self.scroller.traitCollection.displayScale;
                [controlView setNeedsDisplay];
            }
        }
        
        [self adjustScroller];
        [self.scroller.container invalidateIntrinsicContentSize];
        self.scroller.container.center = CGPointMake(ScrollViewCenterX(scrollView), ScrollViewCenterY(scrollView));
        
        [self.view setNeedsUpdateConstraints];
        
    }
    
}

- (void)scrollViewDidEndZooming: (UIScrollView *)scrollView
                       withView: (UIView *)view
                        atScale: (CGFloat)scale {
    [self handledScrollViewDidEndZooming:scrollView withView:view atScale:scale];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.scroller]) {
        [self adjustScroller];
    }
    self.statusLabelZoomScale.frame = [self detailDisplayFrame];
    NSString *formatter = NSLocalizedString(@"Scrolled to %@.", @"Scrolled to %@.");
    NSString *message = [NSString stringWithFormat: formatter, NSStringFromCGPoint(scrollView.contentOffset)];
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, message);
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.scroller.container;
}

#pragma mark -
#pragma mark ScrollView helpers

- (void)adjustScroller {
    
    [self adjustContextOffsetForOpenPopover];
    
    if (self.scroller.contentOffset.x != 0) {
        CGPoint offset = self.scroller.contentOffset;
        offset.x = CGPointZero.x;
        self.scroller.contentOffset = offset;
        self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width, self.scroller.contentSize.height);
    }
}

- (void)handledScrollViewDidEndZooming: (UIScrollView *)scrollView
                              withView: (UIView *)view
                               atScale: (CGFloat)scale {
    if ([scrollView isEqual:self.scroller]) {
        
        CGFloat scaleWithScreen = scale * scrollView.traitCollection.displayScale;
        
        self.ruler.contentScaleFactor = scaleWithScreen;
        
        NSSet *elementViews = self.visibleElementViews;
        for (MADDesignerElementView *elementView in elementViews) {
            elementView.contentScaleFactor = scaleWithScreen;
        }
        UIFont *captionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        CGFloat pointsize = captionFont.pointSize;
        
        NSArray <__kindof MADDesignerSectionLabel *> *sectionControlViewsArray;
        sectionControlViewsArray = self.sectionControlViewsDictionary.allValues;
        [sectionControlViewsArray enumerateObjectsWithOptions: NSEnumerationConcurrent
                                                   usingBlock: ^(__kindof MADDesignerSectionLabel * _Nonnull controlView,
                                                                 NSUInteger idx, BOOL * _Nonnull stop) {
                                                       
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                controlView.font = [captionFont fontWithSize:pointsize / scale];
                controlView.contentScaleFactor = scaleWithScreen;
                [controlView setNeedsDisplay];
            }];
            
        }];
        
        UICollectionView *section;
        NSEnumerator *objectEnumerator = self.sectionViewsDictionary.objectEnumerator;
        for (section in objectEnumerator) {
            section.contentScaleFactor = scale;
        }
        
        [self.view setNeedsLayout];
        
        [self.statusLabelZoomScale hide];
    }
    
    [self adjustContextOffsetForOpenPopover];
}

- (void)updateDisplayDetailZoomValue {
    NSNumber *number = [[NSNumber alloc] initWithDouble: self.scroller.zoomScale];
    NSString *zoomScaleText = [self.numberFormatterPercentage stringFromNumber:number];
    [self.statusLabelZoomScale setText: zoomScaleText];
}

#pragma mark -
#pragma mark UIDocumentStateChangedNotification

- (void)documentStateChanged {
    
    switch (self.document.documentState) {
        case UIDocumentStateEditingDisabled:
            self.view.userInteractionEnabled = NO;
            break;
        case UIDocumentStateSavingError:
        case UIDocumentStateNormal:
        case UIDocumentStateClosed:
        case UIDocumentStateInConflict:
        default:
            self.view.userInteractionEnabled = YES;
            break;
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
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    [private performBlock:^{
    
        RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query =  database.hasQueries.anyObject;
        
        RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
                                                              withNumberOfGroups: query.hasQueryGroups.count];
        
        [section setProducesFormFeed: newPageAfter];
        
        NSError * __autoreleasing *error = NULL;
        if (![private save:error]) NSLog(@"Error saving managed object context: %@", *error);
        
    }];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    NSDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    sectionViewsDictionary = self.sectionViewsDictionary;
    [private performBlock:^{
    
        RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query =  database.hasQueries.anyObject;
        
        RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber
                                                              withNumberOfGroups: query.hasQueryGroups.count];
        
        NSNumber * visibility = [[NSNumber alloc] initWithBool:isVisible];
        section.visibility = visibility;
        
        NSNumber *key = @(section.identifier);

        void (^updateVisibility)(void);
        updateVisibility = ^{
            MADDesignerSectionView *documentSectionView = sectionViewsDictionary[key];
            documentSectionView.visible = isVisible;
        };
        [[NSOperationQueue mainQueue] addOperationWithBlock:updateVisibility];

        NSError * __autoreleasing *error = NULL;
        if (![private save:error]) NSLog(@"Error saving managed object context: %@", *error);

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
    
    NSError * __autoreleasing *error = NULL;
    if (![section.managedObjectContext save:error]) NSLog(@"Error saving managed object context: %@", *error);

    
    NSNumber *key = @(section.identifier);
    UICollectionView *collectionView = self.sectionViewsDictionary[key];
    [collectionView.backgroundView setNeedsDisplay];
    [documentSectionView.collectionViewLayout invalidateLayout];
    [section setInterfaceHeight: collectionViewContentSize.height];
    if (![section.managedObjectContext save:error]) NSLog(@"Error saving managed object context: %@", *error);
    
    [self.view setNeedsUpdateConstraints];
    
}

// FIXME: Unused... Used for multiple rows in the document section... currently unused
- (void)sectionLayoutDidUpdateNumberOfRows:(int32_t)numberOfRows {
    
    MADocument *doc = self.document;
    RptqDocument *document = doc.activeDocumentModel;
    RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    RptqDocumentSection *section = [document documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel
                                                          withNumberOfGroups: query.hasQueryGroups.count];
    
    BOOL insertNewSection = numberOfRows > section.numberOfRows;
    BOOL deleteLastSection = numberOfRows < section.numberOfRows;
    
    UICollectionView *documentSectionView;
    documentSectionView = [self getSectionViewForSectionID: section.identifier];
    
    if (section.numberOfRows == (int64_t)numberOfRows) {
        
        //No change
        
    } else if ((int64_t)numberOfRows > section.numberOfRows) {
        
        //Add row
        RptqDocumentSectionRows *newRowToAppend;
        newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                       inManagedObjectContext: doc.managedObjectContext];
        NSArray *hasRowsArray = section.hasRows.array;
        NSMutableOrderedSet *hasRows;
        hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
                                        [[NSMutableOrderedSet alloc] init];
        newRowToAppend.inSection = section;
        [hasRows addObject:newRowToAppend];
        section.hasRows = hasRows;
        
    } else if ((int64_t)numberOfRows < section.numberOfRows) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = section.hasRows.lastObject;
        NSArray *hasRowsArray = section.hasRows.array;
        NSMutableOrderedSet *hasRows;
        hasRows = hasRowsArray != nil ? [[NSMutableOrderedSet alloc] initWithArray: hasRowsArray] :
                                        [[NSMutableOrderedSet alloc] init];
        if ([hasRows count] > 0) {
            [hasRows.lastObject setInSection:nil];
            [hasRows removeObjectAtIndex:hasRows.count - 1];
            section.hasRows = hasRows;
            [rowToDelete setInSection:nil];
        }
    }
    
    section.numberOfRows = numberOfRows;
    
    id sectionKey = section.objectID.copy;
    UICollectionView *collectionView = self.sectionViewsDictionary[sectionKey];
    MADDesignerSectionBackground *backgroundView = (MADDesignerSectionBackground *)collectionView.backgroundView;
    [backgroundView setNumberOfRowsInBackground:numberOfRows];
    
    NSError *error = nil;
    if (![doc.managedObjectContext save:&error]) NSLog(@"Error saving managed object context: %@", error);

    [doc saveToURL: doc.fileURL forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
               
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

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    UIBarButtonItem *undoButton = self.undoButton;
    MADocument *document = self.document;
    undoButton.enabled = document.undoManager.canUndo;
    undoButton.title = document.undoManager.undoMenuItemTitle.copy;
    
    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    
    for (id updatedObject in updatedObjects) {
        if ([updatedObject isKindOfClass:[RptqTextStyle class]]) {
            RptqTextStyle *updatedTextStyle = updatedObject;
            if (updatedTextStyle.inElement != nil) {
                MADDesignerElementView *elementView;
                elementView = [self elementViewForManagedObject:updatedTextStyle.inElement];
                [elementView updateFontName:updatedTextStyle.inElement.fontname
                                   fontSize:updatedTextStyle.inElement.fontsize
                                       bold:updatedTextStyle.bold
                                     italic:updatedTextStyle.italic];
                [elementView updateSetUnderline:updatedTextStyle.underline];
                [elementView updateSetStrikethrough:updatedTextStyle.strikethrough];
                [elementView setNeedsDisplay];
                //[elementView updateWithElement:updatedTextStyle.inElement];
            }
            
        } else if ([updatedObject isKindOfClass:[RptqDocumentElement class]]) {
            RptqDocumentElement *documentObject = updatedObject;
            NSDictionary *changes = [documentObject changedValues];
            
            MADocument *doc = self.document;
            MADDesignerSectionView *section;
            MADSectionLayoutManager *layoutManager;
            MADSectionLayoutAttributes *attributes;
            for (id change in changes) {
                
                if ([change isEqualToString: NSStringFromSelector(@selector(sizewidth))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(marginLeft))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(marginRight))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(paddingLeft))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(paddingRight))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(sizeheight))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(marginTop))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(marginBottom))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(paddingTop))] ||
                    [change isEqualToString: NSStringFromSelector(@selector(paddingBottom))]) {
                    
                    section = [self getSectionViewForSectionID: documentObject.inSectionRow.inSection.identifier];
                    
                    NSNumber *identifier = @(section.identifier);
                    layoutManager = doc.sectionLayoutManagers[identifier];
                    
                    identifier = @(documentObject.identifier);
                    attributes = layoutManager.items[identifier];
                    
                    if (attributes != nil) {
                        attributes.frame = [documentObject elementViewFrameDesigner];
                        _identifierJustDisplayed = documentObject.identifier;
                        [layoutManager positionItem:attributes];
                        [section.collectionViewLayout invalidateLayout];
                    }
                    
                }
                
            }
        } else if ([updatedObject isKindOfClass:[RptqDocumentSection class]]) {
        
            RptqDocumentSection *documentSection = updatedObject;
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
        }
    }
}

#pragma mark -
#pragma mark NSManagedObjectContextDidSaveNotification

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSManagedObjectContext *context = notification.object;
    NSManagedObject *object;
    for (object in updatedObjects) {
        if ([object isKindOfClass:[RptqDocumentElement class]]) {
            MADDesignerElementView *elementView;
            elementView = [self elementViewForManagedObject:(RptqDocumentElement *)object];
            [elementView updateForManagedObjectContent:context];
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
    
    BOOL editedImageExist = info[UIImagePickerControllerEditedImage] != nil;
    UIImage *selectedImage = nil;
    if (editedImageExist) {
        selectedImage = info[UIImagePickerControllerEditedImage];
    } else {
        selectedImage = info[UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage != nil) {
        
        //MADDesignerViewController * __weak wself = self;
        
        [self dismissViewControllerAnimated:YES completion:^{
            self.hidesStatusBar = NO;
        }];

        NSNumber *type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeImage];
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
    
    UIViewController *result;
    id presented = controller.presentedViewController;
    if (style != UIModalPresentationPopover && [presented isKindOfClass:[UINavigationController class]] == NO) {
        
        UIBarButtonItem *cancelButton;
        cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                     target: self
                                                                     action: @selector(actionCancel:)];
        [controller.presentedViewController.navigationItem setLeftBarButtonItem: cancelButton
                                                                       animated: NO];
        controller.presentedViewController.view.backgroundColor = [UIColor clearColor];
        
        UINavigationController *navigation;
        navigation = [[UINavigationController alloc] initWithRootViewController: presented];
        navigation.navigationBar.translucent = YES;
        navigation.navigationBar.backgroundColor = [UIColor clearColor];
        navigation.view.backgroundColor = [UIColor clearColor];
        result = navigation;
        
    } else if ([controller.presentedViewController isKindOfClass:[UINavigationController class]]) {
    
        if ([((UINavigationController *)controller.presentedViewController).topViewController
                isKindOfClass:[MADDesignerElementPickerViewController class]]) {
        
            UINavigationController *navigationController;
            navigationController = (UINavigationController *)controller.presentedViewController;

//???: Test one function, and uses another (topViewController)?
            if (navigationController.navigationItem.leftBarButtonItem == nil) {
                UIBarButtonItem *cancel;
                cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                       target:self
                                                                       action:@selector(actionCancel:)];
                [navigationController.topViewController.navigationItem setLeftBarButtonItem:cancel animated:NO];
            }
            
            UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
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

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
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

- (MTDocumentObjectType)objectTypeRepresentedByCell:(MADCellElement *)cell {
    RptqDocumentElement *element;
    element = [RptqDocumentElement newDocumentElementWithIdentifier: cell.identifier
                                                  fromObjectContext: _document.managedObjectContext];
    return element.type;
}

- (void)formatDocumentObjectRepresentedByCell:(MADCellElement *)cell {
    id elementView;
    
    [self deselectAllElementsAnimated:YES];
    _lastMenuItemSelectRequiresElementView = YES;
    
    elementView = [self viewForObjectID:@(cell.identifier)];
    [self selectElementView: elementView];
    
}

- (void)editDocumentObjectRepresentedByCell:(MADCellElement *)cell {
    
    NSManagedObjectContext *private;
    int64_t elementID;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    elementID = cell.identifier;
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlock:^{
    
        RptqDocumentElement *documentObject;
        RptqDocumentSection *section;
        MADDesignerSectionView *designerSectionView;
        int64_t designerSectionViewID;
        
        documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: elementID
                                                             fromObjectContext: private];
        section = documentObject.inSectionRow.inSection;
        designerSectionView = [self getSectionViewForDocumentSection:section];
        designerSectionViewID = designerSectionView.identifier;
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
                        
                    case MTDocumentObjectTypeAggregate: {
                        NSNumber *objectID  = @(objectToEdit.identifier);
                        [self editDocumentObjectAggregateWithID: objectID
                                                       objectID: objectToEdit.objectID];
                        break;
                    }
                    
                    case MTDocumentObjectTypeBarcode: {
                        NSNumber *objectID  = @(objectToEdit.identifier);
                        [self editDocumentObjectBarcodeWithID: objectID];
                        break;
                    }
                    
                    case MTDocumentObjectTypeImage: {
                        [self editDocumentObjectImage: objectToEdit];
                        break;
                    }
                        
                    case MTDocumentObjectTypeLabelDynamic:
                        [self editDocumentObjectLabelDynamic:objectToEdit];
                        break;
                        
                    case MTDocumentObjectTypeLabelStatic:
                        [self editDocumentObjectLabelStatic:objectToEdit];
                        break;
                        
                    case MTDocumentObjectTypeWhtiespace:
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
    
    void (^updateAggregate)();
    updateAggregate = ^{
        
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;
        
        UIView *viewToEdit = [strongself viewForObjectID: identifier];
        UINavigationController *navigation;
        navigation = [MADNavigationController newNavigationController: MADNavigationControllerTypeAggregateAdd];
        MADocument *document = strongself.document;
        RptqDocumentElementAggregate *aggregateToEdit = [document.managedObjectContext objectWithID:objectID];
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController;
        aggregateViewController = navigation.viewControllers.firstObject;
        aggregateViewController.document = document;
        aggregateViewController.aggregateDelegate = strongself;
        [aggregateViewController setAggregateObjectToEdit:aggregateToEdit];
        
        UIBarButtonItem *dismiss;
        dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
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
                                                        toView: strongself.scroller.container];
        
        popoverController.sourceView = strongself.scroller.container;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [strongself presentViewController:navigation animated:YES completion:nil];
        [strongself setDisplayInactive];
        
    };

    
    [[NSOperationQueue mainQueue] addOperationWithBlock:updateAggregate];
    
}

- (void)editDocumentObjectBarcodeWithID:(NSNumber *)identifier {
    
    self.barcodeToEditObjectID = identifier.copy;
    
    MADDesignerViewController * __weak weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;
        
        UIView *viewToEdit = [strongself viewForObjectID:identifier];

        MTViewControllerBarcode *barcodeViewController;
        barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
        barcodeViewController.document = strongself.document;
        barcodeViewController.delegate = strongself;
        barcodeViewController.preferredContentSize = sizePopoverFonts();
        barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
        barcodeViewController.bartcodeToEditObjectID = identifier.copy;

        UIPopoverPresentationController *popoverController;
        popoverController = barcodeViewController.popoverPresentationController;
        popoverController.delegate = strongself;
        popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
                                                        toView: strongself.scroller.container];
        popoverController.sourceView = strongself.scroller.container;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [strongself presentViewController:barcodeViewController animated:YES completion:nil];
        [strongself setDisplayInactive];
    }];
    
}

- (void)editDocumentObjectBarcode:(RptqDocumentElement *)object {
    
    UIView *viewToEdit = [self viewForObjectID:@(object.identifier)];
    
    MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode newViewControllerBarcode];
    barcodeViewController.document = self.document;
    barcodeViewController.delegate = self;
    
    barcodeViewController.preferredContentSize = sizePopoverFonts();
    barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverController;
    popoverController = barcodeViewController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
                                                    toView: self.scroller.container];
    popoverController.sourceView = self.scroller.container;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController:barcodeViewController animated:YES completion:nil];
    [self setDisplayInactive];
}

- (void)editDocumentObjectImage:(RptqDocumentElement *)object {
    self.objectIdEditImage = object.objectID.copy;
}

- (void)editDocumentObjectLabelDynamic:(RptqDocumentElement *)object {
    
    self.objectIdEditDynamicLabel = @(object.identifier);
    
    UIView *viewToEdit = [self viewForObjectID:@(object.identifier)];
    
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
                                                    toView: self.scroller.container];
    popoverController.sourceView = self.scroller.container;
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

    void (^completion)(UIAlertAction *action, NSString *text);
    completion = ^(UIAlertAction *action, NSString *text) {
        
        ((RptqDocumentElementLabel *)object).text = text.copy;
        [object.managedObjectContext save:nil];
        
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
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    NSManagedObjectID *barcodeToEditObjectID = barcodeObjectID.copy;
    [private performBlock:^{
    
        RptqDocumentElementBarcode *barcodeToEdit = [private objectWithID:barcodeToEditObjectID];
        [barcodeToEdit updateWithBarcode: barcode field1ID: fieldOne field2ID: fieldTwo];

        NSError * __autoreleasing *error = NULL;
        [private save:error];

    }];
    
}

#pragma mark -
#pragma mark - MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType: (MTAggregateFunctionType)functionType
                                inputType: (MTAggregateFunctionInputType)inputType
                              inputObject: (NSManagedObjectID *)objectID
                                groupType: (MTAggregateGroupByType)groupType
                              groupNumber: (int32_t)groupNumber {
    
    RptqDocumentElementAggregate *aggregateToEdit;
    aggregateToEdit = [self.document.managedObjectContext objectWithID: self.aggregateToEditObjectID];
    [aggregateToEdit updateAggregateFunctionWithFunctionType: functionType
                                                   inputType: MTAggregateFunctionInputTypeField
                                                   groupType: groupType
                                           aggregateObjectID: objectID
                                                 groupNumber: i32abs(groupNumber)];
}

#pragma mark -
#pragma mark - MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                    withFieldID: (NSManagedObjectID *)fieldID {

    NSManagedObjectContext *context = self.document.managedObjectContext;
    RptqQueryField *field = [context objectWithID: fieldID];
    RptqDocumentElementLabelDataField *documentObject;
    documentObject = [RptqDocumentElementLabelDataField newDocumentElementWithIdentifier: field.identifier
                                                                       fromObjectContext: context];
    documentObject.referencesQueryField = field;
    [field.managedObjectContext save:nil];
    
}

#pragma mark -
#pragma mark MADDesignerSectionLayoutLiquidDelegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView: (MADDesignerSectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADocument *document;
    MADSectionLayoutManager *layoutManager;

    document = self.document;
    layoutManager = document.sectionLayoutManagers[@(collectionView.identifier)];
    
    __block MADSectionLayoutAttributes *attributes;
    [layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id key,
                                                             MADSectionLayoutAttributes *object,
                                                            BOOL *stop) {
        if (object.indexPath.section == indexPath.section &&
            object.indexPath.row == indexPath.row) {
            attributes = object;
            *stop = YES;
        }
    }];
    

    RptqDocumentElement *documentObject;
    documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
                                                         fromObjectContext: document.managedObjectContext];
    CGFloat contextScale = self.scroller.zoomScale * self.scroller.traitCollection.displayScale;
    NSString *resuseId = [MADCellElement reuseIdentifier];
    
    MADCellElement *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId forIndexPath:indexPath];
    cell.delegate = self;
    
    CGSize documentObjectSize = [documentObject sizeCalculated];
    CGRect cellFrame = CGRectMake(CGPointZero.x, CGPointZero.y,
                                  documentObjectSize.width, documentObjectSize.height);
    
    switch (documentObject.documentObjectType) {
        case MTDocumentObjectTypeFormula:
        case MTDocumentObjectTypeLabelStatic:
        case MTDocumentObjectTypeLabelDynamic:
        case MTDocumentObjectTypeAggregate:
        default: {
            
            NSArray *subviews = cell.contentView.subviews;
            for (id subview in subviews) {
                [subview removeFromSuperview];
            }
            int64_t identifier = documentObject.identifier;
            
            cell.backgroundColor = [UIColor clearColor];
            cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
            
            MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
            [self.elementViewsDictionary setObject: elementView
                                            forKey: @(identifier)];
            
            UIGestureRecognizer *panGesture, *pinchGesture;
            panGesture = [MADPanGestureRecognizer newPanGestureRecognizerElement: self
                                                                          action: @selector(handlePanPiece:)
                                                                        delegate: self];
            [self.scroller.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
            [elementView addGestureRecognizer:panGesture];

            pinchGesture = [MADPinchGestureRecognizer newPinchGestureRecognizerElement: self
                                                                                action: @selector(handlePinchPiece:)
                                                                              delegate: self];

            [self.scroller.pinchGestureRecognizer requireGestureRecognizerToFail:pinchGesture];
            [elementView addGestureRecognizer:pinchGesture];
            
            elementView.frame = cellFrame;
            cell.identifier = documentObject.identifier;
            
            cell.userInteractionEnabled = YES;
            
            if ([self.selectedElementIDs containsObject: @(identifier)]) {
                [self applyBorderToElementView: elementView];
            }
            
            [cell addElementView:elementView];
            
            if (_identifierJustDisplayed != -1) {
                
                if (_identifierJustDisplayed == identifier) {
                    __typeof(self) __weak wself = self;
                    [elementView flash:^(BOOL finished) {
                        if (finished) {
                            typeof(self) sself = wself;
                            if (sself) {
                                sself->_identifierJustDisplayed = -1;
                            }
                        }
                    }];
                    
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

- (NSInteger)collectionView: (MADDesignerSectionView *)collectionView
     numberOfItemsInSection: (NSInteger)section {
    MADSectionLayoutManager *layoutManager;
    layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
    return (NSInteger)layoutManager.items.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView: (UICollectionView *)collectionView
       willDisplayCell: (MADManagedObjectCollectionViewCell *)cell
    forItemAtIndexPath: (NSIndexPath *)indexPath {
    
    id elementView = nil;

    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[MADDesignerElementView class]]) {
            elementView = view;
            break;
        }
    }
    
    //NSAssert(elementView != nil, @"We need an element view people.");
    if (elementView) {
        [self.visibleElementViews addObject:elementView];
    }
    [self adjustPassthroughViews];
    
}

- (void)collectionView: (UICollectionView *)collectionView
  didEndDisplayingCell: (MADManagedObjectCollectionViewCell *)cell
    forItemAtIndexPath: (NSIndexPath *)indexPath {
    
    NSSet <__kindof MADDesignerElementView *> *elementViewSet;
    
    BOOL (^predicate)(id obj, BOOL *stop);
    predicate = ^BOOL(__kindof MADDesignerElementView * _Nonnull obj, BOOL * _Nonnull stop) {
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

- (BOOL)collectionView: (UICollectionView *)collectionView
      canPerformAction: (SEL)action
    forItemAtIndexPath: (NSIndexPath *)indexPath
            withSender: (id)sender {
    
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:)) {
        result = YES;
    }
    return result;
}

- (void)collectionView: (MADDesignerSectionView *)collectionView
         performAction: (SEL)action forItemAtIndexPath: (NSIndexPath *)indexPath
            withSender: (id)sender {
    
    NSInteger row = indexPath.row;
    
    RptqDocumentSection *section;
    section = [RptqDocumentSection newDocumentSectionWithIdentifier: collectionView.identifier
                                                  fromObjectContext: _document.managedObjectContext];
    NSOrderedSet *objects = [section.hasRows[(NSUInteger)indexPath.section] hasObjects];
    
    if ((NSInteger)objects.count > row) {
        RptqDocumentElement *documentObject = objects[(NSUInteger)row];
        
        if (action == @selector(delete:)) {
            [self delete:documentObject];
        } else if (action == @selector(edit:)) {
            [self edit:documentObject];
        }
        
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                    shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self dismissAllPopovers];
    [self dismissSectionPresentationIfOpen];
    [self dismissToolboxPresentationIfOpen];
    [self deselectAllElementsAnimated:NO];
    
    MADDesignerElementView *elementView = [self elementViewAtIndexPath: indexPath
                                                      inCollectionView: collectionView];
    [self applyBorderToElementView:elementView];
    self.lastElementViewToShowMenu = elementView;
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
                                        didDeselectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView
                                        didHighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView
                                        didSelectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView
                                        didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

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
    NSNumber *objTypeKey;
    NSDictionary *parameters;
    objTypeKey = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeLabelDynamic];
    parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                            objTypeKey,     MTDocumentObjectDefinationType,
                            field.objectID, MTDocumentObjectDefinationObject, nil];
    [self insertDocumentObjectWithDefination: parameters];
    self.hidesStatusBar = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber {
    [self setDisplayActive];

    NSNumber *functionTypeNumber =  [[NSNumber alloc] initWithShort: functionType],
             *groupTypeNumber =     [[NSNumber alloc] initWithShort: groupType],
             *inputTypeNumber =     [[NSNumber alloc] initWithShort: inputType],
             *objectType =          [[NSNumber alloc] initWithShort: MTDocumentObjectTypeAggregate];
    
    NSDictionary *documentObject =  [[NSDictionary alloc] initWithObjectsAndKeys:
        functionTypeNumber,    MTDocumentObjectDefinationAggregateType,
        groupNumber,           MTDocumentObjectDefinationAggregatePivotNumber,
        groupTypeNumber,       MTDocumentObjectDefinationAggregatePivotType,
        inputObject,           MTDocumentObjectDefinationAggregateObjectId,
        inputTypeNumber,       MTDocumentObjectDefinationAggregateFunctionInputType, nil
    ];
    NSDictionary *documentObjectDefination;
    documentObjectDefination = [[NSDictionary alloc] initWithObjectsAndKeys:
                                objectType,     MTDocumentObjectDefinationType,
                                documentObject, MTDocumentObjectDefinationObject, nil];
    
    [self insertDocumentObjectWithDefination: documentObjectDefination];
    self.hidesStatusBar = NO;
}


- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
    [self setDisplayActive];
    NSNumber *type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeLabelStatic];
    NSDictionary *defination = [[NSDictionary alloc] initWithObjectsAndKeys:
                                type, MTDocumentObjectDefinationType,
                                labelText, MTDocumentObjectDefinationObject, nil];
    [self insertDocumentObjectWithDefination:defination];
}

#pragma mark - Gesture Recognizer Delegate

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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    //Require the failure of the resize handles.
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)]) {
        return YES;
    } else {
        if (otherGestureRecognizer == _strayTouchGesture &&
                                    [self.tapSectionLabels containsObject:gestureRecognizer]) {
            return YES;
        } else {
            return  NO;
        }
    }
}

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
    layoutManager = document.sectionLayoutManagers[@(collectionView.identifier)];
    NSManagedObjectContext *objectContext = document.managedObjectContext;
    RptqDocumentElement *documentObject;
    
    for (MADSectionLayoutAttributes *attributes in layoutManager.items.allValues) {
        documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: attributes.objectID
                                                             fromObjectContext: objectContext];
        [documentObject setOriginPoint:attributes.frame.origin];

        //documentObject.sizewidth = @(attributes.frame.size.width);
        //documentObject.sizeheight = @(attributes.frame.size.height);

    }

    //[objectContext save:nil];
}

- (MADSectionLayoutAttributes *)collectionView: (MADDesignerSectionView *)collectionView
                                        layout: (UICollectionViewLayout *)collectionViewLayout
            layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADSectionLayoutManager *layoutManager;
    layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
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
    layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
    return layoutManager.items.count;
}

- (NSArray *)collectionView: (MADDesignerSectionView *)collectionView
        attributesForLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADSectionLayoutManager *layoutManager;
    layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
    return layoutManager.items.allValues;
}

- (CGSize)collectionView: (MADDesignerSectionView *)collectionView
           sizeForLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADSectionLayoutManager *layoutManager;
    layoutManager = self.document.sectionLayoutManagers[@(collectionView.identifier)];
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
                [element setSizeWidth:element.sizeContentView.width *
                                      gestureRecognizer.scale];
                break;

            case vertical:
                [element setSizeHeight:element.sizeContentView.height *
                                       gestureRecognizer.scale];
                break;
                
            default: {
                CGSize s = element.sizeContentView;
                [element setSizeWidth:s.width * gestureRecognizer.scale
                               height:s.height * gestureRecognizer.scale];
                break;
            }
        
        }

    }
    gestureRecognizer.scale = 1.0000f;
    [element.managedObjectContext save:nil];
    
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

- (void)handleStrayTouch:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [[UIMenuController sharedMenuController] setMenuVisible: NO animated: YES];
        if (self.presentedViewController != nil) {
            [self actionHideToolbox];
        }
    }
}

- (void)handleToggleSectionControlPanel:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        MADDesignerSectionLabel *label = (MADDesignerSectionLabel *)sender.view;
        
        [[UIMenuController sharedMenuController] setMenuVisible: NO
                                                       animated: YES];
        
        [self dismissToolboxPresentationIfOpen];
        
        NSSet *selectedElementViews = [self selectedElementViews];
        
        if (selectedElementViews.count >= 1) {
            
            [self actionHideToolbox];
            
        } else {
            
            self.viewControllerToolbox.document = self.document;
            
            if (label.selected) {
                
                
                [label normalView];
                [self actionHideToolbox];
                
            } else {
                
                [self deselectAllElementsAnimated:YES];
                
                
                self.lastSelectedSectionControlPanel = label.tag;
                self.lastSelectedLabel = label;
                RptqDocumentSection *section = [self sectionForLabelTag:label.tag];
                MADDesignerSectionView *superView = [self getSectionViewForDocumentSection: section];
                superView.selected = YES;
                [label dimView];
                
                
                _viewControllerSectionLayoutSettings.initalHeightValue = section.height;
                _viewControllerSectionLayoutSettings.initalVisibility = section.visibility;
                _viewControllerSectionLayoutSettings.initalFormFeedEnabled = section.producesFormFeed;
                _viewControllerSectionLayoutSettings.initalNumberOfRows = section.numberOfRows;
                [_viewControllerSectionLayoutSettings updateDisplay];
                
                UIEdgeInsets ei = _viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets;
                _viewControllerSectionLayoutSettings.tableView.contentInset = UIEdgeInsetsMake(ei.top, ei.left, CGSizeZero.height, ei.right);
                _viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(ei.top, ei.left, CGSizeZero.height, ei.right);
                
                [self showSectionSettingsFromLabel:label];
                
            }
        }
    }
}

- (void)handleToggleElementView:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        MADDesignerElementView *elementView = (MADDesignerElementView *)sender.view;
        [self dismissSectionPresentationIfOpen];
        
        [self displaySectionViewsRemoveBorder];
        
        if ([self elementViewIsSelected: elementView] == NO) {
            [self selectElementView: elementView];
            
            // Select a unselected element
            [self.promptManager addString: elementView.displayStringAttributed.string];
            [self displayPrompt];
            
            if (self.selectedElementIDs.count == 1) {    // Show toolbox if we are selecting the first item.
                
                [self actionShowToolbox];
                
            } else {
                
                [self adjustToolboxLocation];
                
            }
            
            [self setDisplayInactive];
            
        } else {
            
            [self deselectElementView: elementView animated: YES];
            [self.selectedElementIDs removeObject: @(elementView.identifier)];
            (self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
            
            [self.promptManager removeString: elementView.displayStringAttributed.string];
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

    type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeWhtiespace];
    options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            type, MTDocumentObjectDefinationType, nil];
                                            
    [self insertDocumentObjectWithDefination: options];
    [self scrollToDetailSectionView];
}

- (void)saveDynamicLabel:(MADQueryChooseFieldController *)viewController {
    
    MADQueryChooseFieldController *dynamicFieldController;
    dynamicFieldController = (MADQueryChooseFieldController *)viewController;
 
    NSManagedObjectID *objectID = dynamicFieldController.queryFieldID.copy;

    NSNumber *keyDynamic = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeLabelDynamic];
    NSDictionary *definations = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    keyDynamic, MTDocumentObjectDefinationType,
                                    objectID, MTDocumentObjectDefinationObject, nil];
    
    [self insertDocumentObjectWithDefination: definations];
    
    [self scrollToDetailSectionView];
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
    
    if (_editAggregate && _aggregateToEditObjectID != nil) {
        
        if (viewController.fieldObjectID != nil) {
            RptqDocumentElementAggregate *aggregateToEdit;
            aggregateToEdit = [self.document.managedObjectContext objectWithID: _aggregateToEditObjectID];
            [aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
                                                                inputType: MTAggregateFunctionInputTypeField
                                                                groupType: viewController.aggregateGroupByType
                                                        aggregateObjectID: viewController.fieldObjectID
                                                              groupNumber: viewController.groupTypeSectionNumber];
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
        
        MTBarcode *barcode = viewController.barcode;
        
        NSManagedObjectContext *managedObjectContext = _document.managedObjectContext;
        RptqDocumentElementBarcode *object;
        object = [RptqDocumentElementBarcode newDocumentElementWithIdentifier: _objectIdEditBarcode.longLongValue
                                                            fromObjectContext: managedObjectContext];

        [object updateWithBarcode: barcode
                         field1ID: viewController.queryField1ID
                         field2ID: viewController.queryField2ID];
        _objectIdEditBarcode = nil;
        
    } else {
        
        NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
        NSNumber *type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeBarcode];
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
        [self insertDocumentObjectWithDefination:defination];
        
    }
    [self scrollToDetailSectionView];
}

#pragma mark -
#pragma mark Helpers

- (BOOL)elementViewIsSelected:(MADDesignerElementView *)elementView {
    return [self.selectedElementIDs containsObject:@(elementView.identifier)];
}

- (void)removeBorderFromAllSectionViews {
    NSEnumerator <MADDesignerSectionLabel *> *labels;
    labels = self.sectionControlViewsDictionary.objectEnumerator;
    for (MADDesignerSectionLabel *label in labels) {
        [self removeBorderFromSectionLabel: label];
    }
}

- (void)adjustContextOffsetForToolboxWithToolboxType:(MTToolboxType)toolboxType {
    switch (toolboxType) {
        case MTToolboxTypeSection:
            [self adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:self];
            break;
        case MTToolboxTypeElement:
            [self adjustContentOffsetForSelectedElements];
            break;
        default:
            break;
    }
}

- (void)adjustContentOffsetForSelectedElements {
    if (_toolboxTransitioningDelegate.presentationController.presentedViewController != nil &&
        [_toolboxTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
        
        CGRect frame, bounds;
        frame = ((MADToolboxTransitioningDelegate *)_toolboxTransitioningDelegate).
                                        presentationController.presentedViewController.view.frame;
        bounds = [self.scroller positionForRectOfInterest: [self rectForSelectedElements]
                                               withPresentedRect: frame
                                                   containerSize: self.view.frame.size
                                                      adjustment: self.topLayoutGuide.length];
        [self repositionSectionViews:bounds];
    }
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:(MADDesignerViewController *)reportDesigner {
    RptqDocument *document = self.document.activeDocumentModel;
    RptqQuery *query = document.defaultDatabase.defaultQuery;
    RptqDocumentSection *documentSection;
    documentSection = [document documentSectionForSelectedIndex: (NSUInteger)reportDesigner.lastSelectedSectionControlPanel
                                             withNumberOfGroups: query.hasQueryGroups.count];

    
    UIView *selectedSectionView = [reportDesigner getSectionViewForDocumentSection:documentSection];
    if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
        [self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
        CGRect presentedRect, position;
        presentedRect = ((MADToolboxTransitioningDelegate *)self.settingsTransitioningDelegate).
                                        presentationController.presentedViewController.view.frame;
        position = [self.scroller positionForRectOfInterest: selectedSectionView.frame
                                          withPresentedRect: presentedRect
                                              containerSize: self.view.frame.size
                                                 adjustment: self.topLayoutGuide.length];
        [self repositionSectionViews:position];
    }
}

- (void)repositionSectionViews:(CGRect)presentedRect {
    if (presentedRect.origin.x > CGPointZero.x) {
        for (UICollectionView *sectionView in self.sectionViewsDictionary.objectEnumerator) {
            sectionView.contentInset = ScrollIndicatorContentInsets(presentedRect);
            sectionView.scrollIndicatorInsets = ScrollIndicatorContentInsets(presentedRect);
        }
    }
    
}

- (void)selectElementView:(MADDesignerElementView *)elementView {
    if (self.selectedSections.count > 0) {
        [self removeBorderFromAllSectionViews];
    } else {
        [self.selectedElementIDs addObject: @(elementView.identifier)];
        [self applyBorderToElementView: elementView];
        
        self.viewControllerToolbox.document = self.document;
        self.viewControllerToolbox.selectedElementIDs = self.selectedElementIDs;
    }
}

- (void)deselectElementView:(MADDesignerElementView *)elementView
                   animated:(BOOL)animated {
    
    [self removeBorderFromView: elementView];
    
    NSArray <UIView *> *passThroughViewsArray;
    NSMutableSet <UIView *>  * _Nullable passThroughViewsSet;
    passThroughViewsArray = self.popoverToolbox.passthroughViews;
    if (!passThroughViewsArray) goto END_deselectElementView;
    
    passThroughViewsSet = [[NSMutableSet alloc] initWithArray: passThroughViewsArray];
    [passThroughViewsSet removeObject: elementView];
    self.popoverToolbox.passthroughViews = passThroughViewsSet.allObjects;
    
END_deselectElementView:;

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
    NSIndexPath *indexPath;
    MADDesignerElementView *elementView;
    for (indexPath in indexPathsForVisibleItems) {
        elementView = [self elementViewAtIndexPath: indexPath
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
    RptqDocumentSection *section = rptqDocument.hasDetailSection;
    
    MADDesignerSectionView *collectionView;
    MADSectionLayoutManager *layoutManager;

    collectionView = [self getSectionViewForDocumentSection: rptqDocument.hasDetailSection];
    layoutManager = document.sectionLayoutManagers[@(collectionView.identifier)];
    
    MADDesignerViewController * __weak weakself = self;
    [collectionView performBatchUpdates:^{

        MADDesignerViewController * sself = weakself;
        
        NSIndexPath *path;
        NSArray *indexPathsInserted;
        MADSectionLayoutAttributes *layoutAttribute;
        RptqDocumentElement *element = [rptqDocument addDocumentObject:documentObjectDefination];

        NSArray *objects = [[NSArray alloc] initWithObjects:element, nil];

        NSError * __autoreleasing *error = NULL;
        [rptqDocument.managedObjectContext obtainPermanentIDsForObjects: objects
                                                                  error: error];
        
        path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
                                   inSection: 0];
        
        sself->_identifierJustDisplayed = element.identifier;
        
        layoutAttribute.frame = [element elementViewFrameDesigner];
        
        indexPathsInserted = [[NSArray alloc] initWithObjects: path, nil];
        [section addDocumentObject: element
                     withDropPoint: layoutAttribute.frame.origin
              managedObjectContext: section.managedObjectContext];
        
        [collectionView insertItemsAtIndexPaths: indexPathsInserted];
        [section.managedObjectContext save:nil];

        layoutAttribute = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
        layoutAttribute.objectID = element.identifier;
        
        [layoutManager addItem:layoutAttribute];
        [layoutManager layout];

    } completion:^(BOOL finished) {
        
        [weakself.scroller.container setNeedsUpdateConstraints];
        
    }];
}

- (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell {
    int64_t cellIdentifier = cell.identifier;
    NSNumber *objectId = @(cellIdentifier);
    
    MADocument *document;
    NSArray *elements;
    __kindof RptqDocumentElement *element;
    MADDesignerSectionView *sectionView;
    MADSectionLayoutManager *layoutManager;
    MADSectionLayoutAttributes *itemToRemove;
    
    document = _document;
    NSFetchRequest <__kindof RptqDocumentElement *> *fetchElement;
    fetchElement = [RptqDocumentElement fetchRequestElement:cell.identifier];
    NSError * __autoreleasing error = NULL;
    elements = [self.document.managedObjectContext executeFetchRequest: fetchElement
                                                                 error: &error];
    element  = elements.firstObject;
    sectionView = [self getSectionViewForDocumentSection:element.inSectionRow.inSection];
    layoutManager = document.sectionLayoutManagers[@(sectionView.identifier)];
    itemToRemove = (layoutManager.items)[objectId];
    
    [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
    
        MADocument *maDocument = self.document;
        [maDocument removeDocumentObjectWithObjectID: cellIdentifier];
    
    } animationComplete:^() {

        [self.scroller.container invalidateIntrinsicContentSize];
        [self.view setNeedsUpdateConstraints];

    } completion:^() {

        [self redrawAllElementViewsInCollectionView:sectionView];
        RptqDocumentElement *elementB;
        elementB = [RptqDocumentElement newDocumentElementWithIdentifier:cellIdentifier
                                                       fromObjectContext:document.managedObjectContext];
        [document.managedObjectContext deleteObject:elementB];
        [document.managedObjectContext save:nil];

    }];
}

- (CGRect)rectForSelectedElements {
    NSSet *views = [self selectedElementViews];
    return [self.scroller.container popoverRectForSelectedViews:views];
}

- (UIView *)viewForObjectID:(NSNumber *)objectID {

    id result = [self.elementViewsDictionary objectForKey:objectID];
    if (result != nil) return result;
    
    result = [self.sectionControlViewsDictionary objectForKey:objectID];
    if (result != nil) return result;

    result = [self.sectionViewsDictionary objectForKey:objectID];

    return result;
    //return [self.scroller.container viewWithTag: (NSInteger)objectID.hash];
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
        self.settingsTransitioningDelegate.passthroughContainers =  self.passthroughContainers;
        self.settingsTransitioningDelegate.passthroughViews =       [self passthroughViews];
        self.settingsTransitioningDelegate.passthroughContainer =   self.scroller;
    } else if (_toolboxVisible) {
        self.toolboxTransitioningDelegate.passthroughContainers =   self.passthroughContainers;
        self.toolboxTransitioningDelegate.passthroughViews =        [self passthroughViews];
        self.toolboxTransitioningDelegate.passthroughContainer =    self.scroller;
    }
    
}

- (void)dismissSectionPresentationIfOpen {
    
    if (_sectionSettingsVisible &&
        self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
        
        _sectionSettingsVisible = NO;
        [self dismissViewControllerAnimated: YES completion: NULL];
        [self removeBorderFromAllSectionViews];
        [self.document.managedObjectContext save:nil];
        
    }
    
}

- (void)dismissToolboxPresentationIfOpen {
    
    if (_toolboxVisible &&
        self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
        
        _toolboxVisible = NO;
        [self dismissViewControllerAnimated: YES completion: NULL];
        [self deselectAllElementsAnimated:YES];
        [self.document.managedObjectContext save:nil];
        
    }
    
}

#pragma mark -
#pragma mark Gesture Helpers

- (void)translatePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    gestureRecognizer.view.center = CGPointMake(gestureRecognizer.view.center.x + translation.x,
                                                gestureRecognizer.view.center.y + translation.y);
    [gestureRecognizer setTranslation:CGPointZero inView:self.view];
}

- (void)beginPanPiece: (MADDesignerElementView *)piece transition: (void (^)(void))transition
           completion: (void (^)(void))completion {
    
    [[UIMenuController sharedMenuController] setMenuVisible: NO animated: YES];
    
    if (self.presentedViewController != nil) {
        [self actionHideToolbox];
    }
    
    [self setScrollersEnabled: NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        piece.alpha = 0.80000f;
    }];
    [self.scroller.container bringSubviewToFront: piece];

    int64_t pieceID = piece.identifier;

    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = _document.managedObjectContext;
    
    MADDesignerViewController __weak *weakself = self;
    [private performBlockAndWait:^{
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;
        
        RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: pieceID
                                                                                  fromObjectContext: private];
        NSNumber *sectionIdentifier;
        sectionIdentifier = @(documentObject.inSectionRow.inSection.identifier);

        MADDesignerViewController __weak *weakself1 = strongself;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            MADDesignerViewController *strongself1 = weakself1;
            
            MADDesignerSectionView *sectionView;
            sectionView = strongself1.sectionViewsDictionary[sectionIdentifier];
            CGRect b = [strongself1.view convertRect:piece.frame fromView:sectionView];
            piece.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, b.size.width, b.size.height);
            [strongself1.view addSubview: piece];
            
            [UIView animateWithDuration:0.2 animations:^{
                piece.alpha = 0.80000f;
            }];
            
            transition();
            
            MADocument *document = strongself1.document;
            MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[@(sectionView.identifier)];
            MADSectionLayoutAttributes *itemToRemove = (layoutManager.items)[@(pieceID)];
            
            MADocument * __weak wdocument = document;
            MADDesignerViewController __weak *weakself2 = strongself1;
            [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
            
                [wdocument removeDocumentObjectWithObjectID: pieceID];
                
            } animationComplete:^() {

                MADDesignerViewController *strongself2 = weakself2;
                [strongself2.scroller.container invalidateIntrinsicContentSize];
                [strongself2.view setNeedsUpdateConstraints];

            } completion:^() {

                [weakself2 redrawAllElementViewsInCollectionView:sectionView];
                completion();

            }];
        }];
        
    }];
}

- (void)endPanPieceWithGesture:(UIPanGestureRecognizer *)gesture {

    MADDesignerElementView *piece = (MADDesignerElementView *)gesture.view;
    NSNumber *pieceObjectIdTag = @(piece.identifier);
    int64_t pieceIdentifier = piece.identifier;
    MADDesignerSectionView *sectionView = nil;

    for (UIView *subview in self.scroller.container.subviews) {
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
        for (UICollectionView *view in self.scroller.container.subviews) {
            if ([view isKindOfClass: [MADDesignerSectionView class]]) {
                CGPoint p1 = [self.view convertPoint:gesture.view.frame.origin toView:self.view];
                CGPoint p2 = [_scroller.container convertPoint:view.frame.origin toView:self.view];
                if ((distance = (CGFloat)MADDistance(p1, p2)) < minDistance) {
                    sectionView = (MADDesignerSectionView *)view;
                    minDistance = distance;
                }
            }
        }
        
        if (sectionView == nil) {
            for (UICollectionView *view in self.scroller.container.subviews) {
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
        NSManagedObjectContext *private;
        
        private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        private.parentContext = self.document.managedObjectContext;
        [private performBlockAndWait:^{

            RptqDocumentSection *documentSection;
            documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
                                                                  fromObjectContext:private];
            NSNumber *documentSectionKey = @(documentSection.identifier);
            CGFloat documentSectionHeight = documentSection.height;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
                NSLayoutConstraint *layoutConstraint;
                layoutConstraint = self.layoutConstraintsReportSectionHeight[documentSectionKey];
                layoutConstraint.constant = documentSectionHeight;
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
                    
                    la.frame = CGRectMake(locationInSection.x, locationInSection.y,
                                          documentObjectSize.width, documentObjectSize.height);
                    [layoutManager addItem:la];
                    [layoutManager layout];
                    [piece removeFromSuperview];
                    
                    [documentSectionBlock addDocumentObject: documentObject
                                              withDropPoint: locationInSection
                                       managedObjectContext: managedObjectContext];
                    NSError * __autoreleasing *error = nil;
                    [managedObjectContext save:error];
                    
                    
                } animationComplete:^() {
                    
                    [self.scroller.container invalidateIntrinsicContentSize];
                    [self.view setNeedsUpdateConstraints];
                    
                } completion:^() {
                    
                    NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
                    

                    RptqDocumentSection *sectionBlock;
                    sectionBlock = [RptqDocumentSection newDocumentSectionWithIdentifier:sectionViewObjectIdTag.longLongValue
                                                                       fromObjectContext:managedObjectContext];

                    CGFloat sectionViewIntrinsicContentSizeHeight = [sectionView intrinsicContentSize].height;
                    sectionBlock.height = sectionViewIntrinsicContentSizeHeight;
                    
                    NSError * __autoreleasing *error = nil;
                    [managedObjectContext save:error];
                    
                    
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
        CGPoint locationInSuperview = [gestureRecognizer locationInView:self.scroller.container];
        locationInSuperview = [self.scroller.container convertPoint:locationInSuperview toView:self.view];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

#pragma mark -
#pragma mark Display Helpers

- (void)relayoutSectionView:(MADDesignerSectionView *)documentSectionView {
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    int64_t objectId = documentSectionView.identifier;
    __block CGFloat height;

    [private performBlockAndWait:^{
        RptqDocumentSection *documentSection;
        documentSection = [RptqDocumentSection newDocumentSectionWithIdentifier: objectId
                                                              fromObjectContext: private];
        height = documentSection.height;
    }];
    
    NSLayoutConstraint *layoutConstraint = self.layoutConstraintsReportSectionHeight[@(objectId)];
    layoutConstraint.constant = height;
    [self.view setNeedsUpdateConstraints];
}

- (void)setDisplayActive {
    [self setHidesStatusBar: NO];
    _sectionSettingsVisible = NO;
    _toolboxVisible = NO;
    
    MADTabBarController *tabBarController;
    tabBarController = (MADTabBarController *)self.navigationController.tabBarController;
    tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [tabBarController enableTabBarItems];
}

- (void)setDisplayInactive {
    MADTabBarController *tabBarController;
    tabBarController = (MADTabBarController *)self.navigationController.tabBarController;
    tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [tabBarController disableTabBarItems];
}

- (void)setScrollersEnabled:(BOOL)enabled {

    MADBackgroundScrollView *scroller = _scroller;
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
    MADDesignerElementView *elementView;
    NSIndexPath *path;
    NSMutableArray <MADDesignerElementView *> *elementViews;
    elementViews = [[NSMutableArray <MADDesignerElementView *> alloc] initWithCapacity:numberOfItemsInSection];
    for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
        
        path = [NSIndexPath indexPathForItem:(NSInteger)item inSection:section];
        elementView = [self elementViewAtIndexPath: path
                                  inCollectionView: collectionView];
        if (elementView != nil) [elementViews addObject:elementView];
    }
    return elementViews;
}

- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifier {
    MADDesignerSectionView *documentSectionView = nil;
    NSArray<__kindof UIView *> *subviews = _scroller.container.subviews;
    for (UIView *subview in subviews) {
        if (subview.tag == identifier && [subview isKindOfClass:[MADDesignerSectionView class]]) {
            documentSectionView = (MADDesignerSectionView *)subview;
            break;
        }
    }
    return documentSectionView;
}

- (NSSet *)selectedElementViews {
    
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    if (self.selectedElementIDs.count > 0) {
        
        //Try quick hash method...
        BOOL quickHashWorks = YES;
        for (NSNumber *selectedObjectId in self.selectedElementIDs) {
            UIView *selectedView = [self viewForObjectID:selectedObjectId];
            if (selectedView != nil) {
                [results addObject:selectedView];
            } else {
                quickHashWorks = NO;
            }
        }
        
        NSAssert(quickHashWorks, @"Maybe not such a good idea.");
        if (quickHashWorks == NO) {     //Case when views are off screen.
            
            RptqDocumentSectionEnumerator *sectionEnumerator;
            sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
            
            for (RptqDocumentSection *documentSection in sectionEnumerator) {
                MADDesignerSectionView *documentSectionView;
                documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier];
                
                for (NSInteger section = 0;
                     section < [documentSectionView numberOfSections];
                     section++) {
                
                    for (NSInteger item = 0;
                         item < [documentSectionView numberOfItemsInSection:section];
                         item++) {
                        
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                        MADDesignerElementView *elementView = [self elementViewAtIndexPath:indexPath
                                                                          inCollectionView:documentSectionView];
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
    return self.sectionViewsDictionary[@(sectionID)];
}

- (MADDesignerSectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)section {
    return self.sectionViewsDictionary[@(section.identifier)];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)section {
    return self.sectionControlViewsDictionary[@(section.identifier)];
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
    
    //Remove border from element views
    for (MADDesignerElementView *elementView in [self selectedElementViews]) {
        [self deselectElementView: elementView
                         animated: animated];
    }
    
    [self.selectedElementIDs removeAllObjects];
    (self.viewControllerToolbox).selectedElementIDs = self.selectedElementIDs;
    
    [self displaySectionViewsRemoveBorder];
    
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

- (void)displaySectionViewsRemoveBorder {
    
    //Remove border from the section views
    [_sectionControlViewsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionLabel *view, BOOL *stop) {
        [view normalView];
    }];
    
    //Remove border from the section views
    [_sectionViewsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionView *view, BOOL *stop) {
        view.selected = NO;
    }];
    
}

- (void)applyBorderToSectionLabel:(MADDesignerSectionLabel *)view {
    
    NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
    [self.selectedSections addObject:key];
    
    UIColor *tintColor = [MADColorEverydayApps newColorAnalogous4];
    view.layer.borderColor = tintColor.CGColor;
    view.layer.borderWidth = [UIView borderWidthThin];
}

- (void)applyBorderToElementView:(MADDesignerElementView *)view {
    
    view.enableResizing = YES;
    
    NSNumber *key = @(view.identifier);
    [self.selectedElements addObject:key];
    
    UIColor *tintColor = [MADColorEverydayApps newColorAnalogous4];
    view.layer.borderColor = tintColor.CGColor;
    view.layer.borderWidth = [UIView borderWidthThin];
    
}

- (BOOL)removeBorderFromSectionLabel:(MADDesignerSectionLabel *)label {
    BOOL result;
    NSNumber *key = [[NSNumber alloc] initWithInteger:label.tag];
    if ([self.selectedSections containsObject:key]) {
        [self.selectedSections removeObject:key];
        UIColor *color = [UIColor blackColor];
        label.layer.borderColor = color.CGColor;
        label.layer.borderWidth = 0;
        result = YES;
    } else {
        result = NO;
    }
    return result;
}

- (BOOL)removeBorderFromView:(MADDesignerElementView *)view {
    BOOL result;
    NSNumber *key = @(view.identifier);
    if ([self.selectedElements containsObject:key]) {
        [self.selectedElements removeObject:key];
        result = YES;
        UIColor *color = [UIColor blackColor];
        view.layer.borderColor = color.CGColor;
        view.layer.borderWidth = 0;
        view.enableResizing = NO;
    } else {
        result = NO;
    }
    return result;
}

- (BOOL)isBorderAppliedToSectionLabel:(MADDesignerSectionLabel *)view {
    NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
    NSNumber *borderAppliedToView = _borderAppliedToView[key];
    return borderAppliedToView == nil ? NO : borderAppliedToView.boolValue;
}

- (BOOL)isBorderAppliedToElementView:(MADDesignerElementView *)view {
    NSNumber *key = @(view.identifier);
    NSNumber *borderAppliedToView = _borderAppliedToView[key];
    return borderAppliedToView == nil ? NO : borderAppliedToView.boolValue;
}

- (MADDesignerElementView *)elementViewForManagedObject:(__kindof RptqDocumentElement *)managedObject {

    id elementView;
    NSNumber *identifier = @(managedObject.identifier);
    elementView = [self viewForObjectID:identifier];
    if (elementView) goto ElementViewForManagedObjectShortCircut;

    SEL handleTap = @selector(handleToggleElementView:);
    elementView = [MADDesignerElementView newDesignerElementViewForDocumentObject: managedObject
                                                               tapGestureDelegate: self
                                                                      tapSelector: handleTap];
    ElementViewForManagedObjectShortCircut:;
    
    return elementView;
}

#pragma mark -
#pragma mark Constraints Helpers

- (CGRect)detailDisplayFrame {
    return CGRectMake(DetailDisplayFrameOriginX(self.view.frame.size.width),
                      DetailDisplayFrameOriginY(self.topLayoutGuide.length),
                      MADSizeWidthViewDetailDisplay,
                      MADSizeHeightViewDetailDisplay);
}

- (CGSize)designerContentViewSize {
    
    CGFloat height = (self.sectionViewsArray.count * MTReportDesignerBufferPaddingVertical) +
                        (2 * MTReportDesignerBorderPaddingVertical) +
                        self.ruler.intrinsicContentSize.height;
    MADDesignerSectionView *sectionView;
    NSArray *sectionViews = self.sectionViewsArray;
    for (sectionView in sectionViews) {
        height += sectionView.frame.size.height <= CGSizeZero.height ?
        ceil(sectionView.intrinsicContentSize.height) :
        sectionView.frame.size.height;
    }
    return CGSizeMake(self.view.bounds.size.width, height);
}

- (void)scrollToDetailSectionView {
    if (self.presentedViewController != nil) {
        UIView *sectionView = [self detailSectionView];
        CGRect rect = sectionView.frame;
        self.hidesStatusBar = NO;
        [self.scroller scrollRectToVisible:rect animated:YES];
    }
}

- (UIView *)detailSectionView {
    return (UIView *)_sectionControlViewsDictionary[@(_document.activeDocumentModel.hasDetailSection.identifier)];
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
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidChange:)
                          name: NSManagedObjectContextObjectsDidChangeNotification
                        object: document.managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: document.managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(didHideMenuNotification:)
                          name: UIMenuControllerDidHideMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(willHideMenuNotification:)
                          name: UIMenuControllerWillHideMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(didShowMenuNotification:)
                          name: UIMenuControllerDidShowMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(willShowMenuNotification:)
                          name: UIMenuControllerWillShowMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(documentStateChanged)
                          name: UIDocumentStateChangedNotification
                        object: document];
}

- (void)removeObservers {
    
    MADocument *document = self.document;
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextObjectsDidChangeNotification
                           object: document.managedObjectContext];
    
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextDidSaveNotification
                           object: document.managedObjectContext];
    
    [defaultCenter removeObserver: self
                             name: UIMenuControllerDidHideMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: UIMenuControllerDidShowMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: UIMenuControllerWillHideMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: UIMenuControllerWillShowMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: UIDocumentStateChangedNotification
                           object: document];
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionDone:(id)sender {
    NSError *error = nil;
    [self.document.managedObjectContext save:&error];
    if (![self dismissAllPopovers]) {
        [self.delegate viewControllerDidFinish:nil];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (IBAction)actionAdd:(id)sender {
    
    UINavigationController *navigationController;
    MADDesignerElementPickerViewController *pickerController;
    UIPopoverPresentationController *popoverController;

    navigationController = [MADNavigationController newNavigationController: MADNavigationControllerTypeElementPicker];
    
    pickerController = (MADDesignerElementPickerViewController *)navigationController.topViewController;
    pickerController.objectSelectorDelegate = self;
    pickerController.document = self.document;
    
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.preferredContentSize = sizePopoverDefault();
    
    popoverController = navigationController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.barButtonItem = sender;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: navigationController animated: YES completion:^{
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
    [self.document.managedObjectContext save:nil];
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
    
    self.toolboxTransitioningDelegate.sourceView = self.scroller.container;
    self.toolboxTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
    self.toolboxTransitioningDelegate.popoverPresentationControllerDelegate = self;
    self.toolboxTransitioningDelegate.container = self.scroller.container;
    self.toolboxTransitioningDelegate.passthroughContainers = self.passthroughContainers;
    self.toolboxTransitioningDelegate.passthroughViews = [self passthroughViews];
    self.toolboxTransitioningDelegate.passthroughContainer = self.scroller;
    
    self.viewControllerToolbox.clearsBackground = [self padLike];
    self.viewControllerToolbox.document = self.document;
    [self adjustToolboxLocation];
    
    [self presentViewController: self.navigationControllerToolbox animated: YES completion: ^{
        [self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeElement];
    }];
    
}

#pragma mark -
#pragma mark Convenience

- (BOOL)padLike {
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
           self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

- (void)showSectionSettingsFromLabel:(UILabel *)label {
    
    _toolboxVisible = NO;
    self.settingsTransitioningDelegate.sourceRect = label.frame;
    self.settingsTransitioningDelegate.sourceView = self.scroller.container;
    self.settingsTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
    self.settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;
    self.settingsTransitioningDelegate.container = self.scroller.container;
    self.settingsTransitioningDelegate.passthroughContainers = self.passthroughContainers;
    self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
    self.settingsTransitioningDelegate.passthroughContainer = self.scroller;
    
    if (_sectionSettingsVisible == NO) {
        _sectionSettingsVisible = YES;
        [self presentViewController: self.navigationControllerSectionLayoutSettings animated: YES completion: ^{
            [self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
        }];
    } else {
        [self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
    }
    
}

- (NSSet <__kindof UIView *> *)passthroughViews {
    NSSet <__kindof UIView *> *sectionLabels = self.passthroughContainers;
    return [sectionLabels setByAddingObjectsFromSet:self.visibleElementViews];
}

@end
