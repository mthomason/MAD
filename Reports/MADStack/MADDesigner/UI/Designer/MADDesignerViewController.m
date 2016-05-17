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

#include <math.h>
#import <MAD/MADFont.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/NSManagedObject+Extras.h>
#import <MAD/NSManagedObjectID+Extras.h>
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
#import "MTViewControllerBarcode.h"
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
static const CGFloat MTReportDesignerSectionLabelPaddingRight   = 8.0000f;

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

    @property (nonatomic, weak) IBOutlet MADBackgroundScrollView *scroller;

    @property (nonatomic, strong) NSMutableSet          <__kindof MADDesignerElementView *>                         *visibleElementViews;
    @property (nonatomic, strong) NSMutableSet          <__kindof MADDesignerSectionView *>                         *passthroughContainers;
    @property (nonatomic, strong) NSMutableSet          <__kindof NSManagedObjectID *>                              *selectedObjectIds;

    @property (nonatomic, strong) NSMutableArray        <__kindof MADDesignerSectionView *>                         *sectionViewsArray;

    @property (nonatomic, strong) NSMutableDictionary   <__kindof NSString *, __kindof MADDesignerSectionView *>    *sectionViewsDictionary;
    @property (nonatomic, strong) NSMutableDictionary   <__kindof NSString *, __kindof MADDesignerSectionLabel *>   *sectionControlViewsDictionary;

    @property (nonatomic, strong) NSMutableArray        <__kindof NSLayoutConstraint *>                             *viewDidAppearDesignerScrollViewConstraints;
    @property (nonatomic, strong) NSMutableArray        <__kindof NSLayoutConstraint *>                             *viewDidAppearDesignerContentViewConstraints;
    @property (nonatomic, strong) NSMutableArray        <__kindof NSLayoutConstraint *>                             *layoutConstraintSectionLabelHeightContainer;
    @property (nonatomic, strong) NSMutableArray        <__kindof NSLayoutConstraint *>                             *layoutConstraintsSectionsSidesBorder;
    @property (nonatomic, strong) NSMutableArray        <__kindof NSLayoutConstraint *>                             *layoutConstraintsSectionsVerticalBuffer;

    @property (nonatomic, strong) NSMutableDictionary <__kindof NSString *, __kindof NSLayoutConstraint *>          *layoutConstraintsReportSectionHeight;

    @property (nonatomic, strong) NSMutableDictionary <__kindof NSNumber *, __kindof NSNumber *>                    *borderAppliedToView;

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

static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView);
static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView) {
    return scrollView.contentSize.width * 0.5000f + MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5000f, 0.0000f);
}

