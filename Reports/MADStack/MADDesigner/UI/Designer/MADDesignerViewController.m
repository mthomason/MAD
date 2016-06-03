//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerViewController.h"

#import <math.h>

#import <MADCocoaExtensions/MADCompassDirection.h>
#import <MADCocoaExtensions/MADResizeAspect.h>

#import <MADCocoaExtensions/UIAlertController+Constructors.h>   //Sucks... drags in UIKit
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <MAD/MADocument.h>
#import <MAD/MADFont.h>

#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADSectionLayoutAttributes.h>

#import <MAD/NSManagedObject+Extras.h>
#import <MAD/NSManagedObjectID+Extras.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDocumentObject+Extras.h>
#import <MAD/RptqDocumentObjectBarcode+Extras.h>

#import <MAD/RptqDocumentObjectLabel.h>
#import <MAD/RptqDocumentObjectLabelDataField.h>
#import <MAD/RptqDocumentObjectAggregate+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentSectionEnumerator.h>

#import "MADTabBarController.h"
#import "MADManagedObjectView.h"

#import "MTRulerView.h"
#import "MADNavigationBarTitleView.h"

#import "MADDesignerElementView.h"
#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"

#import "MADDesignerElementPickerViewController.h"

#import "MTCollectionViewCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"

#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerSectionBackgroundView.h"

#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTCollectionViewLayoutLiquidAttributes.h"

#import "MADPopoverBackgroundView.h"

#import "MADToolboxPresentationController.h"

#import "MADDesignerStatusLabel.h"
#import "MADBackgroundScrollView.h"
#import "MADPromptManager.h"

#import "MTQueryBuilderChooseFieldDelegate.h"
#import "MTQueryBuilderChooseFieldViewController.h"

#import "MADToolboxViewController.h"
#import "MADToolboxTransitioner.h"

#import "MADToolboxNavigationController.h"

#import "MTReportDesignerSectionViewLayoutLiquid.h"

#import "NSLayoutConstraint+Designer.h"
#import "UITapGestureRecognizer+Designer.h"
#import "UINavigationController+Designer.h"
#import "MTViewControllerBarcode+Designer.h"
#import "MTQueryBuilderChooseFieldViewController+Designer.h"
#import "UIViewController+tabBarItem.h"
#import "UIView+Extras.h"

#import "MADStoryboard.h"

#import "MTViewControllerBarcode.h"

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
    MTToolboxTypeNone = 4,
};

typedef NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADDesignerSectionView *> MADMutableMapSectionViews;
typedef NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADDesignerSectionLabel *> MADMutableMapSectionLabels;

typedef NSMutableDictionary <NSNumber *, NSNumber *> MADMutableMapNumbersByNumber;

typedef NSMutableArray  <__kindof MADDesignerSectionView *> MADMutableSectionViews;
typedef NSMutableSet    <__kindof MADDesignerSectionView *> MADMutableSetSectionViews;

typedef NSMutableSet    <__kindof MADDesignerElementView *> MADMutableSetElementViews;

typedef NSMutableArray  <NSLayoutConstraint *>              MADMutableLayoutConstraints;
typedef NSArray         <NSLayoutConstraint *>              MADLayoutConstraints;

typedef NSMutableArray  <NSManagedObjectID *>               MADMutableManagedObjectIDs;
typedef NSMutableSet    <NSManagedObjectID *>               MADMutableSetManagedObjectIDs;


static const CGFloat MADDefaultsPopooverWidth              = 320.0000f;
static const CGFloat MADDefaultsPopooverHeight             = 480.0000f;

static NSString * const MADImageBarButtonItemMadDesigner8                   = @"UIBarButtonItemMadDesigner8";
static NSString * const MADImageBarButtonItemMadDesigner                    = @"UIBarButtonItemMadDesigner";
static NSString * const MTSegueNewDocumentObjectStaticLabelSaveIdentifer    = @"MTSegueNewDocumentObjectStaticLabelSaveIdentifer";
static NSString * const MTSegueNewDocumentObjectDynamicLabelSaveIdentifer   = @"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer";
static NSString * const MTSegueChooseWhitespaceSaveIdentifer                = @"MTSegueChooseWhitespaceSaveIdentifer";
static NSString * const MTSegueChooseImageSaveIdentifer                     = @"MTSegueChooseImageSaveIdentifer";

static NSString * const MTIdentifierSegueEditFieldExit                      = @"MTIdentifierSegueEditFieldExit";
static NSString * const MTSegueNewDocumentObjectAggregateLabelSaveIdentifer = @"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer";
static NSString * const MTSegueNewDocumentObjectBarcodeSaveIdentifer        = @"MTSegueNewDocumentObjectBarcodeSaveIdentifer";
static NSString * const MADDesignerStoryboardID                             = @"MADIdentifierStoryboardDesignerViewController";

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


@interface MADDesignerViewController()
<MTViewControllerBarcodeDelegate,
    MTViewControllerAggregateDelegate,
    MTCollectionViewCellElementDelegate,
    MTReportDesignerSectionViewLayoutLiquidDelegate,
    MADDesignerElementPickerDelegate,
    MTViewControllerProtocol,
    MTReportDesignerSectionLayoutSettingsDelegate,
    MTQueryBuilderChooseFieldDelegate,
    MTTabBarImageProtocol,
    UIPopoverPresentationControllerDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UIGestureRecognizerDelegate,
    UINavigationControllerDelegate,
    UIScrollViewDelegate,
    UIImagePickerControllerDelegate>

    @property (nonatomic, weak) IBOutlet MADBackgroundScrollView    *scroller;

    @property (nonatomic, strong) MADMutableSetElementViews         *visibleElementViews;
    @property (nonatomic, strong) MADMutableSetSectionViews         *passthroughContainers;
    @property (nonatomic, strong) MADMutableSetManagedObjectIDs     *selectedObjectIds;

    @property (nonatomic, strong) MADMutableSectionViews            *sectionViewsArray;

    @property (nonatomic, strong) MADMutableMapSectionViews         *sectionViewsDictionary;
    @property (nonatomic, strong) MADMutableMapSectionLabels        *sectionControlViewsDictionary;

    @property (nonatomic, strong) MADMutableLayoutConstraints *viewDidAppearDesignerScrollViewConstraints;
    @property (nonatomic, strong) MADMutableLayoutConstraints *viewDidAppearDesignerContentViewConstraints;
    @property (nonatomic, strong) MADMutableLayoutConstraints *layoutConstraintSectionLabelHeightContainer;
    @property (nonatomic, strong) MADMutableLayoutConstraints *layoutConstraintsSectionsSidesBorder;
    @property (nonatomic, strong) MADMutableLayoutConstraints *layoutConstraintsSectionsVerticalBuffer;

    @property (nonatomic, strong) NSMutableDictionary <__kindof NSManagedObjectID *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;

    @property (nonatomic, strong) MADMutableMapNumbersByNumber *borderAppliedToView;

    @property (nonatomic, weak) MADDesignerElementView *lastElementViewToShowMenu;

    @property (nonatomic, strong) MADToolboxTransitioningDelegate *toolboxTransitioningDelegate;
    @property (nonatomic, strong) MADToolboxTransitioningDelegate *settingsTransitioningDelegate;

    @property (nonatomic, strong) NSNumberFormatter *numberFormatterPercentage;

    @property (nonatomic, strong) MTRulerView *ruler;
    @property (nonatomic, strong) MADDesignerStatusLabel *statusLabelZoomScale;
    @property (nonatomic, strong) MADPromptManager *promptManager;

    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerWidth;
    @property (nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;

    @property (nonatomic, strong) MADToolboxViewController *viewControllerToolbox;
    @property (nonatomic, strong) MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings;

    @property (nonatomic, strong) UINavigationController *navigationControllerToolbox;
    @property (nonatomic, strong) UINavigationController *navigationControllerSectionLayoutSettings;

    @property (nonatomic, assign) NSInteger lastSelectedSectionControlPanel;

    @property (nonatomic, strong) UIPopoverPresentationController *popoverToolbox;
    @property (nonatomic, strong) UIPopoverPresentationController *popoverObjectSelector;

    @property (nonatomic, strong) UIPopoverController *popoverControllerObjectSelector;

    @property (nonatomic, assign) bool editAggregate;
    @property (nonatomic, assign) bool toolboxVisible;
    @property (nonatomic, assign) bool sectionSettingsVisible;
    @property (nonatomic, assign) bool insetsSetup;
    @property (nonatomic, assign) bool shownAndHidden;
    @property (nonatomic, assign) bool lastMenuItemSelectRequiresElementView;

    @property (nonatomic, copy) NSManagedObjectID *objectIdEditDynamicLabel;
    @property (nonatomic, copy) NSManagedObjectID *objectIdEditBarcode;     //Never set a value... never used????
    @property (nonatomic, copy) NSManagedObjectID *objectIdEditImage;
    @property (nonatomic, copy) NSManagedObjectID *objectIdJustDisplayed;
    @property (nonatomic, copy) NSManagedObjectID *barcodeToEditObjectID;
    @property (nonatomic, copy) NSManagedObjectID *aggregateToEditObjectID;

    @property (nonatomic, strong) RptqDocumentObjectAggregate *aggregateToEdit;

    @property (nonatomic, assign) CGFloat zoomScaleRestore;
    @property (nonatomic, assign) CGRect boundsOnDisappear;

    @property (nonatomic, weak) UIGestureRecognizer *strayTouchGesture;
    @property (nonatomic, weak) UILabel *lastSelectedLabel;

@end

@implementation MADDesignerViewController

@synthesize document = _document;

#pragma mark - Static Helpers

+ (NSString *)MADDesigner {
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
}

#pragma mark - NSObject

- (void)dealloc { }

+ (instancetype)newDesignerViewController {
    UIStoryboard *storyboard = [MADStoryboard newStoryboardDesigner];
    id controller = [storyboard instantiateViewControllerWithIdentifier:MADDesignerStoryboardID];
    return controller;
}

#pragma mark - Unwind Segue

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action {
    
    if ([action.identifier isEqualToString:MTSegueNewDocumentObjectStaticLabelSaveIdentifer]) {
        [self saveStaticLabel:action.sourceViewController];
        
    } else if ([action.identifier isEqualToString:MTSegueChooseWhitespaceSaveIdentifer]) {
        [self saveWhiteSpace];
        
    } else if ([action.identifier isEqualToString:MTIdentifierSegueEditFieldExit]) {
        [self tableViewControllerChooseFieldDidFinish: action.sourceViewController
                                            withField: [action.sourceViewController queryField]];
        
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

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        self.numberFormatterPercentage = numberFormatter;
        
        MADMutableSetElementViews *visibleElementViews;
        visibleElementViews = [[MADMutableSetElementViews alloc] init];
        self.visibleElementViews = visibleElementViews;

        MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
        self.ruler = viewRuler;
        
        MADMutableMapNumbersByNumber *borderAppliedToView;
        borderAppliedToView = [[MADMutableMapNumbersByNumber alloc] init];
        self.borderAppliedToView = borderAppliedToView;
        
        MADDesignerStatusLabel *detailDisplay;
        detailDisplay = [[MADDesignerStatusLabel alloc] initWithFrame: CGRectZero];
        self.statusLabelZoomScale = detailDisplay;
        
    }
    return self;
}

#pragma mark - UIStateRestore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark - UITraitCollection

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

#pragma mark - UIViewController

- (NSString *)title { return [MADDesignerViewController MADDesigner]; }

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADocument *document = self.document;
    NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    
    self.scroller.scrollsToTop = YES;
    self.scroller.scrollEnabled = YES;
    self.scroller.userInteractionEnabled = YES;
    self.scroller.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    self.scroller.maximumZoomScale = 4.0000f;
    self.scroller.minimumZoomScale = 0.3000f;
    self.scroller.bouncesZoom = NO;
    
    self.hidesStatusBar = false;
    
    MADToolboxTransitioningDelegate *transitioningDelegate;
    transitioningDelegate = [[MADToolboxTransitioningDelegate alloc] init];
    transitioningDelegate.popoverPresentationControllerDelegate = self;
    transitioningDelegate.passthroughContainer = self.scroller;

    MADToolboxTransitioningDelegate *settingsTransitioningDelegate;
    settingsTransitioningDelegate = [[MADToolboxTransitioningDelegate alloc] init];
    settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;

    UINavigationController *navigationControllerToolbox;
    navigationControllerToolbox = [UINavigationController navigationControllerToolbox];
    navigationControllerToolbox.transitioningDelegate = transitioningDelegate;
    navigationControllerToolbox.modalPresentationStyle = UIModalPresentationCustom;
    navigationControllerToolbox.preferredContentSize = sizePopoverDefault();

    MADToolboxViewController *viewControllerToolbox;
    viewControllerToolbox = (MADToolboxViewController *)navigationControllerToolbox.topViewController;
    viewControllerToolbox.clearsBackground = [self padLike];
    viewControllerToolbox.document = document;
    viewControllerToolbox.selectedObjectIds = self.selectedObjectIds;
    self.viewControllerToolbox = viewControllerToolbox;
    
    self.navigationControllerToolbox = navigationControllerToolbox;
    self.toolboxTransitioningDelegate = transitioningDelegate;
    
    MADPromptManager *promptManager;
    NSString *lastPathComponent = document.fileURL.lastPathComponent.copy;
    promptManager = [[MADPromptManager alloc] initWithDefaultPrompt:lastPathComponent];
    self.promptManager = promptManager;
    
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:NO];
        [self displayPrompt];
        [UIView setAnimationsEnabled:YES];
    }
    
    self.statusLabelZoomScale.frame = [self detailDisplayFrame];
    
    self.boundsOnDisappear = CGRectZero;
    self.zoomScaleRestore = -1.0000f;
    self.shownAndHidden = false;
    self.editAggregate = false;
        
    self.insetsSetup = false;
    self.toolboxVisible = false;
    self.sectionSettingsVisible = false;
    
    [self contentViewRemoveAllConstraints];
    [self scrollerRemoveAllConstraints];
    
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
    
    NSLayoutConstraint *constraintContentLeft, *constraintContentRight, *viewScrollerTop,
                       *constraintContentTop, *constraintScrollerBottom, *constraintWidth;

    constraintContentLeft = [NSLayoutConstraint newLayoutConstraintView: self.view
                                                          containerLeft: self.scroller.container];
    
    constraintContentRight = [NSLayoutConstraint newLayoutConstraintView: self.view
                                                          containerRight: self.scroller.container];
    
    constraintContentTop = [NSLayoutConstraint newLayoutConstraintView: self.scroller
                                                          containerTop: self.scroller.container];
    constraintScrollerBottom = [NSLayoutConstraint newLayoutConstraintScroller: self.scroller
                                                                        bottom: self.bottomLayoutGuide];
    constraintWidth = [NSLayoutConstraint newLayoutConstraintContent: self.scroller.container
                                                               width: self.view.frame.size.width / self.scroller.zoomScale];
    
    constraintContentLeft.priority = 999;
    constraintContentRight.priority = 999;

    self.layoutConstraintContainerWidth = constraintWidth;
    
    
    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings;
    viewControllerSectionLayoutSettings = [MTReportDesignerSectionLayoutSettingsViewController toolboxSettings];
    viewControllerSectionLayoutSettings.delegate = self;
    
    self.viewControllerSectionLayoutSettings = viewControllerSectionLayoutSettings;
    
    UINavigationController *navigationController;
    navigationController = [[UINavigationController alloc] initWithRootViewController: self.viewControllerSectionLayoutSettings];
    navigationController.transitioningDelegate = settingsTransitioningDelegate;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    
    self.navigationControllerSectionLayoutSettings = navigationController;
    self.navigationControllerSectionLayoutSettings.preferredContentSize =  CGSizeMake(MADDefaultsPopooverWidth, 100.0000f);
    
    self.settingsTransitioningDelegate = settingsTransitioningDelegate;
    
    viewScrollerTop = [NSLayoutConstraint newLayoutConstraintViewScrollerTop: self.scroller
                                                                        view: self.topLayoutGuide];

    MADMutableSetManagedObjectIDs *selectedObjectIds;
    selectedObjectIds = [[MADMutableSetManagedObjectIDs alloc] init];
    self.selectedObjectIds = selectedObjectIds;
    
    NSArray *constraints;
    constraints = [[NSArray alloc] initWithObjects: constraintContentLeft,
                                                    constraintContentRight,
                                                    constraintContentTop,
                                                    constraintScrollerBottom,
                                                    constraintWidth,
                                                    viewScrollerTop, nil];
    [self.view addConstraints:constraints];
    
    self.scroller.container.backgroundColor =   [UIColor clearColor];
    self.scroller.backgroundColor =             [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    [self addObservers];
    
    MADBackgroundScrollView __unsafe_unretained *scroller = _scroller;
    MADTabBarController * __unsafe_unretained tabBarController = self.tabBarController;

    _lastMenuItemSelectRequiresElementView = false;
    _zoomScaleRestore = scroller.zoomScale;
    [scroller setZoomScale: 1.0000f animated: NO];
    
    RptqDocumentSectionEnumerator *sectionEnumerator;
    sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
    
    NSInteger sectionCounter = 0;
    NSUInteger numberOfSections = sectionEnumerator.count;
    
    [scroller.container addSubview:self.ruler];
    
    [self.view addSubview:self.statusLabelZoomScale];
    [self updateDisplayDetailZoomValue];
    
    MADLayoutConstraints *rulerConstraints, *rulerSideConstraints;
    rulerConstraints = [NSLayoutConstraint constraintForRuler: self.ruler
                                                     designer: scroller.container
                                                    marginTop: MTReportDesignerBorderPaddingVertical
                                                        heigh: MTReportDesignerRulerHeight];
    
    rulerSideConstraints = [NSLayoutConstraint constraintForRuler: self.ruler
                                                         designer: scroller.container
                                                       sideMargin: MTReportDesignerBorderPaddingSides];
    
    MADMutableManagedObjectIDs *reportSectionKeyTracker;
    
    MADMutableLayoutConstraints *scrollerLayoutConstraints,
                                *viewDidAppearDesignerContentViewConstraints,
                                *layoutConstraintsSectionsSidesBorder,
                                *layoutConstraintSectionLabelHeightContainer,
                                *layoutConstraintsSectionsVerticalBuffer;
    
    MADMutableSectionViews *sectionViewsArray;
    NSMutableDictionary <__kindof NSManagedObjectID *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;

    reportSectionKeyTracker = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    scrollerLayoutConstraints = [[MADMutableLayoutConstraints alloc] initWithCapacity:numberOfSections * 2 + 6];
    viewDidAppearDesignerContentViewConstraints = [[MADMutableLayoutConstraints alloc] initWithCapacity:numberOfSections * 5];
    layoutConstraintsSectionsSidesBorder = [[MADMutableLayoutConstraints alloc] initWithCapacity:numberOfSections * 2 + 2];
    layoutConstraintSectionLabelHeightContainer = [[MADMutableLayoutConstraints alloc] initWithCapacity:numberOfSections];
    layoutConstraintsSectionsVerticalBuffer = [[MADMutableLayoutConstraints alloc] initWithCapacity:numberOfSections];
    
    sectionViewsArray = [[MADMutableSectionViews alloc] initWithCapacity:numberOfSections];
    
    layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    
    MADMutableMapSectionViews *sectionViewsDictionary;
    MADMutableMapSectionLabels *sectionControlViewsDictionary;

    sectionViewsDictionary          = [[MADMutableMapSectionViews alloc] initWithCapacity:numberOfSections];
    sectionControlViewsDictionary   = [[MADMutableMapSectionLabels alloc] initWithCapacity:numberOfSections];

    MADMutableSetSectionViews *passthroughContainers;
    passthroughContainers = [[MADMutableSetSectionViews alloc] initWithCapacity:numberOfSections];

    [layoutConstraintsSectionsSidesBorder addObjectsFromArray:rulerSideConstraints];
    
    [scrollerLayoutConstraints addObjectsFromArray:rulerConstraints];
    [scrollerLayoutConstraints addObjectsFromArray:rulerSideConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight +
                                                 MTReportDesignerBorderPaddingVertical;
    
    CGFloat borderWidthThin = [UIView borderWidthThin];
    NSLayoutConstraint *layoutConstraintViewTop,
                       *layoutConstraintView,
                       *layoutConstraintLabelRight,
                       *layoutConstraintLabelBottom,
                       *layoutConstraintLabel,
                       *layoutConstraintViewLeft,
                       *layoutConstraintViewRight;
    NSArray *collectionViewConstraints, *sectionViewLabelConstraints;

    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        @autoreleasepool {
            
            NSManagedObjectID *reportSectionKey;
            MADDesignerSectionView *sectionView;
            MADDesignerSectionLabel *sectionViewLabel;
            UIGestureRecognizer *tapGestureRecognizer;
            
            reportSectionKey = [reportSection copySectionKey];

            sectionHeights += (MTReportDesignerBufferPaddingVertical + reportSection.height.floatValue);
            
            sectionView = [MADDesignerViewController documentSectionView: reportSection
                                                                delegate: self];
            sectionView.delegate = self;
            sectionView.dataSource = self;
            sectionView.layer.borderWidth = borderWidthThin;
            sectionView.showsVerticalScrollIndicator = YES;
            
            ((MTReportDesignerSectionViewLayoutLiquid *)sectionView.collectionViewLayout).tag = sectionCounter;
            
            sectionViewLabel = [[MADDesignerSectionLabel alloc] initWithSection:reportSection];
            
            tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerSectionToggleWithTarget:self
                                                                                                    action:@selector(handleToggleSectionControlPanel:)
                                                                                                  delegate:self];
            
            [self.strayTouchGesture requireGestureRecognizerToFail:tapGestureRecognizer];
            [sectionViewLabel addGestureRecognizer: tapGestureRecognizer];
            
            sectionViewLabel.tag = sectionCounter;
            
            NSManagedObjectID *key;
            UIView *constraintItem;
            
            key = reportSectionKeyTracker.lastObject;
            constraintItem = sectionCounter == 0 ?
                                        self.ruler : sectionViewsDictionary[key];
            
            
            layoutConstraintViewTop = [NSLayoutConstraint newLayoutConstraintViewTop: constraintItem
                                                                          viewBottom: sectionView
                                                                             padding: MTReportDesignerBufferPaddingVertical];
            
            layoutConstraintView = [NSLayoutConstraint newLayoutConstraintView: sectionView
                                                                        height: reportSection.height.floatValue];
            
            layoutConstraintLabelRight = [NSLayoutConstraint newLayoutConstraintLabelRight: sectionViewLabel
                                                                                 container: sectionView
                                                                                   padding: MTReportDesignerSectionLabelPaddingRight];
            
            layoutConstraintLabelBottom = [NSLayoutConstraint newLayoutConstraintLabelBottom: sectionViewLabel
                                                                                   container: sectionView
                                                                                     padding: MTReportDesignerBufferPaddingVertical];
            layoutConstraintLabel = [NSLayoutConstraint newLayoutConstraintLabel: sectionViewLabel
                                                                        toHeight: MTReportDesignerSectionLabelHeight];

            layoutConstraintViewLeft = [NSLayoutConstraint newLayoutConstraintViewLeft:sectionView
                                                                               content:scroller.container
                                                                               padding:MTReportDesignerBorderPaddingSides];

            layoutConstraintViewRight = [NSLayoutConstraint newLayoutConstraintViewRight:sectionView
                                                                                 content:scroller.container
                                                                                 padding:MTReportDesignerBorderPaddingSides];

            collectionViewConstraints = [[NSArray alloc] initWithObjects: layoutConstraintViewLeft,
                                                                          layoutConstraintViewRight, nil];

            sectionViewLabelConstraints = [[NSArray alloc] initWithObjects: layoutConstraintViewTop,
                                                                            layoutConstraintView,
                                                                            layoutConstraintLabelRight,
                                                                            layoutConstraintLabelBottom,
                                                                            layoutConstraintLabel, nil];

            [viewDidAppearDesignerContentViewConstraints addObjectsFromArray:sectionViewLabelConstraints];
            

            [layoutConstraintsSectionsVerticalBuffer addObject:layoutConstraintViewTop];
            [layoutConstraintSectionLabelHeightContainer addObject:layoutConstraintLabel];
            
            [layoutConstraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];

            [scrollerLayoutConstraints addObjectsFromArray:collectionViewConstraints];

            layoutConstraintsReportSectionHeight[sectionView.objectIdTag] = layoutConstraintView;
            
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
    }
    
    [reportSectionKeyTracker removeAllObjects];
    
    self.layoutConstraintsSectionsVerticalBuffer = layoutConstraintsSectionsVerticalBuffer;

    self.layoutConstraintsReportSectionHeight = layoutConstraintsReportSectionHeight;
    self.sectionViewsDictionary = sectionViewsDictionary;
    self.sectionControlViewsDictionary = sectionControlViewsDictionary;

    self.layoutConstraintsSectionsSidesBorder = layoutConstraintsSectionsSidesBorder;
    self.layoutConstraintSectionLabelHeightContainer = layoutConstraintSectionLabelHeightContainer;
    self.passthroughContainers = passthroughContainers;
    self.sectionViewsArray = sectionViewsArray;
    
    sectionHeights += MTReportDesignerBorderPaddingVertical;
    
    NSLayoutConstraint *layoutConstraintDesignerContentViewHeight = [NSLayoutConstraint newLayoutConstraintView: scroller.container
                                                                                                         height: sectionHeights];

    [scrollerLayoutConstraints addObject:layoutConstraintDesignerContentViewHeight];

    self.layoutConstraintDesignerContentViewHeight = layoutConstraintDesignerContentViewHeight;
    
    
    NSLayoutConstraint *layoutConstraintContentToScollerBottom = [NSLayoutConstraint newLayoutConstraintView: scroller.container
                                                                                             containerBottom: scroller];
    
    [scrollerLayoutConstraints addObject:layoutConstraintContentToScollerBottom];
    
    [tabBarController enableTabBarItems];
    
    [self.scroller addConstraints: scrollerLayoutConstraints];
    [self.scroller.container addConstraints: viewDidAppearDesignerContentViewConstraints];
    
    UIBarButtonItem *barButtonItemAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                      target:self
                                                                                      action:@selector(actionAdd:)];
    [tabBarController.navigationItem setRightBarButtonItem:barButtonItemAdd animated:NO];
    
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    self.viewDidAppearDesignerScrollViewConstraints = scrollerLayoutConstraints;

}