static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView);
static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView) {
    return scrollView.contentSize.height * 0.5000f + MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5000f, 0.0000f);
}

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
        [self tableViewControllerChooseFieldDidFinish: action.sourceViewController withField: [action.sourceViewController queryField]];
        
    } else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectDynamicLabelSaveIdentifer]) {
        [self saveDynamicLabel: action.sourceViewController];
        
    } else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectAggregateLabelSaveIdentifer]) {
        [self saveAggregateLabel: action.sourceViewController];
        
    } else if ([action.identifier isEqualToString:MTSegueNewDocumentObjectBarcodeSaveIdentifer]) {
        [self saveBarcodeLabel: action.sourceViewController];
        
    }
    
    [self setDisplayActive];
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return action == @selector(unwindToDesigner:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    
    return action == @selector(unwindToDesigner:) ?
            self : [super viewControllerForUnwindSegueAction: action fromViewController: fromViewController withSender: sender];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        self.numberFormatterPercentage = numberFormatter;
        
        NSMutableSet <__kindof MADDesignerElementView *> *visibleElementViews = [NSMutableSet new];
        self.visibleElementViews = visibleElementViews;

        MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
        self.ruler = viewRuler;
        
        NSMutableDictionary <__kindof NSNumber *, __kindof NSNumber *> *borderAppliedToView = [[NSMutableDictionary alloc] init];
        self.borderAppliedToView = borderAppliedToView;
        
        MADDesignerStatusLabel *detailDisplay = [[MADDesignerStatusLabel alloc] initWithFrame: CGRectZero];
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
    
    MADToolboxTransitioningDelegate *transitioningDelegate = [[MADToolboxTransitioningDelegate alloc] init];
    transitioningDelegate.popoverPresentationControllerDelegate = self;
    transitioningDelegate.passthroughContainer = self.scroller;

    MADToolboxTransitioningDelegate *settingsTransitioningDelegate = [[MADToolboxTransitioningDelegate alloc] init];
    settingsTransitioningDelegate.popoverPresentationControllerDelegate = self;

    UINavigationController *navigationControllerToolbox = [UINavigationController navigationControllerToolbox];
    navigationControllerToolbox.transitioningDelegate = transitioningDelegate;
    navigationControllerToolbox.modalPresentationStyle = UIModalPresentationCustom;
    navigationControllerToolbox.preferredContentSize = sizePopoverDefault();

    MADToolboxViewController *viewControllerToolbox = (MADToolboxViewController *)navigationControllerToolbox.topViewController;
    viewControllerToolbox.clearsBackground = [self padLike];
    viewControllerToolbox.document = document;
    viewControllerToolbox.selectedObjectIds = self.selectedObjectIds;
    self.viewControllerToolbox = viewControllerToolbox;
    
    self.navigationControllerToolbox = navigationControllerToolbox;
    self.toolboxTransitioningDelegate = transitioningDelegate;
    
    MADPromptManager *promptManager = [[MADPromptManager alloc] initWithDefaultPrompt:document.fileURL.lastPathComponent];
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
    
    UIGestureRecognizer *tap = [MADTapGestureRecognizer newTapGestureRecognizerStrayTouchWithTarget:self action:@selector(handleStrayTouch:) delegate:self];
    [tap requireGestureRecognizerToFail:tapGestureDoubleTap];
    [self.scroller addGestureRecognizer:tap];
    self.strayTouchGesture = tap;
    
    self.scroller.delegate = self;
    
    NSLayoutConstraint *constraintContentLeft = [NSLayoutConstraint view:self.view containerLeft:self.scroller.container];
    constraintContentLeft.priority = 999;
    
    NSLayoutConstraint *constraintContentRight = [NSLayoutConstraint view:self.view containerRight:self.scroller.container];
    constraintContentRight.priority = 999;
    
    NSLayoutConstraint *constraintContentTop = [NSLayoutConstraint view:self.scroller containerTop:self.scroller.container];
    NSLayoutConstraint *constraintScrollerBottom = [NSLayoutConstraint scroller:self.scroller bottom:self.bottomLayoutGuide];
    NSLayoutConstraint *constraintWidth = [NSLayoutConstraint content: self.scroller.container width: self.view.frame.size.width / self.scroller.zoomScale];
    
    self.layoutConstraintContainerWidth = constraintWidth;
    
    
    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [MTReportDesignerSectionLayoutSettingsViewController toolboxSettings];
    viewControllerSectionLayoutSettings.delegate = self;
    
    self.viewControllerSectionLayoutSettings = viewControllerSectionLayoutSettings;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewControllerSectionLayoutSettings];
    navigationController.transitioningDelegate = settingsTransitioningDelegate;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    
    self.navigationControllerSectionLayoutSettings = navigationController;
    self.navigationControllerSectionLayoutSettings.preferredContentSize =  CGSizeMake(MADDefaultsPopooverWidth, 100.0000f);
    
    self.settingsTransitioningDelegate = settingsTransitioningDelegate;
    
    NSLayoutConstraint *viewScrollerTop = [NSLayoutConstraint viewScrollerTop: self.scroller view: self.topLayoutGuide];

    NSMutableSet *selectedObjectIds = [NSMutableSet new];
    self.selectedObjectIds = selectedObjectIds;
    
    NSArray *constraints = @[constraintContentLeft, constraintContentRight, constraintContentTop, constraintScrollerBottom, constraintWidth, viewScrollerTop];
    [self.view addConstraints:constraints];
    
    self.scroller.container.backgroundColor = [UIColor clearColor];
    self.scroller.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    [self addObservers];
    
    self.lastMenuItemSelectRequiresElementView = false;
    self.zoomScaleRestore = self.scroller.zoomScale;
    [self.scroller setZoomScale: 1.0000f animated: NO];
    
    RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
    
    NSInteger sectionCounter = 0;
    NSUInteger numberOfSections = sectionEnumerator.count;
    
    [self.scroller.container addSubview:self.ruler];
    
    [self.view addSubview:self.statusLabelZoomScale];
    [self updateDisplayDetailZoomValue];
    
    NSArray <__kindof NSLayoutConstraint *> *rulerConstraints = [NSLayoutConstraint constraintForRuler: self.ruler designer: self.scroller.container marginTop: MTReportDesignerBorderPaddingVertical heigh: MTReportDesignerRulerHeight];
    NSArray <__kindof NSLayoutConstraint *> *rulerSideConstraints = [NSLayoutConstraint constraintForRuler: self.ruler designer: self.scroller.container sideMargin: MTReportDesignerBorderPaddingSides];
    
    NSMutableArray <__kindof NSString *> *reportSectionKeyTracker = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray <__kindof NSLayoutConstraint *> *scrollerLayoutConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 6];

    NSMutableArray <__kindof NSLayoutConstraint *> *viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 5];
    
    NSMutableArray <__kindof NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 2];
    NSMutableArray <__kindof NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray <__kindof NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray <__kindof MADDesignerSectionView *> *sectionViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];

    NSMutableDictionary <__kindof NSString *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    NSMutableDictionary <__kindof NSString *, __kindof MADDesignerSectionView *> *sectionViewsDictionary = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    NSMutableDictionary <__kindof NSString *, __kindof MADDesignerSectionLabel *> *sectionControlViewsDictionary = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];

    NSMutableSet <__kindof MADDesignerSectionView *> *passthroughContainers = [[NSMutableSet alloc] initWithCapacity:numberOfSections];

    [layoutConstraintsSectionsSidesBorder addObjectsFromArray:rulerSideConstraints];
    
    [scrollerLayoutConstraints addObjectsFromArray:rulerConstraints];
    [scrollerLayoutConstraints addObjectsFromArray:rulerSideConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    
    CGFloat borderWidthThin = [UIView borderWidthThin];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        @autoreleasepool {
            
            NSString *reportSectionKey = [reportSection copySectionKey];

            sectionHeights += (MTReportDesignerBufferPaddingVertical + reportSection.height.floatValue);
            
            MADDesignerSectionView *sectionView = [MADDesignerViewController documentSectionView: reportSection delegate: self];
            sectionView.delegate = self;
            sectionView.dataSource = self;
            sectionView.layer.borderWidth = borderWidthThin;
            sectionView.showsVerticalScrollIndicator = YES;
            
            ((MTReportDesignerSectionViewLayoutLiquid *)sectionView.collectionViewLayout).tag = sectionCounter;
            
            MADDesignerSectionLabel *sectionViewLabel = [[MADDesignerSectionLabel alloc] initWithSection:reportSection];
            
            UIGestureRecognizer *tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerSectionToggleWithTarget:self action:@selector(handleToggleSectionControlPanel:) delegate:self];
            
            [self.strayTouchGesture requireGestureRecognizerToFail:tapGestureRecognizer];
            [sectionViewLabel addGestureRecognizer: tapGestureRecognizer];
            
            sectionViewLabel.tag = sectionCounter;
            
            NSString *lastKey = reportSectionKeyTracker.lastObject;
            UIView *constraintItem =  sectionCounter == 0 ? self.ruler : sectionViewsDictionary[lastKey];
            NSString *key = [sectionView.objectIdTag copyKey];
            NSLayoutConstraint *lc1a = [NSLayoutConstraint viewTop: constraintItem viewBottom: sectionView padding: MTReportDesignerBufferPaddingVertical];
            NSLayoutConstraint *lc1b = [NSLayoutConstraint view: sectionView height: reportSection.height.floatValue];
            NSLayoutConstraint *lc1c = [NSLayoutConstraint labelRight: sectionViewLabel container: sectionView padding: MTReportDesignerSectionLabelPaddingRight];
            NSLayoutConstraint *lc1d = [NSLayoutConstraint labelBottom:sectionViewLabel container: sectionView padding: MTReportDesignerBufferPaddingVertical];
            NSLayoutConstraint *lc1e = [NSLayoutConstraint label: sectionViewLabel toHeight: MTReportDesignerSectionLabelHeight];
            NSLayoutConstraint *lc1 = [NSLayoutConstraint viewLeft:sectionView content:self.scroller.container padding:MTReportDesignerBorderPaddingSides];
            NSLayoutConstraint *lc2 = [NSLayoutConstraint viewRight:sectionView content:self.scroller.container padding:MTReportDesignerBorderPaddingSides];
            NSArray *collectionViewConstraints = @[lc1, lc2];
            NSArray *sectionViewLabelConstraints = @[lc1a, lc1b, lc1c, lc1d, lc1e];

            [viewDidAppearDesignerContentViewConstraints addObjectsFromArray:sectionViewLabelConstraints];
            

            [layoutConstraintsSectionsVerticalBuffer addObject:lc1a];
            [layoutConstraintSectionLabelHeightContainer addObject:lc1e];
            
            [layoutConstraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];

            [scrollerLayoutConstraints addObjectsFromArray:collectionViewConstraints];

            [layoutConstraintsReportSectionHeight setObject:lc1b forKey:key];
            [sectionViewsDictionary setObject:sectionView forKey:reportSectionKey];
            [sectionControlViewsDictionary setObject:sectionViewLabel forKey:reportSectionKey];
            
            [reportSectionKeyTracker addObject:reportSectionKey];
            [sectionViewsArray addObject:sectionView];
            
            sectionCounter++;
            
            [self.scroller.container addSubview:sectionView];
            [self.scroller.container addSubview:sectionViewLabel];
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
    
    NSLayoutConstraint *layoutConstraintDesignerContentViewHeight = [NSLayoutConstraint view: self.scroller.container height: sectionHeights];

    [scrollerLayoutConstraints addObject:layoutConstraintDesignerContentViewHeight];

    self.layoutConstraintDesignerContentViewHeight = layoutConstraintDesignerContentViewHeight;
    
    
    NSLayoutConstraint *layoutConstraintContentToScollerBottom = [NSLayoutConstraint view: self.scroller.container containerBottom: self.scroller];
    
    [scrollerLayoutConstraints addObject:layoutConstraintContentToScollerBottom];
    
    [self.tabBarController enableTabBarItems];
    
    [self.scroller addConstraints: scrollerLayoutConstraints];
    [self.scroller.container addConstraints: viewDidAppearDesignerContentViewConstraints];
    
    UIBarButtonItem *barButtonItemAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionAdd:)];
    [self.tabBarController.navigationItem setRightBarButtonItem:barButtonItemAdd animated:NO];
    
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    self.viewDidAppearDesignerScrollViewConstraints = scrollerLayoutConstraints;

}