- (BOOL)prefersStatusBarHidden {
    return self.hidesStatusBar ||
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.insetsSetup == false) self.insetsSetup = true;
    
    [self setScrollersEnabled:YES];
    
    if (self.shownAndHidden && self.zoomScaleRestore > 1.0001) {
        [self.scroller setZoomScale:self.zoomScaleRestore animated:NO];
        [self handledScrollViewDidEndZooming: nil withView: nil atScale: self.scroller.zoomScale];
        [self.scroller scrollRectToVisible:self.boundsOnDisappear animated:NO];
    }
    [self.scroller flashScrollIndicators];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.boundsOnDisappear = self.scroller.bounds;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeObservers];
    
    NSArray *subviews = self.scroller.container.subviews;
    for (id view in subviews) {
        if ([view isKindOfClass:[MADDesignerSectionView class]]) {
            [((MADDesignerSectionView *)view).sectionLabel removeFromSuperview];
        }
        [view removeFromSuperview];
    }
    
    [self.scroller removeConstraints:self.viewDidAppearDesignerScrollViewConstraints];
    [self.scroller.container removeConstraints:self.viewDidAppearDesignerContentViewConstraints];
    
    [self.visibleElementViews removeAllObjects];
    [self.viewDidAppearDesignerContentViewConstraints removeAllObjects];
    [self.viewDidAppearDesignerScrollViewConstraints removeAllObjects];
    [self.layoutConstraintsSectionsSidesBorder removeAllObjects];
    [self.layoutConstraintsSectionsVerticalBuffer removeAllObjects];
    [self.layoutConstraintsReportSectionHeight removeAllObjects];
    
    self.shownAndHidden = true;
    [self.document saveContext];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UIEdgeInsets insets;
    
    // FIXME: This is not choosing the correct scroll inset...
    
    if (self.toolboxTransitioningDelegate.presentationController.presentedView.superview != nil &&
        self.presentedViewController.childViewControllers.count > 0 &&
        self.toolboxTransitioningDelegate.presentationController != nil &&
        ![self showOnSide]) {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                  self.toolboxTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height,
                                  CGSizeZero.width);
        
    } else if (self.settingsTransitioningDelegate.presentationController.presentedView.superview != nil &&
               self.presentedViewController.childViewControllers.count > 0 &&
               self.settingsTransitioningDelegate.presentationController != nil &&
               ![self showOnSide]) {
        
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
    
    self.layoutConstraintContainerWidth.constant = self.view.frame.size.width / self.scroller.zoomScale;
    
    CGFloat zoomscale = self.scroller.zoomScale;
    CGFloat borderPaddingSides = MTReportDesignerBorderPaddingSides / self.scroller.zoomScale;
    
    [self.layoutConstraintsSectionsSidesBorder enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = constraint.constant > 0 ? borderPaddingSides : -borderPaddingSides;
    }];
    
    [self.layoutConstraintsSectionsVerticalBuffer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = constraint.constant > 0 ? MTReportDesignerBufferPaddingVertical : -MTReportDesignerBufferPaddingVertical;
    }];
    
    [self.layoutConstraintSectionLabelHeightContainer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = MTReportDesignerSectionLabelHeight / zoomscale;
    }];
    
    self.layoutConstraintDesignerContentViewHeight.constant = [self designerContentViewSize].height;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
        [(segue.destinationViewController) setDocument: self.document];
    }
    
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
    [coordinator animateAlongsideTransition:transition completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self adjustContextOffsetForOpenPopover];
    }];

}

#pragma mark - UIAccessibility

- (BOOL)accessibilityPerformEscape {
    [self.delegate viewControllerDidFinish:nil];
    return YES;
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
    return direction == UIAccessibilityScrollDirectionUp || direction == UIAccessibilityScrollDirectionDown;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.view.frame = navigationController.view.frame;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
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

- (void)scrollViewDidEndZooming: (UIScrollView *)scrollView withView: (UIView *)view atScale: (CGFloat)scale {
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

- (void)handledScrollViewDidEndZooming:(UIScrollView *)scrollView withView: (UIView *)view atScale: (CGFloat)scale {
    if ([scrollView isEqual:self.scroller]) {
        
        CGFloat scaleWithScreen = scale * scrollView.traitCollection.displayScale;
        
        self.ruler.contentScaleFactor = scaleWithScreen;
        
        NSSet *elementViews = self.visibleElementViews;
        for (MADDesignerElementView *elementView in elementViews) {
            elementView.contentScaleFactor = scaleWithScreen;
        }
        UIFont *captionFont = [MADDesignerViewController captionFont];
        CGFloat pointsize = captionFont.pointSize;
        
        NSArray <__kindof MADDesignerSectionLabel *> *sectionControlViewsArray = self.sectionControlViewsDictionary.allValues;
        [sectionControlViewsArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                   usingBlock:^(__kindof MADDesignerSectionLabel * _Nonnull controlView,
                                                                NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                controlView.font = [captionFont fontWithSize:pointsize / scale];
                controlView.contentScaleFactor = scaleWithScreen;
                [controlView setNeedsDisplay];
            }];
        }];
        
        for (UICollectionView *section in self.sectionViewsDictionary.objectEnumerator) {
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

#pragma mark - UIDocumentStateChangedNotification

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

#pragma mark - MTReportDesignerSectionLayoutSettingsDelegate

- (void)sectionLayoutSettingsDidFinish:(MTReportDesignerSectionLayoutSettingsViewController *)controller {
    [self hideToolbox];
}

- (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings newPageAfter:(bool)newPageAfter {
    NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    [private performBlock:^{
        RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query =  database.hasQueries.anyObject;
        
        RptqDocumentSection *section = [query documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber];
        [section setProducesFormFeed: newPageAfter];
        
        NSError * __autoreleasing *error = NULL;
        [private save:error];
        
    }];
    
}

- (void)sectionLayoutDidUpdateVisibility:(bool)isVisible {
    
    NSInteger selectedSectionNumber = self.lastSelectedSectionControlPanel;
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlock:^{
    
        RptqDocument *document = [RptqDocument newDocumentReadFromManagedObjectContext: private];
        RptqDatabase *database = document.hasDatabaseSchemas.anyObject;
        RptqQuery *query =  database.hasQueries.anyObject;
        
        RptqDocumentSection *section = [query documentSectionForSelectedIndex: (NSUInteger)selectedSectionNumber];
        NSNumber * visibility = [[NSNumber alloc] initWithBool:isVisible];
        section.visibility = visibility;
        
        id key = [section copySectionKey];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            MADDesignerSectionView *documentSectionView = self.sectionViewsDictionary[key];
            documentSectionView.visible = isVisible;
        }];

        NSError * __autoreleasing *error = NULL;
        [private save:error];

    }];
}

//FIXME: Unused... used to allow user to change the height of the sections.
- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
    RptqQuery *query = [database.hasQueries anyObject];
    RptqDocumentSection *documentSection = [query documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel];
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    CGSize collectionViewContentSize = [documentSectionView.collectionViewLayout collectionViewContentSize];
    [documentSection setInterfaceHeight: collectionViewContentSize.height];
 
    [documentSection.managedObjectContext save:nil];
    
    id key = [documentSection copySectionKey];
    UICollectionView *collectionView = self.sectionViewsDictionary[key];
    [collectionView.backgroundView setNeedsDisplay];
    [documentSectionView.collectionViewLayout invalidateLayout];
    [documentSection setInterfaceHeight: collectionViewContentSize.height];
    [documentSection.managedObjectContext save:nil];
    
    [self.view setNeedsUpdateConstraints];
    
}