- (BOOL)prefersStatusBarHidden {
    return self.hidesStatusBar || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
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
        self.presentedViewController.childViewControllers.count > 0 && self.toolboxTransitioningDelegate.presentationController != nil &&
        ![self showOnSide]) {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                  self.toolboxTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height, CGSizeZero.width);
        
    } else if (self.settingsTransitioningDelegate.presentationController.presentedView.superview != nil &&
               self.presentedViewController.childViewControllers.count > 0 && self.settingsTransitioningDelegate.presentationController != nil &&
               ![self showOnSide]) {
        
        insets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width,
                                  self.settingsTransitioningDelegate.presentationController.presentedViewController.view.frame.size.height, CGSizeZero.width);
        
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
            sectionView.contentInset = UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.width, CGSizeZero.height, presentedRect.size.width - MTReportDesignerBorderPaddingSides);
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
        [segue.destinationViewController setDocument:self.document];
    }
    
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
            for (controlView in sectionControlViewsArray) {
                CGRect boundingRectWithSize = [controlView.text boundingRectWithSize: controlView.bounds.size
                                                                             options: -1
                                                                          attributes: attributes
                                                                             context: nil];
                
                controlView.preferredMaxLayoutWidth = boundingRectWithSize.size.width / scrollView.zoomScale;
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
        [sectionControlViewsArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(__kindof MADDesignerSectionLabel * _Nonnull controlView, NSUInteger idx, BOOL * _Nonnull stop) {
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
    NSNumber *number = @(self.scroller.zoomScale);
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
        [section setProducesFormFeed: newPageAfter ? YES : NO];
        
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
        NSNumber * visibility = [[NSNumber alloc] initWithBool:isVisible ? YES : NO];
        section.visibility = visibility;
        
        NSString *key = [section copySectionKey];

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
    
    NSString *key = [documentSection copySectionKey];
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
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:hasRows.count - 1];
        [documentSection setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    
    NSNumber *numberOfRowsObject = [[NSNumber alloc] initWithUnsignedInteger:numberOfRows];
    documentSection.numberOfRows = numberOfRowsObject;
    
    NSString *sectionKey = [documentSection copySectionKey];
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
                
                if ([change isEqualToString:NSStringFromSelector(@selector(sizewidth))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginRight))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingRight))]) {
                    
                    MADDesignerSectionView *section = [self getSectionViewForDocumentSection: documentObject.inSectionRow.inSection];
                    MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[section.objectIdTag];
                    MADSectionLayoutAttributes *attributes = layoutManager.items[documentObject.objectID];
                    if (attributes != nil) {
                        attributes.frame = CGRectMake(documentObject.originx.floatValue, documentObject.originy.floatValue, documentObject.size.width, documentObject.size.height);
                        self.objectIdJustDisplayed = documentObject.objectID.copy;
                        [layoutManager positionItem:attributes];
                        [section.collectionViewLayout invalidateLayout];
                    }
                    
                } else if ([change isEqualToString:NSStringFromSelector(@selector(sizeheight))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginBottom))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingBottom))]) {
                    
                    MADDesignerSectionView *section = [self getSectionViewForDocumentSection: documentObject.inSectionRow.inSection];
                    MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[section.objectIdTag];
                    MADSectionLayoutAttributes *attributes = layoutManager.items[documentObject.objectID];
                    if (attributes != nil) {
                        attributes.frame = CGRectMake(documentObject.originx.floatValue, documentObject.originy.floatValue, documentObject.size.width, documentObject.size.height);
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
    for (NSManagedObject *managedObject in managedObjectsUpdated) {
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
            [self.viewControllerToolbox setSelectedObjectIds:self.selectedObjectIds];
        }
        self.lastElementViewToShowMenu = nil;
    }
    self.lastMenuItemSelectRequiresElementView = false;
}
- (void)didShowMenuNotification:(NSNotification *)notification { }
- (void)willShowMenuNotification:(NSNotification *)notification { }