// FIXME: Unused... Used for multiple rows in the document section... currently unused
- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MADocument *doc = self.document;
    RptqDatabase *database = doc.activeDocumentModel.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    RptqDocumentSection *documentSection = [query documentSectionForSelectedIndex: (NSUInteger)self.lastSelectedSectionControlPanel];
    
    BOOL insertNewSection = numberOfRows > documentSection.numberOfRows.unsignedIntegerValue;
    BOOL deleteLastSection = numberOfRows < documentSection.numberOfRows.unsignedIntegerValue;
    
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    
    if (documentSection.numberOfRows.unsignedIntegerValue == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > documentSection.numberOfRows.unsignedIntegerValue) {
        
        //Add row
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: doc.managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:documentSection.hasRows.array];
        newRowToAppend.inSection = documentSection;
        [hasRows addObject:newRowToAppend];
        documentSection.hasRows = hasRows;
        
    } else if (numberOfRows < documentSection.numberOfRows.unsignedIntegerValue) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = documentSection.hasRows.lastObject;
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:documentSection.hasRows.array];
        [hasRows.lastObject setInSection:nil];
        [hasRows removeObjectAtIndex:hasRows.count - 1];
        documentSection.hasRows = hasRows;
        [rowToDelete setInSection:nil];
        
    }
    
    NSNumber *numberOfRowsObject = [[NSNumber alloc] initWithUnsignedInteger:numberOfRows];
    documentSection.numberOfRows = numberOfRowsObject;
    
    id sectionKey = [documentSection copySectionKey];
    UICollectionView *collectionView = self.sectionViewsDictionary[sectionKey];
    MTReportDesignerSectionBackgroundView *backgroundView = (MTReportDesignerSectionBackgroundView *)collectionView.backgroundView;
    [backgroundView setNumberOfRowsInBackground:numberOfRows];
    
    NSError *error = nil;
    [doc.managedObjectContext save:&error];
    [doc saveToURL: doc.fileURL forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
               
        if (insertNewSection) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:numberOfRows - 1];
            [documentSectionView insertSections:indexSet];
        } else if (deleteLastSection) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:numberOfRows];
            [documentSectionView deleteSections:indexSet];
        }

    }];
    
}

#pragma mark - NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    
    for (id updatedObject in updatedObjects) {
        
        if ([updatedObject isKindOfClass:[RptqDocumentObject class]]) {
            RptqDocumentObject *documentObject = updatedObject;
            NSDictionary *changes = [documentObject changedValues];
            
            MADocument *doc = self.document;
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
                    
                    MADDesignerSectionView *section = [self getSectionViewForDocumentSection: documentObject.inSectionRow.inSection];
                    MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[section.objectIdTag];
                    MADSectionLayoutAttributes *attributes = layoutManager.items[documentObject.objectID];
                    if (attributes != nil) {
                        attributes.frame = [documentObject elementViewFrameDesigner];
                        self.objectIdJustDisplayed = documentObject.objectID.copy;
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

#pragma mark - NSManagedObjectContextDidSaveNotification

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    NSSet *managedObjectsUpdated = notification.userInfo[NSUpdatedObjectsKey];

    NSManagedObject *managedObject;
    for (managedObject in managedObjectsUpdated) {
        MADDesignerElementView *elementView = [self elementViewForManagedObject:managedObject];
        [elementView updateForManagedObjectContent:managedObject.managedObjectContext];
    }
    
}

#pragma mark - Menu Notifications

- (void)willHideMenuNotification:(NSNotification *)notification { }

- (void)didHideMenuNotification:(NSNotification *)notification {
    if (self.lastMenuItemSelectRequiresElementView == false) {
        MADDesignerElementView *lastElementViewToShowMenu = self.lastElementViewToShowMenu;
        if (lastElementViewToShowMenu) {
            [self deselectElementView: lastElementViewToShowMenu animated: YES];
            [self.selectedObjectIds removeObject: lastElementViewToShowMenu.objectIdTag];
            (self.viewControllerToolbox).selectedObjectIds = self.selectedObjectIds;
        }
        self.lastElementViewToShowMenu = nil;
    }
    self.lastMenuItemSelectRequiresElementView = false;
}
- (void)didShowMenuNotification:(NSNotification *)notification { }
- (void)willShowMenuNotification:(NSNotification *)notification { }

- (BOOL)padLike {
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
           self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

#pragma mark - UIImagePickerControllerDelegate

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
        self.hidesStatusBar = false;
        
        MADDesignerViewController * __weak reportDesigner = self;
        [self dismissViewControllerAnimated:YES completion:^{
        
            NSNumber *type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeImage];
            NSDictionary *defination;
            defination = [[NSDictionary alloc] initWithObjectsAndKeys:
                            type,           MTDocumentObjectDefinationType,
                            selectedImage,  MTDocumentObjectDefinationObject, nil];
            [reportDesigner insertDocumentObjectWithDefination: defination];
            
        }];
    }
    
    [self setDisplayActive];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.hidesStatusBar = false;
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self setDisplayActive];
}

#pragma mark - UIPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationOverFullScreen;
}

- (UIViewController *)presentationController:(UIPresentationController *)controller
                        viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
    
    UIViewController *result;
    Class navigationClass = [UINavigationController class];
    id presented = controller.presentedViewController;
    if (style != UIModalPresentationPopover && [presented isKindOfClass:navigationClass] == NO) {
        
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

#pragma mark - UIPopoverPresentationControllerDelegate

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

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

#pragma mark -
#pragma mark MTCollectionViewCellElement Delegate

- (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell {
    RptqDocumentObject *documentObject;
    documentObject = [self.document.managedObjectContext objectWithID:cell.objectIdTag];
    return documentObject.type.shortValue;
}

- (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    id elementView;
    
    [self deselectAllElementsAnimated:YES];
    _lastMenuItemSelectRequiresElementView = true;
    
    elementView = [self viewForObjectID:cell.objectIdTag];
    [self selectElementView: elementView];
    
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    
    NSManagedObjectContext *private;
    NSManagedObjectID *elementViewId;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    elementViewId = cell.objectIdTag.copy;
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlock:^{
    
        RptqDocumentObject *documentObject;
        RptqDocumentSection *documentObjectInSection;
        MADDesignerSectionView *designerSectionView;
        NSManagedObjectID *designerSectionViewTag;
        
        documentObject = [private objectWithID:elementViewId];
        documentObjectInSection = documentObject.inSectionRow.inSection;
        designerSectionView = [self getSectionViewForDocumentSection:documentObjectInSection];
        designerSectionView = designerSectionView.objectIdTag.copy;
        documentObjectInSection = [RptqDocumentSection documentSectionForObjectID: designerSectionViewTag
                                                           inManagedObjectContext: private];
        BOOL found = NO;
        
        NSOrderedSet *documentSectionHasRows = documentObjectInSection.hasRows;
        for (RptqDocumentSectionRows *row in documentSectionHasRows) {
            
            NSMutableOrderedSet *hasObjects = row.hasObjects.mutableCopy;

            NSUInteger i = 0;
            
            for (RptqDocumentObject *object in hasObjects) {
                if ([object.objectID isEqual: elementViewId]) {
                    found = YES;
                    break;
                }
                i++;
            }
            
            if (found) {
                
                RptqDocumentObject *objectToEdit = hasObjects[i];
                
                switch (objectToEdit.type.shortValue) {
                        
                    case MTDocumentObjectTypeAggregate: {
                        NSManagedObjectID *objectID  = objectToEdit.objectID.copy;
                        [self editDocumentObjectAggregateWithID: objectID];
                        break;
                    }
                    
                    case MTDocumentObjectTypeBarcode: {
                        RptqDocumentObjectBarcode *barcode = objectToEdit.isBarcode;
                        NSManagedObjectID *objectID  = objectToEdit.objectID.copy,
                                          *barcodeID = barcode.objectID.copy;
                        [self editDocumentObjectBarcodeWithID: objectID
                                                 andBarcodeID: barcodeID];
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

#pragma mark MTCollectionViewCellElement Helpers

- (void)editDocumentObjectAggregateWithID:(NSManagedObjectID *)objectID {
    
    self.aggregateToEditObjectID = objectID.copy;
    self.editAggregate = true;

    MADDesignerViewController * __weak weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;

        UIView *viewToEdit = [strongself viewForObjectID: objectID];
        UINavigationController *navigationController = [UINavigationController aggregateAdd];
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController;
        aggregateViewController = navigationController.viewControllers.firstObject;
        aggregateViewController.document = strongself.document;
        aggregateViewController.aggregateDelegate = strongself;
        [aggregateViewController setAggregateObjectToEdit:strongself.aggregateToEdit];
        
        UIBarButtonItem *dismiss;
        dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                target: strongself
                                                                action: @selector(actionCancel:)];
        
        [aggregateViewController.navigationItem setRightBarButtonItem:dismiss animated:NO];
        [aggregateViewController.navigationItem setLeftBarButtonItem:nil animated:NO];
        
        navigationController.modalPresentationStyle = UIModalPresentationPopover;
        navigationController.preferredContentSize = sizePopoverFonts();
        
        UIPopoverPresentationController *popoverController;
        popoverController = navigationController.popoverPresentationController;
        popoverController.delegate = strongself;
        popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
                                                        toView: strongself.scroller.container];
        
        popoverController.sourceView = strongself.scroller.container;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [strongself presentViewController:navigationController animated:YES completion:nil];
        [strongself setDisplayInactive];

    }];
    
}

- (void)editDocumentObjectBarcodeWithID:(NSManagedObjectID *)objectID
                           andBarcodeID:(NSManagedObjectID *)barcodeID {
    
    self.barcodeToEditObjectID = barcodeID.copy;
    
    MADDesignerViewController * __weak weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;
        
        UIView *viewToEdit = [strongself viewForObjectID:objectID];

        MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode main];
        barcodeViewController.document = strongself.document;
        barcodeViewController.delegate = strongself;
        barcodeViewController.preferredContentSize = sizePopoverFonts();
        barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
        barcodeViewController.bartcodeToEditObjectID = barcodeID;

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

- (void)editDocumentObjectBarcode:(RptqDocumentObject *)object {
    
    UIView *viewToEdit = [self viewForObjectID:object.objectID];
    
    MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode main];
    barcodeViewController.document = self.document;
    barcodeViewController.delegate = self;
    
    barcodeViewController.preferredContentSize = sizePopoverFonts();
    barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds toView: self.scroller.container];
    popoverController.sourceView = self.scroller.container;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController:barcodeViewController animated:YES completion:nil];
    [self setDisplayInactive];
}

- (void)editDocumentObjectImage:(RptqDocumentObject *)object {
    self.objectIdEditImage = object.objectID.copy;
}

- (void)editDocumentObjectLabelDynamic:(RptqDocumentObject *)object {
    
    self.objectIdEditDynamicLabel = object.objectID.copy;
    
    UIView *viewToEdit = [self viewForObjectID:object.objectID];
    
    MTQueryBuilderChooseFieldViewController *chooseFieldViewController = [MTQueryBuilderChooseFieldViewController main];
    chooseFieldViewController.document = self.document;
    chooseFieldViewController.delegate = self;
    
    chooseFieldViewController.modalPresentationStyle = UIModalPresentationPopover;
    chooseFieldViewController.preferredContentSize = sizePopoverFonts();
    
    UIPopoverPresentationController *popoverController = chooseFieldViewController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds
                                                    toView: self.scroller.container];
    popoverController.sourceView = self.scroller.container;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController:chooseFieldViewController animated:YES completion:nil];
    [self setDisplayInactive];
}