- (BOOL)padLike {
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // FIXME: Add ability to edit image fields.  84848422
    
    BOOL editedImageExist = info[UIImagePickerControllerEditedImage] != nil;
    UIImage *selectedImage = nil;
    if (editedImageExist) {
        selectedImage = info[UIImagePickerControllerEditedImage];
    } else {
        selectedImage = info[UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage != nil) {
        MADDesignerViewController *reportDesigner = self;
        self.hidesStatusBar = false;
        [self dismissViewControllerAnimated:YES completion:^{
            NSNumber *type = @(MTDocumentObjectTypeImage);
            NSDictionary *defination = @{MTDocumentObjectDefinationType: type,
                                         MTDocumentObjectDefinationObject : selectedImage};
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

- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
    
    UIViewController *result;
    if (style != UIModalPresentationPopover && [controller.presentedViewController isKindOfClass:[UINavigationController class]] == NO) {
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)];
        [controller.presentedViewController.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
        controller.presentedViewController.view.backgroundColor = [UIColor clearColor];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
        navigationController.navigationBar.translucent = YES;
        navigationController.navigationBar.backgroundColor = [UIColor clearColor];
        navigationController.view.backgroundColor = [UIColor clearColor];
        result = navigationController;
        
    } else if ([controller.presentedViewController isKindOfClass:[UINavigationController class]]) {
        if ([((UINavigationController *)controller.presentedViewController).topViewController isKindOfClass:[MADDesignerElementPickerViewController class]]) {
            UINavigationController *navigationController = (UINavigationController *)controller.presentedViewController;
            if (navigationController.navigationItem.leftBarButtonItem == nil) {
                UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)];
                [navigationController.topViewController.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
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
    RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:cell.objectIdTag];
    return documentObject.type.shortValue;
}

- (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    [self deselectAllElementsAnimated:YES];
    self.lastMenuItemSelectRequiresElementView = true;
    [self selectElementView:(MADDesignerElementView *)[self viewForObjectID:cell.objectIdTag]];
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    NSManagedObjectID *elementViewId = cell.objectIdTag.copy;
    private.parentContext = self.document.managedObjectContext;
    
    [private performBlock:^{

        RptqDocumentObject *documentObject = [private objectWithID:elementViewId];
        RptqDocumentSection *section = documentObject.inSectionRow.inSection;
        MADDesignerSectionView *svSection = [self getSectionViewForDocumentSection:section];
        RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: svSection.objectIdTag inManagedObjectContext: private];
        BOOL found = NO;
        
        NSOrderedSet *documentSectionHasRows = documentSection.hasRows;
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
                        
                    case MTDocumentObjectTypeAggregate:
                        [self editDocumentObjectAggregateWithID: objectToEdit.objectID];
                        break;
                        
                    case MTDocumentObjectTypeBarcode:
                        [self editDocumentObjectBarcodeWithID: objectToEdit.objectID andBarcodeID:objectToEdit.isBarcode.objectID];
                        break;
                        
                    case MTDocumentObjectTypeImage:
                        [self editDocumentObjectImage:objectToEdit];
                        break;
                        
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

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        UIView *viewToEdit = [self viewForObjectID: objectID];
        UINavigationController *navigationController = [UINavigationController aggregateAdd];
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController = navigationController.viewControllers.firstObject;
        aggregateViewController.document = self.document;
        aggregateViewController.delegate = self;
        [aggregateViewController setAggregateObjectToEdit:self.aggregateToEdit];
        
        UIBarButtonItem *dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionCancel:)];
        [aggregateViewController.navigationItem setRightBarButtonItem:dismiss animated:NO];
        [aggregateViewController.navigationItem setLeftBarButtonItem:nil animated:NO];
        
        navigationController.modalPresentationStyle = UIModalPresentationPopover;
        navigationController.preferredContentSize = sizePopoverFonts();
        
        UIPopoverPresentationController *popoverController = navigationController.popoverPresentationController;
        popoverController.delegate = self;
        popoverController.sourceRect = [viewToEdit convertRect:viewToEdit.bounds toView:self.scroller.container];
        popoverController.sourceView = self.scroller.container;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self presentViewController:navigationController animated:YES completion:nil];
        [self setDisplayInactive];

    }];
    
}