- (void)editDocumentObjectLabelStatic:(RptqDocumentObject *)object {
    
    UIAlertController *alert = [UIAlertController newAlertControllerEditLabel:^(UITextField *textField) {
    
        textField.text = object.isLabel.text;
        textField.clearButtonMode = UITextFieldViewModeAlways;
    
    } completion:^(UIAlertAction *action, NSString *text) {
    
        NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:object.objectID];
        documentObject.isLabel.text = text;
        [managedObjectContext save:nil];
    
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark -
#pragma mark - MTViewControllerBarcodeDelegate

- (void)didUpdateBarcodeWithObjectID:(NSManagedObjectID *)barcodeObjectID
                       barcodeObject:(MTBarcode *)barcode
                        withFieldOne:(RptqQueryField *)fieldOne
                         andFieldTwo:(RptqQueryField *)fieldTwo {
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    NSManagedObjectID *barcodeToEditObjectID = barcodeObjectID.copy;
    [private performBlock:^{
    
        RptqDocumentObjectBarcode *barcodeToEdit = [private objectWithID:barcodeToEditObjectID];
        [barcodeToEdit updateWithBarcode: barcode fieldOne: fieldOne fieldTwo: fieldTwo];

        NSError * __autoreleasing *error = NULL;
        [private save:error];

    }];
    
}

#pragma mark -
#pragma mark - MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType: (MTAggregateFunctionType)functionType
                                inputType: (MTAggregateFunctionInputType)inputType
                              inputObject: (NSManagedObject *)inputObject
                                groupType: (MTAggregateGroupByType)groupType
                              groupNumber: (NSNumber *)groupNumber {
    
    [self.aggregateToEdit updateAggregateFunctionWithFunctionType: functionType
                                                        inputType: MTAggregateFunctionInputTypeField
                                                        groupType: groupType
                                                  aggregateObject: (RptqQueryField *)inputObject
                                                      groupNumber: (NSUInteger)labs(groupNumber.longValue)];
}

#pragma mark -
#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)field {

    RptqDocumentObject *documentObject = [field.managedObjectContext objectWithID:self.objectIdEditDynamicLabel];
    documentObject.isLabelDataField.referencesQueryField = field;
    [field.managedObjectContext save:nil];
    
}

#pragma mark -
#pragma mark MTReportDesignerSectionViewLayoutLiquidDelegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView: (MADDesignerSectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADocument *document = self.document;
    MADSectionLayoutManager *layoutManager;
    layoutManager = document.sectionLayoutManagers[collectionView.objectIdTag];
    
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
    

    RptqDocumentObject *documentObject;
    documentObject = [document.managedObjectContext objectWithID:attributes.objectID];
    CGFloat contextScale = self.scroller.zoomScale * self.scroller.traitCollection.displayScale;
    NSString *resuseId = [MTCollectionViewCellElement reuseIdentifier];
    
    MTCollectionViewCellElement *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId forIndexPath:indexPath];
    cell.delegate = self;
    
    CGSize documentObjectSize = [documentObject size];
    CGRect cellFrame = CGRectMake(CGPointZero.x, CGPointZero.y,
                                  documentObjectSize.width, documentObjectSize.height);
    
    switch (documentObject.getType) {
        case MTDocumentObjectTypeFormula:
        case MTDocumentObjectTypeLabelStatic:
        case MTDocumentObjectTypeLabelDynamic:
        case MTDocumentObjectTypeAggregate:
        default: {
            
            NSArray *subviews = cell.contentView.subviews;
            for (id subview in subviews) {
                [subview removeFromSuperview];
            }
            
            cell.backgroundColor = [UIColor clearColor];
            cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
            
            MADDesignerElementView *elementView = [self elementViewForManagedObject:documentObject];
            
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
            cell.objectIdTag = documentObject.objectID;
            
            cell.userInteractionEnabled = YES;
            
            if ([self.selectedObjectIds containsObject:documentObject.objectID]) {
                [self applyBorderToView:elementView];
            }
            
            [cell addElementView:elementView];
            
            if (self.objectIdJustDisplayed != nil) {
                
                if ([self.objectIdJustDisplayed isEqual: documentObject.objectID]) {
                    [elementView flash:^(BOOL finished) { if (finished) self.objectIdJustDisplayed = nil; }];
                    
                }
                
            }
            
            MTCollectionViewCellElement * __weak weakcell = cell;
            MADDesignerElementView * __weak weakElementView = elementView;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
                MTCollectionViewCellElement * strongcell = weakcell;
                MADDesignerElementView *strongElementView = weakElementView;
                
                if (strongcell) {
                    MTCollectionViewCellElement * __weak weakcell1 = strongcell;
                    MADDesignerElementView * __weak weakElementView1 = strongElementView;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                    
                        MTCollectionViewCellElement *strongcell1 = weakcell1;
                        if (strongcell1) {
                            strongcell1.contentScaleFactor = contextScale;
                            (strongcell1.contentView).contentScaleFactor = contextScale;
                        }
                        
                        weakElementView1.contentScaleFactor = contextScale;
                        
                    });

                }
            });
            break;
        }
    }
    return cell;
}

- (NSInteger)collectionView: (MADDesignerSectionView *)collectionView numberOfItemsInSection: (NSInteger)section {
    MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
    return (NSInteger)layoutManager.items.count;
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView: (UICollectionView *)collectionView willDisplayCell: (MADManagedObjectCollectionViewCell *)cell forItemAtIndexPath: (NSIndexPath *)indexPath {
    
    id elementView = nil;

    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[MADDesignerElementView class]]) {
            elementView = view;
            break;
        }
    }
    
    NSAssert(elementView != nil, @"We need an element view people.");
    [self.visibleElementViews addObject:elementView];
    [self adjustPassthroughViews];
    
}

- (void)collectionView: (UICollectionView *)collectionView didEndDisplayingCell: (MADManagedObjectCollectionViewCell *)cell forItemAtIndexPath: (NSIndexPath *)indexPath {
    
    NSSet <__kindof MADDesignerElementView *> *elementViewSet;
    
    elementViewSet = [self.visibleElementViews objectsPassingTest:^BOOL(__kindof MADDesignerElementView * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.objectIdTag isEqual:cell.objectIdTag]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    
    [self.visibleElementViews minusSet:elementViewSet];
    [self adjustPassthroughViews];
    
}

- (void)collectionView:(UICollectionView *)collectionView
    didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
                     forElementOfKind:(NSString *)elementKind
                          atIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:)) {
        result = YES;
    }
    return result;
}

- (void)collectionView: (MADDesignerSectionView *)collectionView performAction: (SEL)action forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    
    NSInteger row = indexPath.row;
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: collectionView.objectIdTag inManagedObjectContext: self.document.managedObjectContext];
    NSOrderedSet *objects = [documentSection.hasRows[(NSUInteger)indexPath.section] hasObjects];
    
    if ((NSInteger)objects.count > row) {
        RptqDocumentObject *documentObject = objects[(NSUInteger)row];
        
        if (action == @selector(delete:)) {
            [self delete:documentObject];
        } else if (action == @selector(edit:)) {
            [self edit:documentObject];
        }
        
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self dismissAllPopovers];
    [self dismissSectionPresentationIfOpen];
    [self dismissToolboxPresentationIfOpen];
    [self deselectAllElementsAnimated:NO];
    
    MADDesignerElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [self applyBorderToView:elementView];
    self.lastElementViewToShowMenu = elementView;
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark - MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    [self setDisplayActive];
    self.hidesStatusBar = false;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - MADDesignerElementPickerDelegate

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
    [self setDisplayActive];
    NSNumber *objTypeKey;
    NSDictionary *parameters;
    objTypeKey = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeLabelDynamic];
    parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                            objTypeKey,     MTDocumentObjectDefinationType,
                            field.objectID, MTDocumentObjectDefinationObject, nil];
    [self insertDocumentObjectWithDefination: parameters];
    self.hidesStatusBar = false;
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
    self.hidesStatusBar = false;
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
    --------------------------------------------------------------------------------------------------------------------------------------
    Pan Backgournd              -   Scroll designer -   Vertical        - YES
    Pan Section View            -   Scroll section  -   Horizontal      - YES
    Pan Element View            -   Move element                        -  NO
 
    Single Tap Background       -   Tap away                            -  NO                       (...everything else)
    Single Tap Section View     -   Tap away                            -  NO                       (...everything else)
    Single Tap Element View     -   Select element, deselect sections   -  NO                       (pan element view)
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
        return  NO;
    }
}

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch: (UITouch *)touch {
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

#pragma mark - Actions

- (void)edit:(id)sender { }

#pragma mark - MTReportDesignerSectionViewLayoutLiquidDelegate

- (void)collectionView: (MADDesignerSectionView *)collectionView
         prepareLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADocument *document = self.document;
    MADSectionLayoutManager *layoutManager;
    layoutManager = document.sectionLayoutManagers[collectionView.objectIdTag];
    NSManagedObjectContext *objectContext = document.managedObjectContext;
    RptqDocumentObject *documentObject;
    
    for (MADSectionLayoutAttributes *attributes in layoutManager.items.allValues) {

        documentObject = (RptqDocumentObject *)[objectContext objectWithID:attributes.objectID];

        NSNumber *n = [[NSNumber alloc] initWithFloat: attributes.frame.origin.x];
        documentObject.originx = n;

        n = [[NSNumber alloc] initWithFloat: attributes.frame.origin.y];
        documentObject.originy = n;

        //documentObject.sizewidth = @(attributes.frame.size.width);
        //documentObject.sizeheight = @(attributes.frame.size.height);

    }

    //[objectContext save:nil];
}

- (MADSectionLayoutAttributes *)collectionView: (MADDesignerSectionView *)collectionView
                                        layout: (UICollectionViewLayout *)collectionViewLayout
            layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADSectionLayoutManager *layoutManager;
    layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
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

- (NSUInteger)numberOfItemsInSection: (NSUInteger)section ofCollectionView: (MADDesignerSectionView *)collectionView {
    MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
    return layoutManager.items.count;
}