- (void)editDocumentObjectBarcodeWithID:(NSManagedObjectID *)objectID andBarcodeID:(NSManagedObjectID *)barcodeID {
    
    self.barcodeToEditObjectID = barcodeID.copy;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIView *viewToEdit = [self viewForObjectID:objectID];

        MTViewControllerBarcode *barcodeViewController = [MTViewControllerBarcode main];
        barcodeViewController.document = self.document;
        barcodeViewController.delegate = self;
        barcodeViewController.preferredContentSize = sizePopoverFonts();
        barcodeViewController.modalPresentationStyle = UIModalPresentationPopover;
        barcodeViewController.bartcodeToEditObjectID = barcodeID;

        UIPopoverPresentationController *popoverController = barcodeViewController.popoverPresentationController;
        popoverController.delegate = self;
        popoverController.sourceRect = [viewToEdit convertRect: viewToEdit.bounds toView: self.scroller.container];
        popoverController.sourceView = self.scroller.container;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self presentViewController:barcodeViewController animated:YES completion:nil];
        [self setDisplayInactive];
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
    
    UIAlertController *alert = [UIAlertController editLabel:^(UITextField *textField) {
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

- (void)didUpdateBarcodeWithObjectID:(NSManagedObjectID *)barcodeObjectID barcodeObject:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo {
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller withField: (RptqQueryField *)field {

    RptqDocumentObject *documentObject = [field.managedObjectContext objectWithID:self.objectIdEditDynamicLabel];
    documentObject.isLabelDataField.referencesQueryField = field;
    [field.managedObjectContext save:nil];
    
}

#pragma mark -
#pragma mark MTReportDesignerSectionViewLayoutLiquidDelegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView: (MADDesignerSectionView *)collectionView cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADocument *document = self.document;
    MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[collectionView.objectIdTag];
    
    __block MADSectionLayoutAttributes *attributes;
    [layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *object, BOOL *stop) {
        if (object.indexPath.section == indexPath.section &&
            object.indexPath.row == indexPath.row) {
            attributes = object;
            *stop = YES;
        }
    }];
    

    RptqDocumentObject *documentObject = [document.managedObjectContext objectWithID:attributes.objectID];
    CGFloat contextScale = self.scroller.zoomScale * self.scroller.traitCollection.displayScale;
    NSString *resuseId = [MTCollectionViewCellElement reuseIdentifier];
    
    MTCollectionViewCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId forIndexPath:indexPath];
    cell.delegate = self;
    
    CGSize documentObjectSize = [documentObject size];
    CGRect cellFrame = CGRectMake(CGPointZero.x, CGPointZero.y, documentObjectSize.width, documentObjectSize.height);
    
    switch ([documentObject getType]) {
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
            
            UIGestureRecognizer *panGesture = [MADPanGestureRecognizer newPanGestureRecognizerElement:self action: @selector(handlePanPiece:) delegate:self];
            
            UIGestureRecognizer *pinchGesture = [MADPinchGestureRecognizer newPinchGestureRecognizerElement: self action: @selector(handlePinchPiece:) delegate:self];

            [self.scroller.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
            [self.scroller.pinchGestureRecognizer requireGestureRecognizerToFail:pinchGesture];
            
            [elementView addGestureRecognizer:panGesture];
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [cell setContentScaleFactor:contextScale];
                    [cell.contentView setContentScaleFactor:contextScale];
                    [elementView setContentScaleFactor:contextScale];
                });
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
    
    //MADDesignerElementView *elementView = [cell.contentView viewWithTag:(NSInteger)cell.objectIdTag.hash];
    NSSet <__kindof MADDesignerElementView *> *elementViewSet = [self.visibleElementViews objectsPassingTest:^BOOL(__kindof MADDesignerElementView * _Nonnull obj, BOOL * _Nonnull stop) {
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

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

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
    [self setLastElementViewToShowMenu:elementView];
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
    [self insertDocumentObjectWithDefination:
     @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
       MTDocumentObjectDefinationObject : field.objectID}];
    self.hidesStatusBar = false;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType inputType:(MTAggregateFunctionInputType)inputType inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType groupNumber:(NSNumber *)groupNumber {
    [self setDisplayActive];

    NSNumber *functionTypeNumber = @(functionType);
    NSNumber *groupTypeNumber = @(groupType);
    NSNumber *inputTypeNumber = @(inputType);
    NSNumber *objectType = @(MTDocumentObjectTypeAggregate);
    NSDictionary *documentObject = @{
                                     MTDocumentObjectDefinationAggregateType : functionTypeNumber,
                                     MTDocumentObjectDefinationAggregatePivotNumber : groupNumber,
                                     MTDocumentObjectDefinationAggregatePivotType : groupTypeNumber,
                                     MTDocumentObjectDefinationAggregateObjectId : inputObject,
                                     MTDocumentObjectDefinationAggregateFunctionInputType : inputTypeNumber
                                     };
    NSDictionary *documentObjectDefination = @{
                                               MTDocumentObjectDefinationType : objectType,
                                               MTDocumentObjectDefinationObject :  documentObject
                                               };
    
    [self insertDocumentObjectWithDefination: documentObjectDefination];
    self.hidesStatusBar = false;
}


- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
    [self setDisplayActive];
    NSNumber *type = @(MTDocumentObjectTypeLabelStatic);
    NSDictionary *defination = @{MTDocumentObjectDefinationType: type,
                                 MTDocumentObjectDefinationObject : labelText};
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    //Require the failure of the resize handles.
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)]) {
        return YES;
    } else {
        return  NO;
    }
}

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch: (UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
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

- (void)collectionView: (MADDesignerSectionView *)collectionView prepareLayout: (UICollectionViewLayout *)collectionViewLayout {
    MADocument *document = self.document;
    MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[collectionView.objectIdTag];
    NSManagedObjectContext *objectContext = document.managedObjectContext;
    for (MADSectionLayoutAttributes *attributes in layoutManager.items.allValues) {
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[objectContext objectWithID:attributes.objectID];
        documentObject.originx = @(attributes.frame.origin.x);
        documentObject.originy = @(attributes.frame.origin.y);
        //documentObject.sizewidth = @(attributes.frame.size.width);
        //documentObject.sizeheight = @(attributes.frame.size.height);
    }
    //[objectContext save:nil];
}

- (MADSectionLayoutAttributes *)collectionView: (MADDesignerSectionView *)collectionView layout: (UICollectionViewLayout *)collectionViewLayout layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[collectionView.objectIdTag];
    __block MADSectionLayoutAttributes *item;
    [layoutManager.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *object, BOOL *stop) {
        if (object.indexPath.item == indexPath.item && object.indexPath.section == indexPath.section) {
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
    return [layoutManager size];
}

#pragma mark - Gesture Recognizers
#pragma mark Gesture handlers

- (void)handlePinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    MADDesignerElementView *piece = ((MADDesignerElementView *)gestureRecognizer.view);
    RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:piece.objectIdTag];

    if (gestureRecognizer.numberOfTouches > 1) {

        CGPoint p1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
        CGPoint p2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
        MADCompusDirection direction = MADSpecificDirectionOfDegrees(CGAngleBetweenTwoPoints(p1, p2));
        struct MADResizeAspect resizeAspect = MADResizeTypeForDirection(direction);
        switch (resizeAspect.direction) {
            case horizontal:
                documentObject.sizewidth = @(documentObject.sizewidth.floatValue * gestureRecognizer.scale);
                break;
            case vertical:
                documentObject.sizeheight = @(documentObject.sizeheight.floatValue * gestureRecognizer.scale);
                break;
            default:
                documentObject.sizewidth = @(documentObject.sizewidth.floatValue * gestureRecognizer.scale);
                documentObject.sizeheight = @(documentObject.sizeheight.floatValue * gestureRecognizer.scale);
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
    if ([sender state] == UIGestureRecognizerStateEnded) {
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
            [self.viewControllerToolbox setSelectedObjectIds: self.selectedObjectIds];
            
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
    NSNumber *type = @(MTDocumentObjectTypeWhtiespace);
    NSDictionary *options = @{MTDocumentObjectDefinationType: type};
    [self insertDocumentObjectWithDefination: options];
    [self scrollToDetailSectionView];
}

- (void)saveDynamicLabel:(MTQueryBuilderChooseFieldViewController *)viewController {
    
    MTQueryBuilderChooseFieldViewController *dynamicFieldController = (MTQueryBuilderChooseFieldViewController *)viewController;
    RptqQueryField *queryField = [dynamicFieldController queryField];
    NSDictionary *definations = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
                                  MTDocumentObjectDefinationObject : queryField.objectID};
    [self insertDocumentObjectWithDefination: definations];
    
    [self scrollToDetailSectionView];
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
    if (self.aggregateToEdit && self.editAggregate) {
        if ([viewController fieldObject] != nil) {
            [self.aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
                                                                inputType: MTAggregateFunctionInputTypeField
                                                                groupType: viewController.aggregateGroupByType
                                                          aggregateObject: viewController.fieldObject
                                                              groupNumber: (NSUInteger)viewController.groupTypeSectionNumber];
        }
    } else {
        if ([viewController fieldObjectId] != nil) {
            NSNumber *groupNumber = @([viewController groupTypeSectionNumber]);
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
    
    if (self.objectIdEditBarcode  != nil) {
        
        MTBarcode *barcode = [viewController barcode];
        
        NSManagedObjectContext *managedObjectContext = [self.document managedObjectContext];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:self.objectIdEditBarcode];
        RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
        [barcodeObject updateWithBarcode: barcode fieldOne: viewController.queryField1 fieldTwo: viewController.queryField2];
        self.objectIdEditBarcode = nil;
        
    } else {
        
        NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
        defination[MTDocumentObjectDefinationType] = @(MTDocumentObjectTypeBarcode);
        defination[MTDocumentObjectDefinationObject] = [viewController barcode];
        
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
    if (self.toolboxTransitioningDelegate.presentationController.presentedViewController != nil &&
        [self.toolboxTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
        CGRect presentedRect = ((MADToolboxTransitioningDelegate *)self.toolboxTransitioningDelegate).presentationController.presentedViewController.view.frame;
        CGRect position = [self.scroller positionForRectOfInterest: [self rectForSelectedElements]
                                                 withPresentedRect: presentedRect containerSize:self.view.frame.size adjustment:self.topLayoutGuide.length];
        [self repositionSectionViews:position];
    }
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:(MADDesignerViewController *)reportDesigner {
    RptqQuery *query = self.document.activeDocumentModel.defaultDatabase.defaultQuery;
    RptqDocumentSection *documentSection = [query documentSectionForSelectedIndex: (NSUInteger)reportDesigner.lastSelectedSectionControlPanel];
    UIView *selectedSectionView = [reportDesigner getSectionViewForDocumentSection:documentSection];
    if (self.settingsTransitioningDelegate.presentationController.presentedViewController != nil &&
        [self.settingsTransitioningDelegate.presentationController isKindOfClass:[MADToolboxPresentationController class]]) {
        CGRect presentedRect = ((MADToolboxTransitioningDelegate *)self.settingsTransitioningDelegate).presentationController.presentedViewController.view.frame;
        CGRect position = [self.scroller positionForRectOfInterest: selectedSectionView.frame
                                                 withPresentedRect: presentedRect containerSize:self.view.frame.size adjustment:self.topLayoutGuide.length];
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
        
        [self.selectedObjectIds addObject: elementView.objectIdTag];
        [self applyBorderToView: elementView];
        
        self.viewControllerToolbox.document = self.document;
        self.viewControllerToolbox.selectedObjectIds = self.selectedObjectIds;
        
    }
}

- (void)deselectElementView:(MADDesignerElementView *)elementView animated:(BOOL)animated {
    
    [self removeBorderFromView: elementView];
    
    if (self.popoverToolbox.passthroughViews != nil) {

        NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray: self.popoverToolbox.passthroughViews];
        [passThroughViews removeObject: elementView];
        self.popoverToolbox.passthroughViews = passThroughViews.allObjects;

    }
}

- (RptqDocumentSection *)sectionForLabelTag:(NSInteger)tag {
    RptqDatabase *database = self.document.activeDocumentModel.hasDatabaseSchemas.anyObject;
    RptqQuery *query = database.hasQueries.anyObject;
    RptqDocumentSection *section = [query documentSectionForSelectedIndex:(NSUInteger)self.lastSelectedSectionControlPanel];
    return section;
}

- (void)redrawAllElementViewsInCollectionView:(UICollectionView *)collectionView {

    for (NSIndexPath *indexPath in collectionView.indexPathsForVisibleItems) {
        MADDesignerElementView *elementView = [self elementViewAtIndexPath: indexPath inCollectionView: collectionView];
        [elementView setNeedsDisplay];
    }

}

- (MADDesignerElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView {
    return [self elementViewForCollectionViewCell:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (MADDesignerElementView *)elementViewForCollectionViewCell:(UICollectionViewCell *)cell {

    MADDesignerElementView *result = nil;
    for (id elementView in [cell.contentView subviews]) {
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
    
    [detailSection performBatchUpdates:^{
        
        RptqDocumentObject *documentObject = [rptqDocument addDocumentObject:documentObjectDefination];
        [documentObject obtainPermanentID];
        
        NSIndexPath *path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count inSection: 0];
        MADSectionLayoutAttributes *la = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
        la.objectID = documentObject.objectID;
        self.objectIdJustDisplayed = la.objectID.copy;
        la.frame = CGRectMake(documentObject.originx.floatValue, documentObject.originy.floatValue, documentObject.size.width, documentObject.size.height);
        [layoutManager addItem:la];
        [layoutManager layout];
        
        NSArray *indexPathsInserted = @[path];
        [section addDocumentObject: documentObject withDropPoint: la.frame.origin managedObjectContext:section.managedObjectContext];
        
        [detailSection insertItemsAtIndexPaths: indexPathsInserted];
        [section.managedObjectContext save:nil];
        
    } completion:^(BOOL finished) {
        
        [self.scroller.container setNeedsUpdateConstraints];
        
    }];
}

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = cell.objectIdTag;
    
    MADocument *document = self.document;
    RptqDocumentObject *documentObject = [document.managedObjectContext objectWithID:objectId];
    
    MADDesignerSectionView *sectionView = [self getSectionViewForDocumentSection:documentObject.inSectionRow.inSection];
    MADSectionLayoutManager *layoutManager = document.sectionLayoutManagers[sectionView.objectIdTag];
    MADSectionLayoutAttributes *itemToRemove = [layoutManager.items objectForKey:objectId];
    
    [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
    
        MADocument *maDocument = self.document;
        [maDocument removeDocumentObjectWithObjectID: objectId managedObjectContext:maDocument.managedObjectContext];
    
    } animationComplete:^() {

        [self.scroller.container invalidateIntrinsicContentSize];
        [self.view setNeedsUpdateConstraints];

    } completion:^() {

        [self redrawAllElementViewsInCollectionView:sectionView];
        RptqDocumentObject *documentObjectFinished = [document.managedObjectContext objectWithID:objectId];
        [RptqDocument removeDocumentObject:documentObjectFinished fromManagedObjectContext:document.managedObjectContext];
        [document.managedObjectContext save:nil];

    }];
}

- (CGRect)rectForSelectedElements {
    NSSet *views = [self selectedElementViews];
    return [self.scroller.container popoverRectForSelectedViews:views];
}

- (UIView *)viewForObjectID:(NSManagedObjectID *)objectID { return [self.scroller.container viewWithTag: (NSInteger)objectID.hash]; }

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
        self.settingsTransitioningDelegate.passthroughContainers = self.passthroughContainers;
        self.settingsTransitioningDelegate.passthroughViews = [self passthroughViews];
        self.settingsTransitioningDelegate.passthroughContainer = self.scroller;
    } else if (self.toolboxVisible) {
        self.toolboxTransitioningDelegate.passthroughContainers = self.passthroughContainers;
        self.toolboxTransitioningDelegate.passthroughViews = [self passthroughViews];
        self.toolboxTransitioningDelegate.passthroughContainer = self.scroller;
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
    gestureRecognizer.view.center = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    [gestureRecognizer setTranslation:CGPointZero inView:self.view];
}

- (void)beginPanPiece:(MADManagedObjectView *)piece transition:(void (^)(void))transition completion:(void (^)(void))completion {
    
    [[UIMenuController sharedMenuController] setMenuVisible: NO animated: YES];
    
    if (self.presentedViewController != nil) {
        [self hideToolbox];
    }
    
    [self setScrollersEnabled: NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        piece.alpha = 0.80000f;
    }];
    [self.scroller.container bringSubviewToFront: piece];

    MADocument *doc = self.document;
    
    NSManagedObjectID *pieceObjectIDTag = piece.objectIdTag;
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = doc.managedObjectContext;
    [private performBlockAndWait:^{
        
        RptqDocumentObject *documentObject = [private objectWithID:pieceObjectIDTag];
        NSString *documentObjectSectionKey = [documentObject.inSectionRow.inSection copySectionKey];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            
            MADDesignerSectionView *sectionView = self.sectionViewsDictionary[documentObjectSectionKey];
            CGRect b = [self.view convertRect:piece.frame fromView:sectionView];
            piece.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, b.size.width, b.size.height);
            [self.view addSubview: piece];
            [UIView animateWithDuration:0.2 animations:^{
                piece.alpha = 0.80000f;
            }];
            
            transition();
            
            
            MADSectionLayoutManager *layoutManager = doc.sectionLayoutManagers[sectionView.objectIdTag];
            MADSectionLayoutAttributes *itemToRemove = [layoutManager.items objectForKey: pieceObjectIDTag];
            
            [sectionView removeItemAtIndex:itemToRemove.indexPath update:^{
            
                MADocument *document = self.document;
                NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
                [document removeDocumentObjectWithObjectID: pieceObjectIDTag managedObjectContext:managedObjectContext];
                
            } animationComplete:^() {

                    [self.scroller.container invalidateIntrinsicContentSize];
                    [self.view setNeedsUpdateConstraints];

            } completion:^() {

                    [self redrawAllElementViewsInCollectionView:sectionView];
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
                CGPoint p2 = [self.scroller.container convertPoint:view.frame.origin toView:self.view];
                if ((distance = MADDistance(p1, p2)) < minDistance) {
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
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        private.parentContext = self.document.managedObjectContext;
        [private performBlockAndWait:^{

            RptqDocumentSection *documentSection = [private objectRegisteredForID:sectionViewObjectIdTag];
            NSString *documentSectionKey = [documentSection copySectionKey];
            CGFloat documentSectionHeight = documentSection.height.floatValue;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
                NSLayoutConstraint *layoutConstraint = self.layoutConstraintsReportSectionHeight[documentSectionKey];
                layoutConstraint.constant = documentSectionHeight;
                [self.view setNeedsUpdateConstraints];
                
                MADSectionLayoutManager *layoutManager = self.document.sectionLayoutManagers[sectionViewObjectIdTag];
                NSIndexPath *path = [NSIndexPath indexPathForItem: (NSInteger)layoutManager.items.count inSection: 0];
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
                    
                    [documentSectionBlock addDocumentObject: documentObject withDropPoint: locationInSection managedObjectContext:managedObjectContext];
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
    
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    private.parentContext = self.document.managedObjectContext;
    
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    __block NSString *key = nil;
    __block CGFloat height;

    [private performBlockAndWait:^{
        RptqDocumentSection *documentSection;
        documentSection = [RptqDocumentSection documentSectionForObjectID: objectId
                                                   inManagedObjectContext: private];
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
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.tabBarController enableTabBarItems];
}

- (void)setDisplayInactive {
    self.tabBarController.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [self.tabBarController disableTabBarItems];
}

- (void)setScrollersEnabled:(BOOL)enabled {
    @synchronized(self.scroller) {
        if ([self.scroller respondsToSelector:@selector(setScrollEnabled:)]) {
            self.scroller.scrollEnabled = enabled;
            [self.scroller flashScrollIndicators];
            for (UICollectionView *collectionView in [self.scroller.container subviews]) {
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
        
        if ([self popoverControllerObjectSelector] != nil) [allpopovers addObject:[self popoverControllerObjectSelector]];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if ([popoverController isPopoverVisible]) {
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
    
    RptqDocumentSectionEnumerator *sectionEnumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:self.document.activeDocumentModel];
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    for (RptqDocumentSection *documentSection in sectionEnumerator) {
        MADDesignerSectionView *documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier.integerValue];

        for (NSInteger section = 0; section < documentSectionView.numberOfSections; section++) {
        
            NSInteger numberOfItemsInSection = [documentSectionView numberOfItemsInSection:section];
            
            for (NSInteger item = 0; item < numberOfItemsInSection; item++) {
                
                NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:section];
                MADDesignerElementView *elementView = [self elementViewAtIndexPath: path inCollectionView: documentSectionView];
                if (elementView != nil) {
                    [results addObject:elementView];
                }
            }
            
        }
    }
    return results;
}

- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifer {
    MADDesignerSectionView *documentSectionView = nil;
    NSArray<__kindof UIView *> *subviews = self.scroller.container.subviews;
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
                MADDesignerSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]];
                
                for (NSInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
                    for (NSInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                        MADDesignerElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:documentSectionView];
                        if ([self.selectedObjectIds containsObject: [elementView objectIdTag]]) {
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
    NSString *sectionKey = [documentSection copySectionKey];
    return self.sectionViewsDictionary[sectionKey];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    NSString *sectionKey = [documentSection copySectionKey];
    return self.sectionControlViewsDictionary[sectionKey];
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
    
    //Remove border from element views
    for (MADDesignerElementView *elementView in [self selectedElementViews]) {
        [self deselectElementView:elementView animated:animated];
    }
    
    [self.selectedObjectIds removeAllObjects];
    [self.viewControllerToolbox setSelectedObjectIds:self.selectedObjectIds];
    
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
    [self.sectionControlViewsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionLabel *view, BOOL *stop) {
        [view normalView];
    }];
    
    //Remove border from the section views
    [self.sectionViewsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionView *view, BOOL *stop) {
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
    NSNumber *key = @(view.tag);
    return [self.borderAppliedToView[key] boolValue];
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
    NSArray<__kindof NSLayoutConstraint *> *constraints = self.scroller.container.constraints;
    if (constraints.count > 0) {
        [self.scroller.container removeConstraints:constraints];
    }
}

- (void)scrollerRemoveAllConstraints {
    NSArray<__kindof NSLayoutConstraint *> *constraints = self.scroller.constraints;
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
    
    CGFloat height = (self.sectionViewsArray.count * MTReportDesignerBufferPaddingVertical) + (2 * MTReportDesignerBorderPaddingVertical) + self.ruler.intrinsicContentSize.height;
    for (UIView *subview in self.sectionViewsArray) {
        height += subview.frame.size.height <= CGSizeZero.height ?
        ceil(subview.intrinsicContentSize.height) :
        [subview frame].size.height;
    }
    return CGSizeMake(self.view.bounds.size.width, height);
}

- (bool)showOnSide {
    return self.presentingViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
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
    return (UIView *)[self.sectionControlViewsDictionary objectForKey:[self.document.activeDocumentModel.hasDetailSection.objectID copyKey]];
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
    [collectionView setObjectIdTag: section.objectID];
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