- (NSArray *)collectionView: (MADDesignerSectionView *)collectionView attributesForLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
    return layoutManager.items.allValues;
}

- (CGSize)collectionView: (MADDesignerSectionView *)collectionView sizeForLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
    return layoutManager.size;
}

#pragma mark - Gesture Recognizers
#pragma mark Gesture handlers

- (void)handlePinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    MADDesignerElementView *piece = ((MADDesignerElementView *)gestureRecognizer.view);
    RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:piece.objectIdTag];

    if (gestureRecognizer.numberOfTouches > 1) {
        NSNumber *length;
        CGPoint p1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
        CGPoint p2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
        MADCompassDirection direction = MADSpecificDirectionOfDegrees(CGAngleBetweenTwoPoints(p1, p2));
        struct MADResizeAspect resizeAspect = MADResizeTypeForDirection(direction);

        switch (resizeAspect.direction) {

            case horizontal:
                length = [[NSNumber alloc] initWithFloat:documentObject.sizewidth.floatValue *
                                                            gestureRecognizer.scale];
                documentObject.sizewidth = length;
                break;

            case vertical:
                length = [[NSNumber alloc] initWithFloat:documentObject.sizeheight.floatValue *
                                                            gestureRecognizer.scale];
                documentObject.sizeheight = length;
                break;
                
            default:
                length = [[NSNumber alloc] initWithFloat:documentObject.sizewidth.floatValue *
                                                            gestureRecognizer.scale];
                documentObject.sizewidth = length;
                length = [[NSNumber alloc] initWithFloat:documentObject.sizeheight.floatValue *
                                                            gestureRecognizer.scale];
                documentObject.sizeheight = length;
                break;
        
        }

    }
    gestureRecognizer.scale = 1.0000f;
    [documentObject.managedObjectContext save:nil];
    
}

- (void)handlePanPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateFailed:
            break;
            
        case UIGestureRecognizerStateBegan: {
            
            [self beginPanPiece:(MADManagedObjectView *)gestureRecognizer.view transition:^{
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
            [self hideToolbox];
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
            
            [self hideToolbox];
            
        } else {
            
            self.viewControllerToolbox.document = self.document;
            
            if (label.selected) {
                
                
                [label normalView];
                [self hideToolbox];
                
            } else {
                
                [self deselectAllElementsAnimated:YES];
                
                
                self.lastSelectedSectionControlPanel = label.tag;
                self.lastSelectedLabel = label;
                RptqDocumentSection *section = [self sectionForLabelTag:label.tag];
                MADDesignerSectionView *superView = [self getSectionViewForDocumentSection: section];
                superView.selected = YES;
                [label dimView];
                
                
                self.viewControllerSectionLayoutSettings.initalHeightValue = section.height.floatValue;
                self.viewControllerSectionLayoutSettings.initalVisibility = section.visibility.boolValue;
                self.viewControllerSectionLayoutSettings.initalFormFeedEnabled = section.producesFormFeed;
                self.viewControllerSectionLayoutSettings.initalNumberOfRows = section.numberOfRows.unsignedIntegerValue;
                [self.viewControllerSectionLayoutSettings updateDisplay];
                
                UIEdgeInsets ei = self.viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets;
                self.viewControllerSectionLayoutSettings.tableView.contentInset = UIEdgeInsetsMake(ei.top, ei.left, CGSizeZero.height, ei.right);
                self.viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(ei.top, ei.left, CGSizeZero.height, ei.right);
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
            
            if (self.selectedObjectIds.count == 1) {    // Show toolbox if we are selecting the first item.
                
                [self showToolbox];
                
            } else {
                
                [self adjustToolboxLocation];
                
            }
            
            [self setDisplayInactive];
            
        } else {
            
            [self deselectElementView: elementView animated: YES];
            [self.selectedObjectIds removeObject: elementView.objectIdTag];
            (self.viewControllerToolbox).selectedObjectIds = self.selectedObjectIds;
            
            [self.promptManager removeString: elementView.displayStringAttributed.string];
            [self displayPrompt];
            
            if (self.selectedObjectIds.count == 0) {
                
                [self hideToolbox];         // Hide toolbox location
                
            } else {
                
                [self adjustToolboxLocation];
                [self setDisplayInactive];
            }
        }
    }
}

#pragma mark - Save after Unwind from Modal View Controller

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

- (void)saveDynamicLabel:(MTQueryBuilderChooseFieldViewController *)viewController {
    
    MTQueryBuilderChooseFieldViewController *dynamicFieldController;
    dynamicFieldController = (MTQueryBuilderChooseFieldViewController *)viewController;
 
    RptqQueryField *queryField = dynamicFieldController.queryField;

    NSNumber *keyDynamic = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeLabelDynamic];
    NSDictionary *definations = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    keyDynamic, MTDocumentObjectDefinationType,
                                    queryField.objectID, MTDocumentObjectDefinationObject, nil];
    
    [self insertDocumentObjectWithDefination: definations];
    
    [self scrollToDetailSectionView];
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
    
    if (_aggregateToEdit && _editAggregate) {
        
        if (viewController.fieldObject != nil) {
            [self.aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
                                                                inputType: MTAggregateFunctionInputTypeField
                                                                groupType: viewController.aggregateGroupByType
                                                          aggregateObject: viewController.fieldObject
                                                              groupNumber: (NSUInteger)viewController.groupTypeSectionNumber];
        }
        
    } else {
        if (viewController.fieldObjectId != nil) {
        
            NSNumber *groupNumber;
            groupNumber = [[NSNumber alloc] initWithInteger:viewController.groupTypeSectionNumber];
            
            [self insertDocumentObjectNewAggregateFunctionWithType: viewController.aggregateFunctionType
                                                         inputType: MTAggregateFunctionInputTypeField
                                                       inputObject: viewController.fieldObjectId
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
        RptqDocumentObject *object;
        object = (RptqDocumentObject *)[managedObjectContext objectWithID:_objectIdEditBarcode];
        RptqDocumentObjectBarcode *barcodeObject = object.isBarcode;
        [barcodeObject updateWithBarcode: barcode
                                fieldOne: viewController.queryField1
                                fieldTwo: viewController.queryField2];
        _objectIdEditBarcode = nil;
        
    } else {
        
        NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
        NSNumber *type = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeBarcode];
        defination[MTDocumentObjectDefinationType] = type;
        defination[MTDocumentObjectDefinationObject] = viewController.barcode;
        
        RptqQueryField *queryField1 = viewController.queryField1;
        if (queryField1 != nil) {
            defination[MTDocumentObjectDefinationField1] = queryField1.objectID;
        }
        
        RptqQueryField *queryField2 = viewController.queryField2;
        if (queryField2 != nil) {
            defination[MTDocumentObjectDefinationField2] = queryField2.objectID;
        }
        [self insertDocumentObjectWithDefination:defination];
        
    }
    [self scrollToDetailSectionView];
}

#pragma mark - Helpers
#pragma mark General

- (BOOL)elementViewIsSelected:(MADDesignerElementView *)elementView {
    return [self.selectedObjectIds containsObject:elementView.objectIdTag];
}

- (NSUInteger)removeBorderFromAllSectionViews {
    NSUInteger deselectedSectionViewCounter = 0;
    for (id view in self.sectionControlViewsDictionary.allValues) {
        deselectedSectionViewCounter += [self removeBorderFromView: view] ? 1 : 0;
    }
    return deselectedSectionViewCounter;
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
        
        CGRect frame = ((MADToolboxTransitioningDelegate *)_toolboxTransitioningDelegate).presentationController.presentedViewController.view.frame;
        CGRect bounds = [self.scroller positionForRectOfInterest: [self rectForSelectedElements]
                                               withPresentedRect: frame
                                                   containerSize: self.view.frame.size
                                                      adjustment: self.topLayoutGuide.length];
        [self repositionSectionViews:bounds];
    }
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:(MADDesignerViewController *)reportDesigner {
    RptqQuery *query = self.document.activeDocumentModel.defaultDatabase.defaultQuery;
    RptqDocumentSection *documentSection;
    documentSection = [query documentSectionForSelectedIndex: (NSUInteger)reportDesigner.lastSelectedSectionControlPanel];
    UIView *selectedSectionView = [reportDesigner getSectionViewForDocumentSection:documentSection];
    if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
        [self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
        CGRect presentedRect = ((MADToolboxTransitioningDelegate *)self.settingsTransitioningDelegate).presentationController.presentedViewController.view.frame;
        CGRect position = [self.scroller positionForRectOfInterest: selectedSectionView.frame
                                                 withPresentedRect: presentedRect
                                                     containerSize: self.view.frame.size
                                                        adjustment: self.topLayoutGuide.length];
        [self repositionSectionViews:position];
    }
}

static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect);
static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect) {
    return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.width, CGSizeZero.height, presentedRect.size.width - MTReportDesignerBorderPaddingSides);
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
    
    NSUInteger numberOfViewsDeselected = [self removeBorderFromAllSectionViews];
    
    if (numberOfViewsDeselected == 0) {
        NSManagedObjectID *objectID = elementView.objectIdTag.copy;
        [self.selectedObjectIds addObject: objectID];
        [self applyBorderToView: elementView];
        
        self.viewControllerToolbox.document = self.document;
        self.viewControllerToolbox.selectedObjectIds = self.selectedObjectIds.copy;
        
    }
}

- (void)deselectElementView:(MADDesignerElementView *)elementView animated:(BOOL)animated {
    
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
    RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    RptqDocumentSection *section;
    section = [query documentSectionForSelectedIndex:(NSUInteger)_lastSelectedSectionControlPanel];
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
    
    MADDesignerSectionView *detailSection = [self getSectionViewForDocumentSection: rptqDocument.hasDetailSection];
    MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[detailSection.objectIdTag];
    
    MADDesignerViewController * __weak weakself = self;
    [detailSection performBatchUpdates:^{

        MADDesignerViewController * sself = weakself;
        
        NSIndexPath *path;
        NSArray *indexPathsInserted;
        MADSectionLayoutAttributes *la;
        RptqDocumentObject *documentObject = [rptqDocument addDocumentObject:documentObjectDefination];

        NSArray *objects = [[NSArray alloc] initWithObjects:documentObject, nil];

        NSError * __autoreleasing *error = NULL;
        [rptqDocument.managedObjectContext obtainPermanentIDsForObjects: objects
                                                                  error: error];
        
        path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count
                                   inSection: 0];
        
        la = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
        la.objectID = documentObject.objectID.copy;
        sself.objectIdJustDisplayed = documentObject.objectID.copy;
        
        la.frame = [documentObject elementViewFrameDesigner];
        [layoutManager addItem:la];
        [layoutManager layout];
        
        indexPathsInserted = [[NSArray alloc] initWithObjects: path, nil];
        [section addDocumentObject: documentObject
                     withDropPoint: la.frame.origin
              managedObjectContext: section.managedObjectContext];
        
        [detailSection insertItemsAtIndexPaths: indexPathsInserted];
        [section.managedObjectContext save:nil];
        
    } completion:^(BOOL finished) {
        
        [weakself.scroller.container setNeedsUpdateConstraints];
        
    }];
}

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = cell.objectIdTag;
    
    MADocument *document;
    RptqDocumentObject *documentObject;
    MADDesignerSectionView *sectionView;
    MADSectionLayoutManager *layoutManager;
    MADSectionLayoutAttributes *itemToRemove;
    
    document = _document;
    documentObject  = [document.managedObjectContext objectWithID:objectId];
    sectionView = [self getSectionViewForDocumentSection:documentObject.inSectionRow.inSection];
    layoutManager = document.sectionLayoutManagers[sectionView.objectIdTag];
    itemToRemove = (layoutManager.items)[objectId];
    
    [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
    
        MADocument *maDocument = self.document;
        [maDocument removeDocumentObjectWithObjectID: objectId
                                managedObjectContext: maDocument.managedObjectContext];
    
    } animationComplete:^() {

        [self.scroller.container invalidateIntrinsicContentSize];
        [self.view setNeedsUpdateConstraints];

    } completion:^() {

        [self redrawAllElementViewsInCollectionView:sectionView];
        RptqDocumentObject *documentObjectFinished;
        documentObjectFinished = [document.managedObjectContext objectWithID:objectId];
        [RptqDocument removeDocumentObject: documentObjectFinished
                  fromManagedObjectContext: document.managedObjectContext];
        [document.managedObjectContext save:nil];

    }];
}

- (CGRect)rectForSelectedElements {
    NSSet *views = [self selectedElementViews];
    return [self.scroller.container popoverRectForSelectedViews:views];
}

- (UIView *)viewForObjectID:(NSManagedObjectID *)objectID {
    return [self.scroller.container viewWithTag: (NSInteger)objectID.hash];
}

- (void)adjustContextOffsetForOpenPopover {
    if ([self padLike]) {
        if (self.sectionSettingsVisible &&
            self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
            
            [self adjustSettingsLocation];
            
        } else if (self.toolboxVisible &&
                   self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
            
            [self adjustToolboxLocation];
            
        }
    }
}

- (void)adjustPassthroughViews {
    
    if (self.sectionSettingsVisible) {
        self.settingsTransitioningDelegate.passthroughContainers =  self.passthroughContainers;
        self.settingsTransitioningDelegate.passthroughViews =       [self passthroughViews];
        self.settingsTransitioningDelegate.passthroughContainer =   self.scroller;
    } else if (self.toolboxVisible) {
        self.toolboxTransitioningDelegate.passthroughContainers =   self.passthroughContainers;
        self.toolboxTransitioningDelegate.passthroughViews =        [self passthroughViews];
        self.toolboxTransitioningDelegate.passthroughContainer =    self.scroller;
    }
    
}

- (void)dismissSectionPresentationIfOpen {
    
    if (self.sectionSettingsVisible &&
        self.settingsTransitioningDelegate.presentationController.presentedViewController != nil) {
        
        self.sectionSettingsVisible = false;
        [self dismissViewControllerAnimated: YES completion: NULL];
        [self removeBorderFromAllSectionViews];
        [self.document.managedObjectContext save:nil];
        
    }
    
}

- (void)dismissToolboxPresentationIfOpen {
    
    if (self.toolboxVisible &&
        self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil) {
        
        self.toolboxVisible = false;
        [self dismissViewControllerAnimated: YES completion: NULL];
        [self deselectAllElementsAnimated:YES];
        [self.document.managedObjectContext save:nil];
        
    }
    
}

#pragma mark Gesture Helpers

- (void)translatePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    gestureRecognizer.view.center = CGPointMake(gestureRecognizer.view.center.x + translation.x,
                                                gestureRecognizer.view.center.y + translation.y);
    [gestureRecognizer setTranslation:CGPointZero inView:self.view];
}

- (void)beginPanPiece: (MADManagedObjectView *)piece transition: (void (^)(void))transition
           completion: (void (^)(void))completion {
    
    [[UIMenuController sharedMenuController] setMenuVisible: NO animated: YES];
    
    if (self.presentedViewController != nil) {
        [self hideToolbox];
    }
    
    [self setScrollersEnabled: NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        piece.alpha = 0.80000f;
    }];
    [self.scroller.container bringSubviewToFront: piece];

    NSManagedObjectID *pieceObjectIDTag = piece.objectIdTag;
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = _document.managedObjectContext;
    
    MADDesignerViewController __weak *weakself = self;
    [private performBlockAndWait:^{
        MADDesignerViewController *strongself = weakself;
        if (!strongself) return;
        
        RptqDocumentObject *documentObject = [private objectWithID:pieceObjectIDTag];
        NSManagedObjectID *documentObjectSectionKey;
        documentObjectSectionKey = [documentObject.inSectionRow.inSection copySectionKey];

        MADDesignerViewController __weak *weakself1 = strongself;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            MADDesignerViewController *strongself1 = weakself1;
            
            MADDesignerSectionView *sectionView = strongself1->_sectionViewsDictionary[documentObjectSectionKey];
            CGRect b = [strongself1.view convertRect:piece.frame fromView:sectionView];
            piece.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, b.size.width, b.size.height);
            [strongself1.view addSubview: piece];
            [UIView animateWithDuration:0.2 animations:^{
                piece.alpha = 0.80000f;
            }];
            
            transition();
            
            MADocument *document = strongself1.document;
            MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[sectionView.objectIdTag];
            MADSectionLayoutAttributes *itemToRemove = (layoutManager.items)[pieceObjectIDTag];
            
            MADocument * __unsafe_unretained wdocument = document;
            MADDesignerViewController __weak *weakself2 = strongself1;
            [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
            
                MADocument *sdocument = wdocument;
                [sdocument removeDocumentObjectWithObjectID: pieceObjectIDTag
                                       managedObjectContext: sdocument.managedObjectContext];
                
            } animationComplete:^() {

                MADDesignerViewController *strongself2 = weakself2;
                [strongself2.scroller.container invalidateIntrinsicContentSize];
                [strongself2.view setNeedsUpdateConstraints];

            } completion:^() {

                MADDesignerViewController *strongself2 = weakself2;
                [strongself2 redrawAllElementViewsInCollectionView:sectionView];
                completion();

            }];
        }];
        
    }];
}

- (void)endPanPieceWithGesture:(UIPanGestureRecognizer *)gesture {

    MADDesignerElementView *piece = (MADDesignerElementView *)gesture.view;
    NSManagedObjectID *pieceObjectIdTag = piece.objectIdTag.copy;
    
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
    
    CGPoint locationInSection = [self.view convertPoint:gesture.view.frame.origin toView:sectionView];

    if (sectionView != nil) {
        
        NSManagedObjectID *sectionViewObjectIdTag = sectionView.objectIdTag;
        NSManagedObjectContext *private;
        private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        private.parentContext = self.document.managedObjectContext;
        [private performBlockAndWait:^{

            RptqDocumentSection *documentSection = [private objectRegisteredForID:sectionViewObjectIdTag];
            NSManagedObjectID *documentSectionKey = [documentSection copySectionKey];
            CGFloat documentSectionHeight = documentSection.height.floatValue;
            
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
                    la.objectID = pieceObjectIdTag;
                    
                    NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
                    RptqDocumentSection *documentSectionBlock = [managedObjectContext objectWithID:sectionViewObjectIdTag];
                    RptqDocumentObject *documentObject = [managedObjectContext objectWithID:pieceObjectIdTag];
                    
                    CGSize documentObjectSize = documentObject.size;
                    
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
                    

                    RptqDocumentSection *documentSectionBlock = [managedObjectContext objectRegisteredForID:sectionViewObjectIdTag];

                    CGFloat sectionViewIntrinsicContentSizeHeight = [sectionView intrinsicContentSize].height;
                    CFNumberRef h = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &sectionViewIntrinsicContentSizeHeight);
                    documentSectionBlock.height = (__bridge NSNumber *)(h);
                    CFRelease(h);
                    
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

#pragma mark Display Helpers

- (void)relayoutSectionView:(MADDesignerSectionView *)documentSectionView {
    
    NSManagedObjectContext *private;
    private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    NSManagedObjectID *objectId = documentSectionView.objectIdTag;
    __block NSManagedObjectID *key = nil;
    __block CGFloat height;

    [private performBlockAndWait:^{
        RptqDocumentSection *documentSection;
        documentSection = [private objectRegisteredForID:objectId];
        key = [documentSection copySectionKey];
        height = documentSection.height.floatValue;
    }];
    
    NSLayoutConstraint *layoutConstraint = self.layoutConstraintsReportSectionHeight[key];
    layoutConstraint.constant = height;
    [self.view setNeedsUpdateConstraints];
}

- (void)setDisplayActive {
    [self setHidesStatusBar: NO];
    self.sectionSettingsVisible = false;
    self.toolboxVisible = false;
    
    MADTabBarController *tabBarController = self.tabBarController;
    tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [tabBarController enableTabBarItems];
}

- (void)setDisplayInactive {
    MADTabBarController *tabBarController = self.tabBarController;
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

#pragma mark Element View helpers

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
        
        if (self.popoverControllerObjectSelector != nil)
            [allpopovers addObject:self.popoverControllerObjectSelector];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if (popoverController.popoverVisible) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }
        [self deselectAllElementsAnimated:YES];
    }
    [self setDisplayActive];
    return result;
}

- (NSSet *)elementViews {
    
    RptqDocumentSectionEnumerator *sectionEnumerator;
    RptqDocument *activeDocumentModel = self.document.activeDocumentModel;
    sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument: activeDocumentModel];
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    MADDesignerSectionView *documentSectionView;
    RptqDocumentSection *documentSection;
    for (documentSection in sectionEnumerator) {
        documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier.integerValue];

        NSInteger numberOfItemsInSection,
                  numberOfSections = documentSectionView.numberOfSections,
                  section, item;
        
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

- (NSArray <MADDesignerElementView *> *)elementViewsInSection:(NSInteger)section
                                       numberOfItemsInSection:(NSUInteger)numberOfItemsInSection
                                             inCollectionView:(UICollectionView *)collectionView {
    MADDesignerElementView *elementView;
    NSIndexPath *path;
    NSMutableArray <MADDesignerElementView *> *elementViews;
    elementViews = [[NSMutableArray <MADDesignerElementView *> alloc] initWithCapacity:numberOfItemsInSection];
    NSUInteger item;
    for (item = 0; item < numberOfItemsInSection; item++) {
        
        path = [NSIndexPath indexPathForItem:(NSInteger)item inSection:section];
        elementView = [self elementViewAtIndexPath: path
                                  inCollectionView: collectionView];
        if (elementView != nil) [elementViews addObject:elementView];
    }
    return elementViews;
}

- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifer {
    MADDesignerSectionView *documentSectionView = nil;
    NSArray<__kindof UIView *> *subviews = _scroller.container.subviews;
    for (UIView *subview in subviews) {
        if (subview.tag == identifer && [subview isKindOfClass:[MADDesignerSectionView class]]) {
            documentSectionView = (MADDesignerSectionView *)subview;
            break;
        }
    }
    return documentSectionView;
}

- (NSSet *)selectedElementViews {
    
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    if (self.selectedObjectIds.count > 0) {
        
        //Try quick hash method...
        BOOL quickHashWorks = YES;
        for (NSManagedObjectID *selectedObjectId in self.selectedObjectIds) {
            UIView *selectedView = [self viewForObjectID:selectedObjectId];
            if (selectedView != nil) {
                [results addObject:selectedView];
            } else {
                quickHashWorks = NO;
            }
        }
        
        //NSAssert(quickHashWorks, @"Maybe not such a good idea.");
        if (quickHashWorks == NO) {     //Case when views are off screen.
            
            RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
            
            for (RptqDocumentSection *documentSection in sectionEnumerator) {
                MADDesignerSectionView *documentSectionView;
                documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier.integerValue];
                
                for (NSInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
                
                    for (NSInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                        MADDesignerElementView *elementView = [self elementViewAtIndexPath:indexPath
                                                                          inCollectionView:documentSectionView];
                        if ([self.selectedObjectIds containsObject: elementView.objectIdTag]) {
                            [results addObject:elementView];
                        }
                    }
                }
            }
        }
    }
    return results;
}

- (MADDesignerSectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)documentSection {
    NSManagedObjectID *sectionKey = [documentSection copySectionKey];
    return self.sectionViewsDictionary[sectionKey];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    NSManagedObjectID *sectionKey = [documentSection copySectionKey];
    return self.sectionControlViewsDictionary[sectionKey];
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
    
    //Remove border from element views
    for (MADDesignerElementView *elementView in [self selectedElementViews]) {
        [self deselectElementView:elementView animated:animated];
    }
    
    [self.selectedObjectIds removeAllObjects];
    (self.viewControllerToolbox).selectedObjectIds = self.selectedObjectIds;
    
    [self displaySectionViewsRemoveBorder];
    
    [self.promptManager removeAll];
    [self displayPrompt];
}

- (void)displayPrompt {
    MADTabBarController * __unsafe_unretained tabBarController = self.tabBarController;
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        tabBarController.navigationItem.prompt = self.promptManager.prompt.copy;
    } else {
        if (tabBarController.navigationItem.prompt != nil) {
            tabBarController.navigationItem.prompt = nil;
        }
    }
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

- (void)applyBorderToView:(MADDesignerElementView *)view {
    
    view.enableResizing = YES;
    
    NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
    self.borderAppliedToView[key] = @YES;
    
    UIColor *tintColor = [MADColorEverydayApps newColorAnalogous4];
    view.layer.borderColor = tintColor.CGColor;
    view.layer.borderWidth = [UIView borderWidthThin];
    
}

- (BOOL)removeBorderFromView:(MADDesignerElementView *)view {
    BOOL result;
    if ([self isBorderAppliedToView:view]) {

        NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
        self.borderAppliedToView[key] = @NO;
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

- (BOOL)isBorderAppliedToView:(UIView *)view {
    NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
    NSNumber __unsafe_unretained *borderAppliedToView = _borderAppliedToView[key];
    return borderAppliedToView.boolValue;
}

- (MADDesignerElementView *)elementViewForManagedObject:(NSManagedObject *)managedObject {
    id elementView;
    RptqDocumentObject *documentObject;

    elementView = [self viewForObjectID:managedObject.objectID];
    if (elementView) goto ElementViewForManagedObjectShortCircut;
    
    documentObject = [RptqDocumentObject documentObjectForObject:managedObject];
    if (!documentObject) goto ElementViewForManagedObjectShortCircut;


    elementView = [self viewForObjectID:documentObject.objectID];
    if (elementView) goto ElementViewForManagedObjectShortCircut;

    SEL handleTap = @selector(handleToggleElementView:);
    elementView = [MADDesignerElementView newDesignerElementViewForDocumentObject: documentObject
                                                               tapGestureDelegate: self
                                                                      tapSelector: handleTap];

    ElementViewForManagedObjectShortCircut:;
    
    return elementView;
}

#pragma mark Constraints Helpers

- (void)contentViewRemoveAllConstraints {

    MADLayoutConstraints *constraints = self.scroller.container.constraints;
    if (constraints.count > 0) {
        [self.scroller.container removeConstraints:constraints];
    }
}

- (void)scrollerRemoveAllConstraints {
    MADLayoutConstraints *constraints = self.scroller.constraints;
    if (constraints.count > 0) {
        [self.scroller removeConstraints:constraints];
    }
}

- (CGFloat)toolboxHeightCalculated {
    return ((MADToolboxTransitioningDelegate *)self.toolboxTransitioningDelegate).presentationController.presentedViewController.view.frame.size.height;
}

static inline CGFloat DetailDisplayFrameOriginX(CGFloat width);
static inline CGFloat DetailDisplayFrameOriginX(CGFloat width) {
    return width - MADSizeWidthViewDetailDisplay - MTReportDesignerBorderPaddingDetail;
}

static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop);
static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop) {
    return CGPointZero.y + marginTop + MTReportDesignerBorderPaddingDetail;
}

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
    
    for (UIView *subview in self.sectionViewsArray) {
        height += subview.frame.size.height <= CGSizeZero.height ?
        ceil(subview.intrinsicContentSize.height) :
        subview.frame.size.height;
    }
    
    return CGSizeMake(self.view.bounds.size.width, height);
}

- (bool)showOnSide {
    return self.presentingViewController.traitCollection.verticalSizeClass ==
                UIUserInterfaceSizeClassCompact;
}

- (void)scrollToDetailSectionView {
    if (self.presentedViewController != nil) {
        UIView *sectionView = [self detailSectionView];
        CGRect rect = sectionView.frame;
        self.hidesStatusBar = false;
        [self.scroller scrollRectToVisible:rect animated:YES];
    }
}

- (UIView *)detailSectionView {
    return (UIView *)_sectionControlViewsDictionary[_document.activeDocumentModel.hasDetailSection.objectID];
}

- (void)adjustSettingsLocation {
    self.settingsTransitioningDelegate.sourceRect = self.lastSelectedLabel.frame;
}

- (void)adjustToolboxLocation {
    self.toolboxTransitioningDelegate.sourceRect = self.rectForSelectedElements;
    self.viewControllerToolbox.selectedObjectIds = self.selectedObjectIds;
}

#pragma mark NSNotificationCenter Helpers

- (void)addObservers {

    MADocument *document = self.document;
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self selector: @selector(managedObjectContextDidChange:)
                          name: NSManagedObjectContextObjectsDidChangeNotification
                        object: document.managedObjectContext];
    
    [defaultCenter addObserver: self selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: document.managedObjectContext];
    
    [defaultCenter addObserver: self selector: @selector(didHideMenuNotification:)
                          name: UIMenuControllerDidHideMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self selector: @selector(willHideMenuNotification:)
                          name: UIMenuControllerWillHideMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self selector: @selector(didShowMenuNotification:)
                          name: UIMenuControllerDidShowMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self selector: @selector(willShowMenuNotification:)
                          name: UIMenuControllerWillShowMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self selector: @selector(documentStateChanged)
                          name: UIDocumentStateChangedNotification
                        object: document];
}

- (void)removeObservers {
    
    MADocument *document = self.document;
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: self name: NSManagedObjectContextObjectsDidChangeNotification
                           object: document.managedObjectContext];
    
    [defaultCenter removeObserver: self name: NSManagedObjectContextDidSaveNotification
                           object: document.managedObjectContext];
    
    [defaultCenter removeObserver: self name: UIMenuControllerDidHideMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self name: UIMenuControllerDidShowMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self name: UIMenuControllerWillHideMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self name: UIMenuControllerWillShowMenuNotification
                           object: nil];
    
    [defaultCenter removeObserver: self name: UIDocumentStateChangedNotification
                           object: document];
}

#pragma mark - Creators

static const inline CGSize sizePopoverDefault() {
    return CGSizeMake(MADDefaultsPopooverWidth, 320.0000f);
}

static const inline CGSize sizePopoverFonts() {
    return CGSizeMake(MADDefaultsPopooverWidth, MADDefaultsPopooverHeight);
}

+ (MADDesignerSectionView *)documentSectionView:(RptqDocumentSection *)section delegate:(id)layoutDelegate {
    MADDesignerSectionView *collectionView = [[MADDesignerSectionView alloc] initWithFrame:CGRectZero];
    ((MTReportDesignerSectionViewLayoutLiquid *)collectionView.collectionViewLayout).delegate = layoutDelegate;
    collectionView.objectIdTag = section.objectID;
    collectionView.tag = section.identifier.integerValue;
    collectionView.visible = section.visibility.boolValue;
    collectionView.selected = NO;
    return collectionView;
}

#pragma mark - Actions

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
    
    UINavigationController *navigationController = [UINavigationController elementPicker];
    MADDesignerElementPickerViewController *pickerController = (MADDesignerElementPickerViewController *)navigationController.topViewController;
    pickerController.objectSelectorDelegate = self;
    pickerController.document = self.document;
    
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.preferredContentSize = sizePopoverDefault();
    
    UIPopoverPresentationController *popoverController = navigationController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.barButtonItem = sender;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self presentViewController: navigationController animated: YES completion:^{
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, pickerController);
    }];
    [self setDisplayInactive];
    
}

- (IBAction)actionCancel:(id)sender {
    self.hidesStatusBar = false;
    [self dismissViewControllerAnimated:YES completion:^{
        [self setDisplayActive];
    }];
}

- (IBAction)actionDismiss {
    [self deselectAllElementsAnimated:YES];
    [self.document.managedObjectContext save:nil];
}

- (IBAction)hideToolbox {
    self.hidesStatusBar = false;

    typeof(self) __weak weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        MADDesignerViewController *sself = weakself;
        if (sself) {
            [sself actionDismiss];
            [sself setDisplayActive];
        }
    }];
}

- (IBAction)showToolbox {
    
    self.toolboxVisible = true;
    self.sectionSettingsVisible = false;
    
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

#pragma mark - Convenience

+ (UIFont *)captionFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
}

- (void)showSectionSettingsFromLabel:(UILabel *)label {
    
    self.toolboxVisible = false;
    self.settingsTransitioningDelegate.sourceRect = label.frame;
    self.settingsTransitioningDelegate.sourceView = self.scroller.container;
    self.settingsTransitioningDelegate.permittedArrowDirections = UIPopoverArrowDirectionAny;
    self.settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;
    self.settingsTransitioningDelegate.container = self.scroller.container;
    self.settingsTransitioningDelegate.passthroughContainers = self.passthroughContainers;
    self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
    self.settingsTransitioningDelegate.passthroughContainer = self.scroller;
    
    if (self.sectionSettingsVisible == false) {
        self.sectionSettingsVisible = true;
        [self presentViewController: self.navigationControllerSectionLayoutSettings animated: YES completion: ^{
            [self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
        }];
    } else {
        [self adjustContextOffsetForToolboxWithToolboxType: MTToolboxTypeSection];
    }
    
}

- (NSSet *)passthroughViews {
    NSSet *sectionLabels = [NSSet setWithArray:self.sectionControlViewsDictionary.allValues];
    NSSet *passthroughViews = [sectionLabels setByAddingObjectsFromSet:self.visibleElementViews];
    return passthroughViews;
}

#pragma mark MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemMadDesigner8];
}

@end
