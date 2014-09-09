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

#import "MTReportDesignerViewController.h"
#include <math.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MTReportDesigner.h"
#import "MTSettingsViewController.h"
#import "MTReportDesignerObjectSelectorViewController.h"
#import "MTReportViewerController.h"
#import "MTCollectionViewCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTElementView.h"
#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "MTReportDesignerToolBoxViewController.h"
#import "MTRulerView.h"
#import "MTDocumentSectionView.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "NSManagedObject+Extras.h"
#import "DesignerSectionLabel.h"
#import "MTViewControllerBarcode.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTCollectionViewLayoutLiquidAttributes.h"
#import "MTLog.h"
#import "UIColor+EverydayApps.h"
#import "UIView+NSObjectIdTag.h"
#import "CGGeometry+Extras.h"
#import "UIDevice+Hack.h"
#import "SectionEnumerator.h"
#import "MTFont.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryField.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentObjectLabel.h"

#import "RptqDocumentObjectLabelDataField.h"

#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectBarcode+Extras.h"

#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectImage+Extras.h"


#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"

#import "Constants.h"

#import "UIViewController+ui.h"
#import "UIViewController+tabBarItem.h"
#import "UIScrollView+Extras.h"

#import "NSManagedObjectID+Extras.h"

#import "UIView+Extras.h"

#import "MADViewDetailSmall.h"

#import "MADPromptManager.h"

NSString * const MTSegueNewDocumentObjectStaticLabelSaveIdentifer   = @"MTSegueNewDocumentObjectStaticLabelSaveIdentifer";
NSString * const MTSegueNewDocumentObjectDynamicLabelSaveIdentifer  = @"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer";
NSString * const MTSegueChooseWhitespaceSaveIdentifer               = @"MTSegueChooseWhitespaceSaveIdentifer";
NSString * const MTSegueChooseImageSaveIdentifer                    = @"MTSegueChooseImageSaveIdentifer";

const CGFloat MADSizeWidthViewDetailDisplay         = 32.0000f;
const CGFloat MADSizeHeightViewDetailDisplay        = 20.0000f;
//const CGFloat MADSizeWidthViewDetailDisplay

const CGFloat MTReportDesignerRulerHeight           = 20.0000f;
const CGFloat MTReportDesignerSectionLabelHeight    = 20.0000f;
const CGFloat MTReportDesignerBorderPaddingSides    =  8.0000f;
const CGFloat MTReportDesignerBorderPaddingDetail   =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingVertical =  3.0000f;
const CGFloat MTReportDesignerBufferPaddingVertical =  2.0000f;
const CGFloat MTReportDesignerCornerRadius          =  3.0000f;
const CGFloat previousScaleWeight                   =  0.6666f;

const CGFloat MADSizeWidthSectionLabel              = 0.2000f;

const CGFloat MTReportDesignerToolboxHeight         = 250.0000f;

@interface MTReportDesignerViewController()
    <MTViewControllerBarcodeDelegate,
        MTViewControllerAggregateDelegate,
        MTReportDesignerToolBoxDelegate,
        MTElementViewDelegate,
        MTCollectionViewCellElementDelegate,
        MTReportDesignerSectionViewLayoutLiquidDelegate,
        MTReportDesignerObjectSelectorDelegate,
        MTViewControllerProtocol,
        MTDocumentSectionViewDelegate,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderChooseFieldDelegate,
        MTTabBarImageProtocol, DesignerSectionLabelDelegate,
        UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        UINavigationControllerDelegate,
        UIScrollViewDelegate,
        UIImagePickerControllerDelegate,
        UITabBarControllerDelegate,
        UITextFieldDelegate>

@property (nonatomic, strong) NSNumberFormatter *numberFormatterPercentage;

@property (nonatomic, strong) MTRulerView *ruler;
@property (nonatomic, weak) IBOutlet UIView *toolbox;                               //iPhone only
@property (nonatomic, weak) IBOutlet UIScrollView *scroller;
@property (nonatomic, weak) IBOutlet UIView *container;

@property (nonatomic, assign) BOOL editAggregate;
@property (nonatomic, assign) BOOL editDynamicField;

@property (nonatomic, strong) NSArray *sectionViewsArray;
@property (nonatomic, strong) NSArray *sectionControlViewsArray;

@property (nonatomic, strong) NSArray *viewDidAppearDesignerScrollViewConstraints;  //These are removed on disapear
@property (nonatomic, strong) NSArray *viewDidAppearDesignerContentViewConstraints; //These are removed on disapear
@property (nonatomic, strong) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, strong) NSArray *layoutConstraintsToolboxHidden;

@property (nonatomic, strong) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, strong) UINavigationController *navigationControllerSectionLayoutSettings;
@property (nonatomic, strong) MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings;

@property (nonatomic, assign) NSUInteger lastSelectedSectionControlPanel;

@property (nonatomic, strong) UIPopoverController *popoverControllerInformation;
@property (nonatomic, strong) UIPopoverController *popoverControllerObjectSelector;
@property (nonatomic, strong) UIPopoverController *popoverControllerSectionSettings;
@property (nonatomic, strong) UIPopoverController *popoverControllerEditBarcode;
@property (nonatomic, strong) UIPopoverController *popoverControllerEditDataLabel;
@property (nonatomic, strong) UIPopoverController *popoverControllerEditAggregate;

@property (nonatomic, strong) MTElementView *lastElementViewToShowMenu;

@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerWidth;
@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintToolbarHeight;
@property (nonatomic, strong) NSMutableDictionary *layoutConstraintsReportSectionHeight;

@property (nonatomic, strong) NSMutableArray *layoutConstraintSectionLabelHeightContainer;
@property (nonatomic, strong) NSMutableArray *layoutConstraintSectionLabelWidthContainer;
@property (nonatomic, strong) NSMutableArray *layoutConstraintSectionLabelWidthContainer2;
@property (nonatomic, strong) NSMutableArray *layoutConstraintsSectionsSidesBorder;
@property (nonatomic, strong) NSMutableArray *layoutConstraintsSectionsVerticalBuffer;

@property (nonatomic, strong) NSMutableDictionary *sectionViews;
@property (nonatomic, strong) NSMutableDictionary *sectionControlViews;

@property (nonatomic, strong) NSMutableDictionary *borderAppliedToView;

@property (nonatomic, strong) NSArray *toolbarBottomItems;

@property (nonatomic, strong) NSMutableDictionary *collectionViewReuseIdentifiers;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbarBottom;                          //iPhone only
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonAddReportObject;

@property (nonatomic, strong) NSMutableSet *selectedObjectIds;

@property (nonatomic, strong) MTDocumentSectionView *reportFooterView;

@property (nonatomic, assign) CGPoint pinchInitalPointA;
@property (nonatomic, assign) CGPoint pinchInitalPointB;
@property (nonatomic, assign) CGAffineTransform pinchBeginTransform;

@property (nonatomic, assign) CGPoint currentNewPointA;
@property (nonatomic, assign) CGPoint currentNewPointB;
@property (nonatomic, assign) CGSize currentScaleSize;

@property (nonatomic, assign) BOOL toolboxVisible;

@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithToolbar;
@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithoutToolbar;

@property (nonatomic, assign) BOOL insetsSetup;

@property (nonatomic, strong) UIAlertView *alertViewEdit;

@property (nonatomic, strong) NSManagedObjectID *objectIdEditStaticLabel;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditDynamicLabel;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditAggregateFunction;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditBarcode;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditImage;

@property (nonatomic, strong) NSArray *availableZoomScales;

@property (nonatomic, strong) NSManagedObjectID *objectIdJustDisplayed;

@property (nonatomic, strong) RptqDocumentObjectBarcode *barcodeToEdit;
@property (nonatomic, strong) RptqDocumentObjectAggregate *aggregateToEdit;

@property (nonatomic, assign) BOOL lastMenuItemSelectRequiresElementView;

@property (nonatomic, weak) UINavigationBar *navigationBar;

@property (nonatomic, assign) CGFloat zoomScaleRestore;
@property (nonatomic, assign) CGRect boundsOnDisappear;
@property (nonatomic, assign) BOOL shownAndHidden;
@property (nonatomic, assign) BOOL toolboxIsVisible;
@property (nonatomic, assign) CGPoint contentOffsetOnShowToolbox;

@property (nonatomic, strong) MADViewDetailSmall *detailDisplayView;

@property (nonatomic, strong) UIFont *captionFont;

//@property (nonatomic, strong) NSMutableArray *promptItems;
@property (nonatomic, strong) MADPromptManager *promptManager;

@end

@implementation MTReportDesignerViewController

#pragma mark - Exit

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action {
    
    if ([[action identifier] isEqualToString:MTSegueNewDocumentObjectStaticLabelSaveIdentifer]) {
        [self saveStaticLabel:action.sourceViewController];

    } else if ([[action identifier] isEqualToString:MTSegueChooseWhitespaceSaveIdentifer]) {
        [self saveWhiteSpace];
    
    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
        [self tableViewControllerChooseFieldDidFinish:[action sourceViewController] withField:[[action sourceViewController] queryField]];
    
    } else if ([[action identifier] isEqualToString:MTSegueNewDocumentObjectDynamicLabelSaveIdentifer]) {
        [self saveDynamicLabel: action.sourceViewController];
    
    } else if ([[action identifier] isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {
        [self saveAggregateLabel: action.sourceViewController];
    
    } else if ([[action identifier] isEqualToString:@"MTSegueNewDocumentObjectBarcodeSaveIdentifer"]) {
        [self saveBarcodeLabel: action.sourceViewController];
        
    } else if ([[action identifier] isEqualToString:MTSegueChooseImageSaveIdentifer]) {
        //Intentionally blank
        
    }
    [self setDisplayActive];
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToDesigner:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToDesigner:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

#pragma mark - NSObject

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark - UIViewController

- (NSString *)title {
    return NSLocalizedString(@"MAD Designer", "MAD Designer");
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADPromptManager *promptManager = [[MADPromptManager alloc] init];
    self.promptManager = promptManager;
    
    UIFont *captionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.captionFont = captionFont;
    
    NSMutableArray *layoutConstraintSectionLabelHeightContainer = [[NSMutableArray alloc] init];
    self.layoutConstraintSectionLabelHeightContainer = layoutConstraintSectionLabelHeightContainer;
    
    NSMutableArray *layoutConstraintSectionLabelContainer = [[NSMutableArray alloc] init];
    self.layoutConstraintSectionLabelWidthContainer = layoutConstraintSectionLabelContainer;
    
    NSMutableArray *layoutConstraintSectionLabelWidthContainer2 = [[NSMutableArray alloc] init];
    self.layoutConstraintSectionLabelWidthContainer2 = layoutConstraintSectionLabelWidthContainer2;
    
    NSMutableArray *layoutConstraintsSectionsSidesBorder = [[NSMutableArray alloc] init];
    self.layoutConstraintsSectionsSidesBorder = layoutConstraintsSectionsSidesBorder;
    
    NSMutableArray *layoutConstraintsSectionsVerticalBuffer = [[NSMutableArray alloc] init];
    self.layoutConstraintsSectionsVerticalBuffer = layoutConstraintsSectionsVerticalBuffer;
    
    MADViewDetailSmall *detailDisplay = [[MADViewDetailSmall alloc] initWithFrame: [self detailDisplayFrame]];
    self.detailDisplayView = detailDisplay;

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
    self.numberFormatterPercentage = numberFormatter;
    
    if ([UIDevice isModernOS]) {
        self.toolbox.backgroundColor = [UIColor clearColor];
    }
    
    MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
    self.ruler = viewRuler;
    
    self.boundsOnDisappear = CGRectZero;
    self.zoomScaleRestore = -1.0000f;
    self.shownAndHidden = NO;
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    self.borderAppliedToView = d;
    
    NSArray *viewDidAppearDesignerScrollViewConstraints = [[NSArray alloc] init];
    self.viewDidAppearDesignerScrollViewConstraints = viewDidAppearDesignerScrollViewConstraints;
    
    NSArray *viewDidAppearDesignerContentViewConstraints = [[NSArray alloc] init];
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    
    self.editAggregate = NO;
    
    self.tabBarController.delegate = self;
    
    self.insetsSetup = NO;
    self.toolboxVisible = NO;
    
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    labelMadDesigner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    labelMadDesigner.attributedText = [MTApplicationInstance localizedAttributedApplicationNameMadDesigner];
    self.navigationItem.titleView = labelMadDesigner;
    [self.navigationItem.titleView sizeToFit];
    
    [self contentViewRemoveAllConstraints];
    [self scrollerRemoveAllConstraints];
    
    UITapGestureRecognizer *tapGestureDoubleTap = [MTReportDesignerViewController tapGestureRecognizerDouble:self];
    tapGestureDoubleTap.delegate =  self;
    
    UITapGestureRecognizer *tapGestureSingleTap = [MTReportDesignerViewController tapGestureRecognizerSingle:self];
    tapGestureSingleTap.delegate =  self;
    [tapGestureSingleTap requireGestureRecognizerToFail:tapGestureDoubleTap];

    [self.scroller addGestureRecognizer:tapGestureDoubleTap];
    [self.scroller addGestureRecognizer:tapGestureSingleTap];
    self.scroller.bouncesZoom = YES;
    self.scroller.scrollsToTop = YES;
    self.scroller.translatesAutoresizingMaskIntoConstraints = NO;
    self.scroller.scrollEnabled = YES;
    self.scroller.maximumZoomScale = 4.0000f;
    self.scroller.minimumZoomScale = 0.3000f;
    self.scroller.delegate = self;
    self.scroller.userInteractionEnabled = YES;
    self.scroller.backgroundColor = [MTReportDesignerViewController designerBackgroundColor];
    self.scroller.indicatorStyle = UIScrollViewIndicatorStyleDefault;

    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    NSLayoutConstraint *constraintContentLeft = [self layoutConstraintViewContentLeft];
    [constraints addObject:constraintContentLeft];
    
    NSLayoutConstraint *constraintContentRight = [self layoutConstraintViewContentRight];
    [constraints addObject:constraintContentRight];

    NSLayoutConstraint *constraintContentTop = [self layoutConstraintViewContentTop];
    [constraints addObject:constraintContentTop];

    NSLayoutConstraint *constraintScrollerBottom = [self layoutConstraintViewScrollerBottom];
    [constraints addObject:constraintScrollerBottom];
    
    if ([UIDevice isModernOS]) {
        NSLayoutConstraint *constraintWidth = [self layoutConstraintContentWidthCalculated];
        [constraints addObject:constraintWidth];
        self.layoutConstraintContainerWidth = constraintWidth;
    }
    
    MTReportDesignerToolBoxViewController *viewControllerToolbox = [MTReportDesignerViewController toolbox];
    viewControllerToolbox.delegate = self;
    viewControllerToolbox.document = self.document;
    self.viewControllerToolbox = viewControllerToolbox;
    
    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [MTReportDesignerViewController toolboxSettings];
    viewControllerSectionLayoutSettings.delegate = self;
    viewControllerSectionLayoutSettings.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.viewControllerSectionLayoutSettings = viewControllerSectionLayoutSettings;
    
    UINavigationController *navigationController = [MTReportDesignerViewController navigationControllerSectionLayoutSettings:self.viewControllerSectionLayoutSettings];
    self.navigationControllerSectionLayoutSettings = navigationController;
    
    self.navigationController.navigationBar.barTintColor = [UIColor tintColorBlue];
    self.navigationController.navigationBar.tintColor = [UIColor tintColorWhite];

    if ([UIDevice isPad] == NO) {
        UIBarButtonItem *buttonDone = [MTReportDesignerViewController buttonDone:self];
        [self.viewControllerSectionLayoutSettings.navigationItem setRightBarButtonItem: buttonDone
                                                                              animated: NO];

        NSLayoutConstraint *layoutConstraintToolboxHeight = [self layoutConstraintToolBoxViewHeight];
        self.layoutConstraintsToolboxVisiable =  @[layoutConstraintToolboxHeight];
        
        NSLayoutConstraint *layoutConstraintViewToolbarHeightHidden = [self layoutConstraintViewToolbarHeightHidden];
        layoutConstraintViewToolbarHeightHidden.constant = [self toolbarBottomHeight];
        [constraints addObject: layoutConstraintViewToolbarHeightHidden];
        
        
        NSLayoutConstraint *layoutConstraintToolboxHeightHidden = [self layoutConstraintToolboxHeightHidden];
        [constraints addObject: layoutConstraintToolboxHeightHidden];
        
        NSLayoutConstraint *layoutConstraintToolBoxViewBottom = [self layoutConstraintToolBoxViewBottom];
        [constraints addObject:layoutConstraintToolBoxViewBottom];
        
        NSLayoutConstraint *layoutConstraintViewScrollerTop = [self layoutConstraintViewScrollerTop];
        [constraints addObject: layoutConstraintViewScrollerTop];

        NSLayoutConstraint *layoutConstraintToolbarBottomToToolboxView = [self layoutConstraintToolbarBottomToToolboxView];
        [constraints addObject: layoutConstraintToolbarBottomToToolboxView];

        NSArray *layoutConstraintsToolboxHidden = @[layoutConstraintToolboxHeightHidden, constraintScrollerBottom];
        self.layoutConstraintsToolboxHidden = layoutConstraintsToolboxHidden;
        self.layoutConstraintToolbarHeight = layoutConstraintViewToolbarHeightHidden;
        
    } else {
        [self setupPopoverControllers];
    }
    
    NSMutableSet *selectedObjectIds = [NSMutableSet new];
    self.selectedObjectIds = selectedObjectIds;
    
    NSArray *toolbarBottomItems = [self.toolbarBottom items];
    self.toolbarBottomItems = toolbarBottomItems;
    
    self.toolboxIsVisible = NO;
    
    NSNumber *zoomScale1 = @(0.5000f);
    NSNumber *zoomScale2 = @(0.7500f);
    NSNumber *zoomScale3 = @(1.0000f);
    NSNumber *zoomScale4 = @(2.0000f);
    NSNumber *zoomScale5 = @(3.0000f);
    NSArray *availableZoomScales = @[zoomScale1,
                                     zoomScale2,
                                     zoomScale3,
                                     zoomScale4,
                                     zoomScale5];
    self.availableZoomScales = availableZoomScales;
    
    [self.view addConstraints:constraints];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    NSMutableArray *constraintsScroller = [NSMutableArray new];
    NSMutableArray *constraintsContainer = [NSMutableArray new];
    
    [self addObservers];

    self.lastMenuItemSelectRequiresElementView = NO;
    self.zoomScaleRestore = self.scroller.zoomScale;
    [self.scroller setZoomScale: 1.0000f animated:NO];
    
    RptqDocument *document = [self.document activeDocumentModel];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    
    NSInteger sectionCounter = 0;
    NSInteger numberOfSections = [sectionEnumerator count];
    
    NSMutableDictionary *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setLayoutConstraintsReportSectionHeight:layoutConstraintsReportSectionHeight];
    
    NSMutableDictionary *dictionarySections = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionViews: dictionarySections];
    
    NSMutableDictionary *dictionarySectionControls = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionControlViews:dictionarySectionControls];
    
    NSMutableDictionary *collectionViewReuseIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setCollectionViewReuseIdentifiers:collectionViewReuseIdentifiers];
    
    [self.container addSubview:self.ruler];
    
    [self.view addSubview:self.detailDisplayView];
    [self updateDisplayDetailZoomValue];
    
    NSMutableArray *viewDidAppearDesignerScrollViewConstraints = [[NSMutableArray alloc] init];
    NSMutableArray *viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] init];
    
    NSArray *rulerConstraints = [MTReportDesignerViewController layoutConstraintsRuler:self.ruler
                                                                            inDesigner:self.container];
    NSArray *rulerSideConstraints = [MTReportDesignerViewController layoutConstraintsRulerSide:self.ruler
                                                                                    inDesigner:self.container];
    
    [self.layoutConstraintsSectionsSidesBorder addObjectsFromArray:rulerSideConstraints];
    
    [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:rulerConstraints];
    [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:rulerSideConstraints];
    [constraintsScroller addObjectsFromArray:rulerConstraints];
    [constraintsScroller addObjectsFromArray:rulerSideConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    NSMutableArray *reportSectionKeyTracker = [[NSMutableArray alloc] init];
    NSMutableArray *sectionControlViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray *sectionViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    CGFloat borderWidthThin = [self.view borderWidthThin];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        @autoreleasepool {
            
            sectionHeights += (MTReportDesignerBufferPaddingVertical + reportSection.height.floatValue);

            MTDocumentSectionView *sectionView = [MTReportDesignerViewController documentSectionView: reportSection
                                                                                            delegate: self];
            sectionView.delegate = self;
            sectionView.sectionDelegate = self;
            sectionView.dataSource = self;
            sectionView.layer.borderWidth = borderWidthThin;
            
            DesignerSectionLabel *sectionViewLabel = [[DesignerSectionLabel alloc] initWithSection:reportSection];
            
            sectionViewLabel.delegate = self;
            sectionViewLabel.tag = sectionCounter;
            
            NSString *documentElementReuseIdentifier = [MTReportDesignerViewController reuseIdentifierSection:reportSection.identifier.integerValue];
            self.collectionViewReuseIdentifiers[reportSection.identifier] = documentElementReuseIdentifier;
            
            
            
            NSString *lastKey = [reportSectionKeyTracker lastObject];
            id constraintItem =  sectionCounter == 0 ? self.ruler :
            self.sectionViews[lastKey];
            
            sectionView.showsVerticalScrollIndicator = YES;
            
            NSLayoutConstraint *lc1a = [MTReportDesignerViewController layoutConstraintSection: sectionView
                                                                                  toItemBottom: constraintItem];
            [self.layoutConstraintsSectionsVerticalBuffer addObject:lc1a];
            [constraintsContainer addObject:lc1a];
            [viewDidAppearDesignerContentViewConstraints addObject:lc1a];
            
            NSLayoutConstraint *lc1b = [MTReportDesignerViewController layoutConstraintSection: sectionView
                                                                                      toHeight: reportSection.height.floatValue];
            NSManagedObjectID *objectId = [sectionView objectIdTag];
            NSString *key = [objectId key];
            self.layoutConstraintsReportSectionHeight[key] = lc1b;
            
            [constraintsContainer addObject:lc1b];
            [viewDidAppearDesignerContentViewConstraints addObject:lc1b];

            NSLayoutConstraint *lc1c = [MTReportDesignerViewController layoutConstraintSection: sectionView
                                                                                  toLabelRight: sectionViewLabel];
            [constraintsContainer addObject:lc1c];
            [viewDidAppearDesignerContentViewConstraints addObject:lc1c];
            
            NSLayoutConstraint *lc1d = [MTReportDesignerViewController layoutConstraintSection: sectionView
                                                                                 toLabelBottom: sectionViewLabel];
            [constraintsContainer addObject:lc1d];
            [viewDidAppearDesignerContentViewConstraints addObject:lc1d];
            
            NSLayoutConstraint *lc1e = [MTReportDesignerViewController layoutConstraintLabel: sectionViewLabel
                                                                                    toHeight: MTReportDesignerSectionLabelHeight];
            [self.layoutConstraintSectionLabelHeightContainer addObject:lc1e];
            [constraintsContainer addObject:lc1e];
            [viewDidAppearDesignerContentViewConstraints addObject:lc1e];
            
            NSArray *collectionViewConstraints = [MTReportDesignerViewController layoutConstraintsForSection: sectionView
                                                                                                     content: self.container];
            [constraintsScroller addObjectsFromArray:collectionViewConstraints];
            [self.layoutConstraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];
            
            [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:collectionViewConstraints];
            
            if (reportSection.type.integerValue == MNSDocumentSectionTypeReportFooter) {
                [self setReportFooterView:sectionView];
            }
            
            [sectionViewsArray addObject:sectionView];
            [sectionControlViewsArray addObject:sectionViewLabel];
            
            NSString *collectionViewKey = [reportSection sectionKey];
            [self.sectionViews setValue:sectionView forKey:collectionViewKey];
            [self.sectionControlViews setValue:sectionViewLabel forKey:collectionViewKey];
            
            [reportSectionKeyTracker addObject:collectionViewKey];
            
            sectionCounter++;
            
            [self.container addSubview:sectionView];
            [self.container addSubview:sectionViewLabel];
        }
    }
    
    self.sectionViewsArray = sectionViewsArray;
    self.sectionControlViewsArray = sectionControlViewsArray;
    
    sectionHeights += MTReportDesignerBorderPaddingVertical;

    self.container.backgroundColor = [UIColor clearColor];
    self.container.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *layoutConstraintDesignerContentViewHeight = [MTReportDesignerViewController layoutConstraintViewContent: self.container
                                                                                                                         height: sectionHeights];
    [constraintsScroller addObject:layoutConstraintDesignerContentViewHeight];
    [viewDidAppearDesignerScrollViewConstraints addObject:layoutConstraintDesignerContentViewHeight];
    self.layoutConstraintDesignerContentViewHeight = layoutConstraintDesignerContentViewHeight;

    
    NSLayoutConstraint *layoutConstraintContentToScollerBottom = [MTReportDesignerViewController layoutConstraintViewContent: self.container
                                                                                                            toScrollerBottom: self.scroller];

    [constraintsScroller addObject:layoutConstraintContentToScollerBottom];
    [viewDidAppearDesignerScrollViewConstraints addObject:layoutConstraintContentToScollerBottom];
    
    self.viewDidAppearDesignerScrollViewConstraints = viewDidAppearDesignerScrollViewConstraints;
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    
    [self enableTabBarItems];
    
    [self.scroller addConstraints: constraintsScroller];
    [self.container addConstraints: constraintsContainer];
    self.scroller.backgroundColor = [UIColor tintColorRed];
    self.view.backgroundColor = [UIColor tintColorRed];
    
}

- (NSLayoutConstraint *)layoutConstraintContentWidthCalculated {
    return [NSLayoutConstraint constraintWithItem: self.container
                                        attribute: NSLayoutAttributeWidth
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: self.view.frame.size.width / self.scroller.zoomScale];
}

- (NSLayoutConstraint *)layoutConstraintContentCenterX {
    return [NSLayoutConstraint constraintWithItem: self.container
                                        attribute: NSLayoutAttributeCenterX
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.scroller.viewForBaselineLayout
                                        attribute: NSLayoutAttributeCenterX
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (CGRect)detailDisplayFrame {
    return CGRectMake(self.view.frame.size.width - MADSizeWidthViewDetailDisplay - MTReportDesignerBorderPaddingDetail,
                      CGPointZero.y + self.topLayoutGuide.length + MTReportDesignerBorderPaddingDetail,
                      MADSizeWidthViewDetailDisplay, MADSizeHeightViewDetailDisplay);
}

- (UIEdgeInsets)desiredEdgeInsets {
    return UIEdgeInsetsMake(self.topLayoutGuide.length,
                            CGSizeZero.width,
                            self.toolboxVisible ? CGSizeZero.height : self.tabBarController.tabBar.frame.size.height,
                            CGSizeZero.height);
}

- (CGFloat)toolboxHeightCalculated {
    return MIN(self.view.frame.size.height / 2.0000f, MTReportDesignerToolboxHeight);
}

- (UIEdgeInsets)desiredScrollInsets {
    return UIEdgeInsetsMake(self.topLayoutGuide.length,
                            CGSizeZero.width,
                            self.toolboxVisible ? CGSizeZero.height + [self toolboxHeightCalculated]:
                                                  CGSizeZero.height + self.tabBarController.tabBar.frame.size.height,
                            CGSizeZero.width);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self insetsSetup] == NO) {
        self.edgeInsetsWithToolbar = self.scroller.contentInset;
        self.edgeInsetsWithoutToolbar = UIEdgeInsetsMake(self.edgeInsetsWithToolbar.top,
                                                         self.edgeInsetsWithToolbar.left,
                                                         CGSizeZero.height,
                                                         self.edgeInsetsWithToolbar.right);
        self.insetsSetup = YES;
    }
    
    [self setScrollersEnabled:YES];
    
    if (self.shownAndHidden && self.zoomScaleRestore > 1.0001) {
        [self.scroller setZoomScale:self.zoomScaleRestore animated:NO];
        [self scrollViewDidEndZooming:nil withView:nil atScale: self.scroller.zoomScale];
        [self.scroller scrollRectToVisible:self.boundsOnDisappear animated:NO];
    }
    
    [self.scroller flashScrollIndicators];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.boundsOnDisappear = self.scroller.bounds;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeObservers];
    
    [self.ruler removeFromSuperview];
    for (UIView *view in [self sectionViewsArray]) {
        [view removeFromSuperview];
    }
    for (UIView *view in [self sectionControlViewsArray]) {
        [view removeFromSuperview];
    }
    
    [self.scroller removeConstraints:self.viewDidAppearDesignerScrollViewConstraints];
    [self.scroller removeConstraints:self.viewDidAppearDesignerContentViewConstraints];
    [self.layoutConstraintsSectionsSidesBorder removeAllObjects];
    [self.layoutConstraintsSectionsVerticalBuffer removeAllObjects];

    [[AppDelegate app] reportDesigner].shownAndHidden = YES;
    [self.document saveContext];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.detailDisplayView.frame = [self detailDisplayFrame];
    [self.viewControllerSectionLayoutSettings viewWillLayoutSubviews];

    if ([UIDevice isModernOS]) {    //Needed for iOS8 Scroll View Changes
        [self.view removeConstraint: self.layoutConstraintContainerWidth];
        NSLayoutConstraint *width = [self layoutConstraintContentWidthCalculated];
        [self.view addConstraint:width];
        self.layoutConstraintContainerWidth = width;
    }
    CGFloat zoomscale = self.scroller.zoomScale;
    
    CGFloat borderPaddingSides = MTReportDesignerBorderPaddingSides / self.scroller.zoomScale;
    [self.layoutConstraintsSectionsSidesBorder enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = constraint.constant > 0 ? borderPaddingSides : -borderPaddingSides;
    }];
    
    [self.layoutConstraintsSectionsVerticalBuffer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = constraint.constant > 0 ? MTReportDesignerBufferPaddingVertical : -MTReportDesignerBufferPaddingVertical;
    }];

   // [self.layoutConstraintSectionLabelWidthContainer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
   //     constraint.constant = MADSizeWidthSectionLabel / zoomscale;
   // }];

    //[self.layoutConstraintSectionLabelWidthContainer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
    //    constraint.constant = 0.9500 / zoomscale;
    //}];
    
    [self.layoutConstraintSectionLabelHeightContainer enumerateObjectsUsingBlock:^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
        constraint.constant = MTReportDesignerSectionLabelHeight / zoomscale;
    }];


    self.layoutConstraintDesignerContentViewHeight.constant = [self designerContentViewSize].height;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.navigationItem.titleView sizeToFit];
    [self.ruler setNeedsDisplay];
}

- (CGSize)designerContentViewSize {
    NSMutableString *debuggingString = [NSMutableString new];
    
    RptqDocument *document = [self.document activeDocumentModel];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    CGSize designerContentViewSize = CGSizeMake(self.view.bounds.size.width, CGSizeZero.height);
    
    designerContentViewSize.height += (MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical);
    [debuggingString appendFormat:@"%f\n", designerContentViewSize.height];

    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        [debuggingString appendFormat:@"%f %@\n", reportSection.height.floatValue, [reportSection name]];
        [debuggingString appendFormat:@"%f\n", MTReportDesignerBufferPaddingVertical];
        designerContentViewSize.height += (MTReportDesignerBufferPaddingVertical + reportSection.height.floatValue);
        designerContentViewSize.height += self.scroller.zoomScale < 0.9000f ? 1.0000f : 0.0000f;
    }
    designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
    [debuggingString appendFormat:@"%f\n", MTReportDesignerBorderPaddingVertical];
    [debuggingString appendString:NSStringFromCGSize(designerContentViewSize)];
    [debuggingString appendString:@"*****\n\n\n"];
    //NSLog(@"ContentSize\n%@", debuggingString);
    return designerContentViewSize;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.viewControllerSectionLayoutSettings willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.ruler setNeedsDisplay];
    
    CGFloat toolBarHeight = [self toolbarBottomHeight];
    __weak MTReportDesignerViewController *reportDesigner = self;
    [UIView animateWithDuration:duration delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
        reportDesigner.layoutConstraintToolbarHeight.constant = toolBarHeight;
    } completion:NULL];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.viewControllerSectionLayoutSettings didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if ([UIDevice isPad] == NO) {
        CGRect navigationToolbarFrame = self.navigationController.toolbar.frame;
        if (navigationToolbarFrame.size.height != [[self layoutConstraintToolbarHeight] constant]) {
            __weak MTReportDesignerViewController *reportDesigner = self;
            [UIView animateWithDuration:0.1000f delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
                [[reportDesigner layoutConstraintToolbarHeight] setConstant:[reportDesigner toolbarBottomHeight]];
                [reportDesigner.viewControllerSectionLayoutSettings.tableView setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, reportDesigner.toolbox.bounds.size.width, reportDesigner.toolbox.bounds.size.height)];

                if (reportDesigner.toolboxIsVisible) {
                    NSLayoutConstraint *h = reportDesigner.layoutConstraintsToolboxVisiable[0];
                    h.constant = [reportDesigner toolboxHeightCalculated];
                }
            } completion:NULL];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showObjects"]) {

        [self performSegueShowObjects:segue];

    } else if ([segue.identifier isEqualToString:@"MTSegueShowReportViewer"]) {

        [self performSegueShowReportViewer:segue];

    } else if ([segue.identifier isEqualToString:@"showReportViewerFromDesign"]) {
    
        [self performSegueShowReportViewerFromDesigner:segue];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueDocumentObjectEditBarcode"]) {
        
        [self performSegueEditBarcode:segue];

    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueDocumentObjectEditAggregate"]) {
        
        [self performSegueEditAggregate:segue.destinationViewController];
        
    }

    if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
        [segue.destinationViewController setDocument:self.document];
    }

}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.view.frame = navigationController.view.frame;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {

    if ([scrollView isEqual:self.scroller]) {
        [self.detailDisplayView show];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    if ([scrollView isEqual:self.scroller]) {
        
        [self updateDisplayDetailZoomValue];
        self.detailDisplayView.frame = [self detailDisplayFrame];
        
        [self.ruler setNeedsDisplay];
        CGFloat pointsize = self.captionFont.pointSize;
        UIFont *font = [self.captionFont fontWithSize:(pointsize / scrollView.zoomScale)];
        NSDictionary *attributes = @{NSFontAttributeName : font};
        for (DesignerSectionLabel *controlView in [self sectionControlViewsArray]) {
            CGRect boundingRectWithSize = [controlView.text boundingRectWithSize:controlView.bounds.size options:-1 attributes:attributes context:nil];
            controlView.preferredMaxLayoutWidth = boundingRectWithSize.size.width / scrollView.zoomScale;
            controlView.font = font;
            controlView.scale = self.scroller.zoomScale;
            controlView.contentScaleFactor =  scrollView.zoomScale * self.scroller.window.screen.scale;
            [controlView setNeedsDisplay];
        }


        
        if ([UIDevice isModernOS]) {
            
            [self adjustScroller];
            [self.container invalidateIntrinsicContentSize];
            CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
            CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
            self.container.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                                scrollView.contentSize.height * 0.5 + offsetY);
        }
        
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([scrollView isEqual:self.scroller]) {
        CGFloat scaleWithScreen = scale * self.scroller.window.screen.scale;
        
        self.ruler.contentScaleFactor = scaleWithScreen;
        
        for (MTElementView *elementView in [self elementViews]) {
            elementView.contentScaleFactor = scaleWithScreen;
        }
        
        //UIFont *captionFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        CGFloat pointsize = self.captionFont.pointSize;
        for (DesignerSectionLabel *controlView in [self sectionControlViewsArray]) {
            controlView.font = [self.captionFont fontWithSize:pointsize / scale];
            controlView.contentScaleFactor = scaleWithScreen;
            [controlView setNeedsDisplay];
        }
        
        for (UICollectionView *section in [self.sectionViews objectEnumerator]) {
            section.contentScaleFactor = scale;
        }
        
        [self.view setNeedsLayout];
        
        [self.detailDisplayView hide];
        
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([UIDevice isModernOS] && [scrollView isEqual:self.scroller]) {
        [self adjustScroller];
    }
    self.detailDisplayView.frame = [self detailDisplayFrame];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (void)updateDisplayDetailZoomValue {
    NSNumber *number = @(self.scroller.zoomScale);
    [self.detailDisplayView setText: [self.numberFormatterPercentage stringFromNumber:number]];
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.container;
}

- (void)adjustScroller {
    if (self.scroller.contentOffset.x != 0) {
        CGPoint offset = self.scroller.contentOffset;
        offset.x = 0.0000f;
        self.scroller.contentOffset = offset;
        self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width, self.scroller.contentSize.height);
    }
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

- (void)layoutSettings:(MTReportDesignerSectionLayoutSettingsViewController *)layoutSettings newPageAfter:(BOOL)newPageAfter {
    NSUInteger selectedSectionNumber = [self lastSelectedSectionControlPanel];
    
    RptqDocument *document = [self.document activeDocumentModel];
    [document setNewPageAfter:newPageAfter forSectionAtRow:selectedSectionNumber];

    /*
    RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
    RptqQuery *query = [database.hasQueries anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForRow: selectedSectionNumber
                                                                                query: query];
    
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    UIColor *color = [MTReportDesignerViewController sectionBackgroundColor:isVisible];
    documentSectionView.backgroundColor = color;
    */
    [self.document saveContext];
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    NSUInteger selectedSectionNumber = [self lastSelectedSectionControlPanel];

    RptqDocument *document = [self.document activeDocumentModel];
    [document setVisibility:isVisible forSectionAtRow:selectedSectionNumber];
    
    RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
    RptqQuery *query = [database.hasQueries anyObject];
    RptqDocumentSection *documentSection = [query documentSectionForRow: selectedSectionNumber];
    
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    UIColor *color = [MTReportDesignerViewController sectionBackgroundColor:isVisible];
    documentSectionView.backgroundColor = color;
    [self.document saveContext];
}

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
    RptqQuery *query = [database.hasQueries anyObject];
    RptqDocumentSection *documentSection = [query documentSectionForRow: self.lastSelectedSectionControlPanel];
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    CGSize collectionViewContentSize = [documentSectionView.collectionViewLayout collectionViewContentSize];
    [documentSection setInterfaceHeight: collectionViewContentSize.height];
    
    NSString *key = [documentSection sectionKey];
    UICollectionView *collectionView = self.sectionViews[key];
    [collectionView.backgroundView setNeedsDisplay];
    [documentSectionView.collectionViewLayout invalidateLayout];
    [documentSection setInterfaceHeight: collectionViewContentSize.height];

    [self.view setNeedsUpdateConstraints];
    
}

// FIXME: Used for multiple rows in the document section... currently unused

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    RptqDocument *document = [self.document activeDocumentModel];
    RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
    RptqQuery *query = [database.hasQueries anyObject];
    RptqDocumentSection *documentSection = [query documentSectionForRow: self.lastSelectedSectionControlPanel];
    
    BOOL insertNewSection = numberOfRows > documentSection.numberOfRows.integerValue;
    BOOL deleteLastSection = numberOfRows < documentSection.numberOfRows.integerValue;
    
    __weak UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];

    if ([[documentSection numberOfRows] integerValue] == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > [[documentSection numberOfRows] integerValue]) {
        
        //Add row
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: self.document.managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[documentSection hasRows] array]];
        [newRowToAppend setInSection:documentSection];
        [hasRows addObject:newRowToAppend];
        [documentSection setHasRows:hasRows];
        
    } else if (numberOfRows < [[documentSection numberOfRows] integerValue]) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[documentSection hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[documentSection.hasRows array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:hasRows.count - 1];
        [documentSection setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    [documentSection setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
    UICollectionView *collectionView = self.sectionViews[[documentSection sectionKey]];
    MTReportDesignerSectionBackgroundView *backgroundView = (MTReportDesignerSectionBackgroundView *)collectionView.backgroundView;
    [backgroundView setNumberOfRowsInBackground:numberOfRows];

    NSError *error = nil;
    [self.document.managedObjectContext save:&error];
    
    [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        if (insertNewSection) {
            NSInteger index = numberOfRows - 1;
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
            [documentSectionView insertSections:indexSet];
        } else if (deleteLastSection) {
            NSInteger index = numberOfRows;
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
            [documentSectionView deleteSections:indexSet];
        }
    }];
}

#pragma mark - MTDocumentSectionViewDelegate

- (void)didUpdateLayout:(id)sender {
    MTDocumentSectionView *documentSectionView = (MTDocumentSectionView *)sender;
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:[documentSectionView objectIdTag] inManagedObjectContext:self.document.managedObjectContext];
    documentSection.height = @(documentSectionView.bounds.size.height);
    [self relayoutSectionView:documentSectionView];
    [self.document.managedObjectContext save:nil];
}

#pragma mark - MTReportDesignerToolBoxDelegate

- (void)toolboxHeightChanged:(CGFloat)newHeight {
    CGSize newSize = CGSizeMake(320.0000f, newHeight);
    [self.popoverControllerInformation setPopoverContentSize:newSize animated:YES];
    [[self.popoverControllerInformation contentViewController] setPreferredContentSize:newSize];
}

- (void)hideToolbox {
    [UIDevice isPad] ? [self dismissToolboxPopoverControllers] : [self dismissToolboxView];
    [self deselectAllElementsAnimated:YES];
    [self.document.managedObjectContext save:nil];
}

#pragma mark - NSManagedObjectContextObjectsDidChangeNotification

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSArray *updatedObjects = [notification userInfo][NSUpdatedObjectsKey];

    for (id updatedObject in updatedObjects) {
        
        if ([updatedObject isKindOfClass:[RptqDocumentObject class]]) {
            RptqDocumentObject *documentObject = updatedObject;
            NSDictionary *changes = [documentObject changedValues];

            for (id change in changes) {
                if ([change isEqualToString:NSStringFromSelector(@selector(sizewidth))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginRight))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingRight))]) {
                    
                    
                    UICollectionView *section = [self getSectionViewForDocumentSection: documentObject.inSectionRow.inSection];
                    [section.collectionViewLayout invalidateLayout];
                    
                } else if ([change isEqualToString:NSStringFromSelector(@selector(sizeheight))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginBottom))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingBottom))]) {
                    
                    UICollectionView *section = [self getSectionViewForDocumentSection: documentObject.inSectionRow.inSection];
                    [section.collectionViewLayout invalidateLayout];
                }
                
            }
        } else if ([updatedObject isKindOfClass:[RptqDocumentSection class]]) {
            RptqDocumentSection *documentSection = updatedObject;
            NSDictionary *changes = [documentSection changedValues];
            for (id change in changes) {
                if ([change isEqualToString:NSStringFromSelector(@selector(height))]) {
                    MTDocumentSectionView *section = (MTDocumentSectionView *)[self getSectionViewForDocumentSection: documentSection];
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
    NSArray *managedObjectsUpdated = [notification userInfo][NSUpdatedObjectsKey];
    for (NSManagedObject *managedObject in managedObjectsUpdated) {
        MTElementView *elementView = [self elementViewForManagedObject:managedObject];
        [elementView updateForManagedObjectContent:managedObject.managedObjectContext];
    }
}

#pragma mark - Menu Notifications

- (void)willHideMenuNotification:(NSNotification *)notification { }
- (void)didHideMenuNotification:(NSNotification *)notification {
    if ([self lastMenuItemSelectRequiresElementView] == NO) {
        [self deselectLastElementViewToShowMenu];
    }
    self.lastMenuItemSelectRequiresElementView = NO;
}
- (void)didShowMenuNotification:(NSNotification *)notification { }
- (void)willShowMenuNotification:(NSNotification *)notification { }

#pragma mark - MTElementViewDelegate

- (void)didTouchElementView:(MTElementView *)elementView {
    [self removeBorderFromSectionViews];
    if ([self elementViewIsSelected:elementView]) {
        [self.promptManager removeString:elementView.displayStringAttributed.string];
        self.navigationItem.prompt = self.promptManager.prompt;
        [self deselectElementView:elementView animated:YES];
    } else {
        [self.promptManager addString:elementView.displayStringAttributed.string];
        self.navigationItem.prompt = self.promptManager.prompt;
        [self selectElementView:elementView];
    }
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
        __weak MTReportDesignerViewController *reportDesigner = self;
        [self dismissViewControllerAnimated:YES completion:^{
            NSNumber *type = @(MTDocumentObjectTypeImage);
            [reportDesigner insertDocumentObjectWithDefination:
             @{MTDocumentObjectDefinationType: type,
               MTDocumentObjectDefinationObject : selectedImage}];
        }];
    }
    
    [self setDisplayActive];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self setDisplayActive];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController isEqual:self.navigationController] == NO) {
        [self hideToolbox];
    }
}

#pragma mark - Actions

- (void)doubleTapZoom:(UITapGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateEnded) {
        CGFloat initalZoomScale = [self.scroller zoomScale];
        CGFloat zoomScale = ((NSNumber *)self.availableZoomScales.firstObject).floatValue;
        for (NSNumber *scale in self.availableZoomScales) {
            if (initalZoomScale < scale.floatValue) {
                zoomScale = scale.floatValue;
                break;
            }
        }
        [self.scroller setZoomScale:zoomScale animated:YES];
        [self scrollViewDidEndZooming: self.scroller
                             withView: self.container
                              atScale: zoomScale];
    }
}

- (IBAction)done:(id)sender {
    
    NSError *error = nil;
    [self.document.managedObjectContext save:&error];
    if (error != nil) {
        [self.document.managedObjectContext save:&error];
    }
    if (![self dismissAllPopovers]) {
        [self.delegate viewControllerDidFinish:@(NO)];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (IBAction)add:(id)sender {
    [self setDisplayActive];
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showObjects" sender:sender];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self deselectAllElementsAnimated:YES];
    [self setDisplayActive];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
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
    NSManagedObjectID *objectId = [cell objectIdTag];
    NSManagedObjectContext *managedObjectContext = [[self.document activeDocumentModel] managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
    [[documentObject type] integerValue];
    MTDocumentObjectType objectType = [[documentObject type] integerValue];
    return objectType;
}

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = [cell objectIdTag];
    [self removeCollectionViewCellForElementView:objectId completion:^(BOOL finished) {
        if (finished) {
            NSManagedObjectContext *managedObjectContext = [self.document managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
            [[self.document activeDocumentModel] removeDocumentObject:documentObject];
        }
    }];
}

- (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    [self deselectAllElementsAnimated:YES];
    self.lastMenuItemSelectRequiresElementView = YES;
    [self selectElementView:(MTElementView *)[self viewForObjectID:cell.objectIdTag]];
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {

    NSManagedObjectID *elementViewId = [cell objectIdTag];
    RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: elementViewId
                                                                  managedObjectContext: self.document.managedObjectContext];
    
    RptqDocumentSection *section = [[documentObject inSectionRow] inSection];
    UICollectionView *svSection = [self getSectionViewForDocumentSection:section];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: svSection.objectIdTag
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    
    BOOL found = NO;
    
    for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
        
        NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [row hasObjects]];
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
            
            switch ([[objectToEdit type] integerValue]) {

                case MTDocumentObjectTypeAggregate:
                    [self editDocumentObjectAggregate:objectToEdit];
                    break;
                    
                case MTDocumentObjectTypeBarcode:
                    [self editDocumentObjectBarcode:objectToEdit];
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
}

#pragma mark MTCollectionViewCellElement Helpers

- (void)editDocumentObjectAggregate:(RptqDocumentObject *)object {
    self.aggregateToEdit = object.isAggregate;
    self.editAggregate = YES;
    
    if ([UIDevice isPad]) {
        
        NSManagedObjectID *objectId = [object objectID];
        UIView *viewToEdit = [self viewForObjectID:objectId];
        
        if (viewToEdit != nil) {
            CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
            
            UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:MTDocumentObjectNewAggregateNavigationControllerIdentifier];
            MTDocumentObjectNewAggregateViewController *aggregateViewController = [[navigationController viewControllers] firstObject];
            aggregateViewController.delegate = self;
            aggregateViewController.document = self.document;
            [aggregateViewController setAggregateObjectToEdit:self.aggregateToEdit];
            
            CGRect popoverRect = [viewToEdit convertRect:viewToEdit.bounds
                                                  toView:self.container];
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
            popoverController.delegate = self;
            [popoverController setPopoverContentSize:popoverSize animated:NO];
            [popoverController presentPopoverFromRect: popoverRect
                                               inView: self.container
                             permittedArrowDirections: UIPopoverArrowDirectionAny
                                             animated: YES];
            [self setDisplayInactive];
            [self setPopoverControllerEditBarcode: popoverController];
        } else {
            self.objectIdEditAggregateFunction = object.objectID;
            [self performSegueWithIdentifier: MTIdentifierSegueDocumentObjectEditAggregate
                                      sender: self];
        }
        
    } else {
        self.objectIdEditAggregateFunction = object.objectID;
        [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditAggregate sender:self];
    }
}

- (void)editDocumentObjectBarcode:(RptqDocumentObject *)object {
    if ([UIDevice isPad]) {
        
        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
        UIView *viewToEdit = [self viewForObjectID:object.objectID];
        
        if (viewToEdit != nil) {
            
            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
            MTViewControllerBarcode *barcodeViewController = [storyboard instantiateViewControllerWithIdentifier: MTDocumentObjectNewBarcodeViewControllerIdentifier];
            barcodeViewController.document = self.document;
            barcodeViewController.delegate = self;
            
            RptqDocumentObject *documentObject = (RptqDocumentObject *)[self.document.managedObjectContext objectWithID:object.objectID];
            RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
            [self setBarcodeToEdit: barcodeObject];
            [barcodeViewController setBarcodeToEdit: barcodeObject];
            
            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:self.container];
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:barcodeViewController];
            popoverController.delegate = self;
            [popoverController setPopoverContentSize:popoverSize animated:NO];
            [popoverController presentPopoverFromRect:popoverRect
                                               inView:self.container
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
            [self setDisplayInactive];
            
            [self setPopoverControllerEditBarcode: popoverController];
            
        } else {
            self.objectIdEditBarcode = object.objectID;
            [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditBarcode sender:self];
        }
        
        
        
    } else {
        self.objectIdEditBarcode = object.objectID;
        [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditBarcode sender:self];
    }
}

- (void)editDocumentObjectImage:(RptqDocumentObject *)object {
    self.objectIdEditImage = object.objectID;
}

- (void)editDocumentObjectLabelDynamic:(RptqDocumentObject *)object {
    [self setEditDynamicField:YES];
    
    [self setObjectIdEditDynamicLabel:[object objectID]];
    if ([UIDevice isPad]) {
        
        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
        UIView *viewToEdit = [self viewForObjectID:[object objectID]];
        
        if (viewToEdit != nil) {
            
            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
            MTQueryBuilderChooseFieldViewController *chooseFieldViewController = [storyboard instantiateViewControllerWithIdentifier: @"UITableViewControllerChooseFieldDataObject"];
            chooseFieldViewController.document = self.document;
            chooseFieldViewController.delegate = self;
            
            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:self.container];
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:chooseFieldViewController];
            popoverController.delegate = self;
            [popoverController setPopoverContentSize:popoverSize animated:NO];
            [popoverController presentPopoverFromRect:popoverRect
                                               inView:self.container
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
            [self setDisplayInactive];
            [self setPopoverControllerEditDataLabel: popoverController];
        } else {
            [self performSegueWithIdentifier:@"MTIdentifierSegueEditField" sender:self];
        }
    } else {
        [self performSegueWithIdentifier:@"MTIdentifierSegueEditField" sender:self];
        
    }
}

- (void)editDocumentObjectLabelStatic:(RptqDocumentObject *)object {
    
    [self setObjectIdEditStaticLabel:[object objectID]];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Edit Label", @"Edit Label")
                                                        message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel")
                                              otherButtonTitles: NSLocalizedString(@"Change", @"Change"), nil
                              ];
    [alertView setAlertViewStyle: UIAlertViewStylePlainTextInput];
    alertView.delegate = self;
    UITextField *textField = [alertView textFieldAtIndex:0];
    [textField setClearButtonMode:UITextFieldViewModeAlways];
    textField.delegate = self;
    NSString *textFieldText = object.isLabel.text;
    textField.text = textFieldText;
    alertView.tag = MTDocumentObjectTypeLabelStatic;
    self.alertViewEdit = alertView;
    [self.alertViewEdit show];
}

#pragma mark -
#pragma mark - MTViewControllerBarcodeDelegate

- (void)didUpdateBarcode:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo {

    if (self.barcodeToEdit != nil) {
        [self.barcodeToEdit updateWithBarcode:barcode fieldOne:fieldOne fieldTwo:fieldTwo];
    }
    
}

#pragma mark -
#pragma mark - MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                inputType:(MTAggregateFunctionInputType)inputType
                              inputObject:(NSManagedObject *)inputObject
                                groupType:(MTAggregateGroupByType)groupType
                              groupNumber:(NSNumber *)groupNumber {

    RptqDocumentObjectAggregate *aggregateToEdit = [self aggregateToEdit];
    [aggregateToEdit updateAggregateFunctionWithFunctionType:functionType
                                                   inputType:MTAggregateFunctionInputTypeField
                                                   groupType:groupType
                                             aggregateObject:(RptqQueryField *)inputObject
                                                 groupNumber:labs((long)[groupNumber integerValue])];
}

#pragma mark -
#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {
    RptqDocumentObject *documentObject = (RptqDocumentObject *)[[field managedObjectContext] objectWithID:[self objectIdEditDynamicLabel]];
    [[documentObject isLabelDataField] setReferencesQueryField:field];
    [field.managedObjectContext save:nil];
}

#pragma mark -
#pragma mark - UIAlertView delegate protocol

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
        
        NSManagedObjectID *objectId = [self objectIdEditStaticLabel];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[self.document.managedObjectContext objectWithID:objectId];

        UITextField *textField = [alertView textFieldAtIndex:0];
        [documentObject.isLabel setText:textField.text];
        [self.document.managedObjectContext save:nil];
    }
}

#pragma mark -
#pragma mark Text Field Delegate Protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self alertView:self.alertViewEdit clickedButtonAtIndex:1];
    [self.alertViewEdit dismissWithClickedButtonIndex:1 animated:YES];
    return YES;
}


#pragma mark -
#pragma mark Collection View Layout Delegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: [collectionView objectIdTag]
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    return documentSection.height.floatValue;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: [collectionView objectIdTag]
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    
    NSOrderedSet *objects = [documentSection.hasRows[section] hasObjects];
    CGSize result;
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = objects[row];
        result = [documentObject size];
    } else {
        result = CGSizeZero;
    }
    return result;
}

#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat contextScale = [self.scroller zoomScale] * [[[self.scroller window] screen] scale];

    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:[collectionView objectIdTag]
                                                                            inManagedObjectContext:self.document.managedObjectContext];
    NSOrderedSet *objects = [[documentSection hasRows][indexPath.section] hasObjects];
    NSString *resuseId = [self collectionViewReuseIdentifiers][[documentSection identifier]];
    
    MTCollectionViewCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath];
    cell.delegate = self;
    if ([objects count] > indexPath.row) {
        
        RptqDocumentObject *documentObject = objects[indexPath.row];
    
        CGSize documentObjectSize = [documentObject size];
        CGRect cellFrame = CGRectMake(CGPointZero.x, CGPointZero.y, documentObjectSize.width, documentObjectSize.height);
        
        switch ([documentObject getType]) {
            case MTDocumentObjectTypeFormula:
            case MTDocumentObjectTypeLabelStatic:
            case MTDocumentObjectTypeLabelDynamic:
            case MTDocumentObjectTypeAggregate:
            default: {

                for (UIView *subview in [[cell contentView] subviews]) {
                    [subview removeFromSuperview];
                }

                cell.backgroundColor = [UIColor clearColor];
                cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                
                MTElementView *elementView = [self elementViewForManagedObject:documentObject];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                             action: @selector(panPiece:)];
                panGesture.maximumNumberOfTouches = 1;
                panGesture.delegate = self;
                
                UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget: self
                                                                                                   action: @selector(pinchPiece:)];
                pinchGesture.delegate = self;
                
                [self.scroller.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
                [self.scroller.pinchGestureRecognizer requireGestureRecognizerToFail:pinchGesture];
                
                [elementView addGestureRecognizer:panGesture];
                [elementView addGestureRecognizer:pinchGesture];
                
                [elementView setFrame:cellFrame];
                [cell setObjectIdTag:[documentObject objectID]];
                cell.userInteractionEnabled = YES;
                [cell.contentView addSubview:elementView];
                
                if (self.objectIdJustDisplayed != nil) {
                    if (self.objectIdJustDisplayed == documentObject.objectID) {
                        __weak MTReportDesignerViewController *weakself = self;
                        [elementView flash:^(BOOL finished) {
                            if (finished) {
                                weakself.objectIdJustDisplayed = nil;
                            }
                        }];
                    }
                }
                __weak UICollectionViewCell *blockCell = cell;
                __weak MTElementView *blockElementView = elementView;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [blockCell setContentScaleFactor:contextScale];
                        [blockCell.contentView setContentScaleFactor:contextScale];
                        [blockElementView setContentScaleFactor:contextScale];
                    });
                });
                break;
            }
        }
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: collectionView.objectIdTag
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    NSOrderedSet *objects = [documentSection.hasRows[section] hasObjects];
    return [objects count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionReuseableViewDefault *result = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        label.text = @"Header";
        [result addSubview:label];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        label.text = @"Footer";
        [result addSubview:label];
    } else {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
    }
    return result;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:[collectionView objectIdTag]
                                                                    inManagedObjectContext:self.document.managedObjectContext];
    return [[documentSection hasRows] count];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
      forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:)) {
        result = YES;
    }
    return result;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSInteger row = indexPath.row;

    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: collectionView.objectIdTag
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    NSOrderedSet *objects = [documentSection.hasRows[indexPath.section] hasObjects];
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = objects[row];
        
        if (action == @selector(delete:)) {
            [self delete:documentObject];
        } else if (action == @selector(edit:)) {
            [self edit:documentObject];
        }
        
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissAllPopovers];
    [self deselectAllElementsAnimated:NO];
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
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
    
    if ([sender isKindOfClass:[MTSettingsViewController class]]) {
        [self.scroller setZoomScale: 1.0000f animated:NO];
        __weak MTReportDesignerViewController *reportDesigner = self;
        [self dismissViewControllerAnimated:YES completion:^{
            [reportDesigner.view setNeedsUpdateConstraints];
            [reportDesigner.container setNeedsLayout];
            [reportDesigner.container setNeedsDisplay];
        }];
        
    } else if ([sender isKindOfClass:[MTReportViewerController class]]) {
        if ([UIDevice isPad]) {
            [self dismissViewControllerAnimated:YES completion:^{}];
            [self setDisplayActive];
        }
    } else {
        if ([UIDevice isPad]) {
            if ([self.popoverControllerObjectSelector isPopoverVisible]) {
                [self.popoverControllerObjectSelector dismissPopoverAnimated:YES];
                [self setDisplayActive];
            } else {
                [self.scroller setZoomScale:1.0000f animated:NO];
                __weak MTReportDesignerViewController *reportDesigner = self;
                [self dismissViewControllerAnimated:YES completion:^{
                    [reportDesigner.view setNeedsUpdateConstraints];
                    [reportDesigner.container setNeedsLayout];
                    [reportDesigner.container setNeedsDisplay];
                    [reportDesigner setDisplayActive];
                }];
            }
        } else {
            __weak MTReportDesignerViewController *reportDesigner = self;
            [self dismissViewControllerAnimated:YES completion:^{
                [reportDesigner.container setNeedsDisplay];
                [reportDesigner setDisplayActive];
            }];
        }
    }
}

#pragma mark - MTReportDesignerObjectSelectorDelegate

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
    [self setDisplayActive];
    [self insertDocumentObjectWithDefination:
     @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
       MTDocumentObjectDefinationObject : [field objectID]}];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber {
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
}


- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
    [self setDisplayActive];
    [self insertDocumentObjectWithDefination:
        @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelStatic),
           MTDocumentObjectDefinationObject : labelText}];

}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer.view isEqual:[otherGestureRecognizer view]] == NO  &&
            [gestureRecognizer.view isEqual:self.scroller] == NO &&
            [[otherGestureRecognizer view] isEqual:self.scroller] == NO;

}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

#pragma mark - Actions

- (void)edit:(id)sender { }

#pragma mark - MTReportDesignerSectionViewLayoutLiquidDelegate

- (MTCollectionViewLayoutLiquidAttributes *)collectionView: (UICollectionView *)collectionView
                                                    layout: (UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {
    
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: [collectionView objectIdTag]
                                                                    inManagedObjectContext: self.document.managedObjectContext];
    RptqDocumentSectionRows *rows =[[documentSection hasRows] firstObject];
    NSOrderedSet *objects = [rows hasObjects];
    MTCollectionViewLayoutLiquidAttributes *result = [MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    if ([objects count] > [indexPath item]) {
        RptqDocumentObject *documentObject = objects[[indexPath item]];
        [result setDropPoint: CGPointMake([[documentObject dropPointX] floatValue], [[documentObject dropPointY] floatValue])];
        CGSize documentObjectSize = documentObject.size;
        [result setFrame:CGRectMake(result.dropPoint.x, result.dropPoint.y, documentObjectSize.width, documentObjectSize.height)];
        
        [result setLastTouchPoint: result.dropPoint];
        [result setDropIndex: [[documentObject dropIndex] integerValue]];
        [result setLayoutDescription:[documentObject toStringHumanReadable]];
    } else {
        result.dropPoint = CGPointZero;
        result.lastTouchPoint = CGPointZero;
        result.dropIndex = 0;
        result.frame = CGRectZero;
    }
    result.lastTouchPointValid = NO;
    return result;
}

- (NSUInteger)numberOfItemsInSection: (NSUInteger)section
                    ofCollectionView: (UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:collectionView.objectIdTag
                                                                    inManagedObjectContext:self.document.managedObjectContext];
    NSOrderedSet *objects = [[documentSection hasRows][section] hasObjects];
    return [objects count];
}

- (NSUInteger)collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:[collectionView objectIdTag]
                                                                            inManagedObjectContext:self.document.managedObjectContext];
    
    NSOrderedSet *objects = [[documentSection hasRows][indexPath.section] hasObjects];
    NSUInteger dropIndex = 0;
    if ([objects count] > indexPath.row) {
        RptqDocumentObject *documentObject = objects[indexPath.row];
        NSUInteger dropIndex = [documentSection nextDropIndexForSection];
        [documentObject setDropIndex:@(dropIndex)];
        NSError *error = nil;
        [[documentObject managedObjectContext] save:&error];
    }
    return dropIndex;
}

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
          setDropPoint:(CGPoint)dropPoint
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: [collectionView objectIdTag]
                                                                            inManagedObjectContext: self.document.managedObjectContext];
    
    
    NSOrderedSet *objects = [[documentSection hasRows][section] hasObjects];
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = objects[row];
        if (CGPointEqualToPoint(dropPoint, [documentObject dropPoint]) == NO) {
            [documentObject setDropPoint:dropPoint];
            [self.document.managedObjectContext save:nil];
        }
    }
}

#pragma mark - Helpers

#pragma mark General

- (BOOL)oneOrMoreElementsSelected {
    return [[self selectedObjectIds] count] > 0;
}

- (BOOL)elementViewIsSelected:(MTElementView *)elementView {
    return [[self selectedObjectIds] containsObject:[elementView objectIdTag]];
}

- (NSInteger)removeBorderFromAllSectionViews {
    NSUInteger deselectedSectionViewCounter = 0;
    for (UIView *view in [self.sectionControlViews objectEnumerator]) {
        deselectedSectionViewCounter += [self  removeBorderFromView:view] ? 1 : 0;
    }
    return deselectedSectionViewCounter;
}

- (void)selectElementView:(MTElementView *)elementView {
    
    NSInteger numberOfViewsDeselected = [self removeBorderFromAllSectionViews];
    
    if (numberOfViewsDeselected == 0) {
        
        [self.selectedObjectIds addObject:elementView.objectIdTag];
        [self applyBorderToView:elementView];
        
        self.viewControllerToolbox.document = self.document;
        [self.viewControllerToolbox showToolboxWithObjectIds:self.selectedObjectIds];
        
        if ([UIDevice isPad] == NO) {
            if ([self dismissAllPopovers] == NO) {
                [self showToolbox:MTToolboxTypeElement];
            }
        } else {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[self.popoverControllerInformation passthroughViews]];
            [passThroughViews addObject:elementView];
            
            NSArray *allObjects = [self.elementViews allObjects];
            [self.popoverControllerInformation setPassthroughViews:allObjects];
            [self.popoverControllerInformation setPopoverContentSize: CGSizeMake(320.0000f, 300.0000f) animated:NO];
            
            [self repositionPopoverControllerInformationAnimated:YES];
            [self setDisplayInactive];
        }
        
    } else {
        [self hideToolbox];
    }
    
}

- (void)deselectElementView:(MTElementView *)elementView animated:(BOOL)animated {
    
    [[self selectedObjectIds] removeObject:[elementView objectIdTag]];
    [self removeBorderFromView: elementView];
    
    if ([UIDevice isPad]) {
        
        NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[self.popoverControllerInformation passthroughViews]];
        [passThroughViews removeObject:elementView];
        
        if ([self.popoverControllerInformation isPopoverVisible]) {
            if ([self oneOrMoreElementsSelected]) {
                [self repositionPopoverControllerInformationAnimated:animated];
                [self setDisplayInactive];
            } else {
                [self hideToolbox];
            }
        }
    } else if ([self oneOrMoreElementsSelected] == NO) {
        [self hideToolbox];
    }
}

- (UIViewController *)viewControllerForToolboxType:(MTToolboxType)tooboxType {
    UIViewController *viewController;
    switch (tooboxType) {
            
        case MTToolboxTypeElement:
            [self.popoverControllerInformation setPassthroughViews:[[self elementViews] allObjects]];
            [self.viewControllerToolbox showToolboxWithObjectIds:[self selectedObjectIds]];
            self.viewControllerToolbox.document = self.document;
            viewController = self.viewControllerToolbox;
            break;
            
        case MTToolboxTypeSection: {
            [self.navigationControllerSectionLayoutSettings setNavigationBarHidden:NO animated:NO];
            viewController = self.navigationControllerSectionLayoutSettings;
            break;
        }
        default:
            NSAssert(false, @"%s: ToolboxType unkonwn.", __PRETTY_FUNCTION__);
            break;
    }
    return viewController;
}

- (void)setupToolboxWithViewController:(UIViewController *)viewController {
    
    viewController.view.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.toolbox.frame.size.width, self.toolbox.frame.size.height);
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    if (viewController.view.superview == nil) {
        [self.toolbox addSubview:viewController.view];
    }

}

- (void)dismissToolboxPopoverControllers {
    if ([self.popoverControllerInformation isPopoverVisible]) {
        [self.popoverControllerInformation dismissPopoverAnimated:YES];
        [self setDisplayActive];
    }
    if ([self.popoverControllerSectionSettings isPopoverVisible]) {
        [self.popoverControllerSectionSettings dismissPopoverAnimated:YES];
        [self setDisplayActive];
    }
    [self setDisplayActive];
}

- (void)presentToolboxViewOfType:(MTToolboxType)toolboxType {
    if (self.toolboxIsVisible == NO) {
        self.toolboxIsVisible = YES;
        
        [self removeItemsFromToolbars];
        [self.view layoutIfNeeded];
        self.contentOffsetOnShowToolbox = self.scroller.contentOffset;
        
        __weak MTReportDesignerViewController *weakSelf = self;
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                         animations: ^{
                             [weakSelf setConstraintsForToolboxVisible];
                             
                             UIEdgeInsets insets = [weakSelf desiredScrollInsets];
                             weakSelf.contentInset = insets;
                             insets = [weakSelf desiredScrollInsets];
                             weakSelf.scrollIndicatorInsets = insets;
                             [weakSelf.view layoutIfNeeded];
                             
                         } completion: ^(BOOL finished) {
                             if (finished) {
                                 [weakSelf adjustContextOffsetForToolboxWithToolboxType:toolboxType];
                             }
                         }];
    }
    
}

- (void)setContentInset:(UIEdgeInsets)insets {
    self.scroller.contentInset = insets;
}

- (void)setScrollIndicatorInsets:(UIEdgeInsets)insets {
    self.scroller.scrollIndicatorInsets = insets;
}

- (void)dismissToolboxView {
    if (self.toolboxIsVisible) {
        self.toolboxIsVisible = NO;
        
        [self.navigationControllerSectionLayoutSettings setNavigationBarHidden:YES animated:YES];
        
        __weak MTReportDesignerViewController *weakSelf = self;
        
        MTBlockCompletionNoReturn animations = ^{
            [weakSelf setConstraintsForToolboxHidden];
            UIEdgeInsets insets = [weakSelf desiredEdgeInsets];
            weakSelf.contentInset = insets;
            weakSelf.scrollIndicatorInsets = insets;
            [weakSelf.view layoutIfNeeded];
        };
        
        MTBlockCompletionSimple completion = ^(BOOL finished) {
            if (finished) {
                if ([weakSelf.navigationControllerSectionLayoutSettings.view superview] != nil) {
                    [weakSelf.navigationControllerSectionLayoutSettings.view removeFromSuperview];
                }
                if ([weakSelf.viewControllerToolbox.view superview] != nil) {
                    [weakSelf.viewControllerToolbox.view removeFromSuperview];
                }
                [weakSelf.toolbarBottom setItems:weakSelf.toolbarBottomItems animated:YES];
                
                [weakSelf.scroller setContentOffset:weakSelf.contentOffsetOnShowToolbox animated:YES];
                weakSelf.navigationItem.prompt = nil;
            }
        };
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: animations
                         completion: completion];
    }
}

- (void)showToolbox:(MTToolboxType)tooboxType { //Never called on iPad
    UIViewController *viewController = [self viewControllerForToolboxType:tooboxType];
    if ([viewController respondsToSelector:@selector(setDocument:)]) {
        [(MTReportDesignerToolBoxViewController *)viewController setDocument:self.document];
    }
    [self setupToolboxWithViewController:viewController];
    [self presentToolboxViewOfType:tooboxType];
}

- (void)adjustContextOffsetForToolboxWithToolboxType:(MTToolboxType)toolboxType {
    if (toolboxType == MTToolboxTypeSection) {
        [self adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:self];
    } else if (toolboxType == MTToolboxTypeElement) {
        [self adjustContentOffsetForSelectedElements];
    }
}

- (void)adjustContentOffsetForSelectedElements {
    [self positionForRectOfInterest: [self rectForSelectedElements]];
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:(MTReportDesignerViewController *)reportDesigner {
    RptqQuery *query = [[self.document activeDocumentModel] defaultQuery];
    RptqDocumentSection *documentSection = [query documentSectionForRow: reportDesigner.lastSelectedSectionControlPanel];
    UIView *selectedSectionView = [reportDesigner getSectionViewForDocumentSection:documentSection];
    [self positionForRectOfInterest: selectedSectionView.frame];
}

- (void)positionForRectOfInterest:(CGRect)rectOfInterest {
    
    CGFloat adjustment = [self heightScrollViewAdjustment];

    CGRect visibleRect;
    visibleRect.origin = CGPointMake(self.scroller.contentOffset.x, self.scroller.contentOffset.y);
    visibleRect.size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - [self toolboxHeightCalculated]);
    visibleRect = CGRectAdjustForScale(visibleRect, self.scroller.zoomScale);

    CGRect visableRectAdjusted = CGRectMake(CGPointZero.x - (CGFLOAT_MAX / 2.0000f),
                                            visibleRect.origin.y + adjustment,
                                            CGFLOAT_MAX,
                                            visibleRect.size.height - adjustment);
    
    if (CGRectContainsRect(visableRectAdjusted, rectOfInterest) == NO) {
        CGPoint contentOffset = CGPointContentOffsetBottomOfRect(rectOfInterest, visibleRect);
        contentOffset = CGPointMake(contentOffset.x, contentOffset.y * self.scroller.zoomScale);
        [self.scroller setContentOffset:contentOffset animated:YES];
    }
}


- (void)setConstraintsForToolboxVisible {
    [self.view removeConstraints:self.layoutConstraintsToolboxHidden];
    self.layoutConstraintsToolboxVisiable = @[[self layoutConstraintToolBoxViewHeight]];
    [self.view addConstraints:self.layoutConstraintsToolboxVisiable];
    self.toolboxVisible = YES;
    self.layoutConstraintToolbarHeight.constant = CGSizeZero.height;
}

- (void)setConstraintsForToolboxHidden {
    [self.view removeConstraints:self.layoutConstraintsToolboxVisiable];
    [self.view addConstraints:self.layoutConstraintsToolboxHidden];
    self.toolboxVisible = NO;
    self.layoutConstraintToolbarHeight.constant = CGSizeZero.height;
}

- (void)removeItemsFromToolbars {
    [self.toolbarBottom setItems:nil animated:YES];
}

- (void)repositionPopoverControllerInformationAnimated:(BOOL)animated {
    [self.popoverControllerInformation presentPopoverFromRect: self.rectForSelectedElements
                                                       inView: self.container
                                     permittedArrowDirections: UIPopoverArrowDirectionAny
                                                     animated: animated];
}

- (CGPoint)locationOfPointInWindows:(CGPoint)point {
    return [self.scroller convertPoint:point fromView:self.scroller.window];
}

- (void)pinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    gestureRecognizer.view.transform = CGAffineTransformScale(gestureRecognizer.view.transform, gestureRecognizer.scale, gestureRecognizer.scale);
    gestureRecognizer.scale = 1.0000f;

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
        gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
        gestureRecognizer.state == UIGestureRecognizerStateFailed) {

        UICollectionView *collectionView = [self sectionViewFor:gestureRecognizer];
        __weak MTReportDesignerViewController *weakself = self;
        __weak UICollectionView *weakCollectionView = collectionView;
        
        [collectionView performBatchUpdates:^(void) {
            
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: [(MTElementView *)gestureRecognizer.view objectIdTag]
                                                                          managedObjectContext: weakself.document.managedObjectContext];
            [documentObject dropAtRect:gestureRecognizer.view.frame];
            [documentObject.managedObjectContext save:nil];
            
            [gestureRecognizer.view setNeedsLayout];
            [gestureRecognizer.view setNeedsDisplay];
            
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.6666f animations:^{
                    [weakCollectionView invalidateIntrinsicContentSize];
                }];
            }
        }];
        
        [collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {
            
            [self gestureBegan];
            
            gestureRecognizer.view.alpha = 0.8888f;
            [self.container bringSubviewToFront: gestureRecognizer.view];
            
            gestureRecognizer.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, self.scroller.zoomScale, self.scroller.zoomScale);
            CGPoint newCenter = [self.scroller locationInMainWindow:gestureRecognizer];
            [self.scroller addSubview: gestureRecognizer.view];
            gestureRecognizer.view.center = newCenter;
            
            __weak MTReportDesignerViewController *weakself = self;
            [self removeCollectionViewCellForElementView: [gestureRecognizer.view objectIdTag] completion: ^(BOOL finished) {
                UICollectionView *sectionView = [weakself sectionViewFor:gestureRecognizer];
                [weakself relayoutSectionView:sectionView];
                [weakself.view setNeedsLayout];
                gestureRecognizer.view.center = [weakself.scroller locationInMainWindow:gestureRecognizer];
            }];

            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            gestureRecognizer.view.center = [self.scroller locationInMainWindow:gestureRecognizer];
            
            break;
        }
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            
            gestureRecognizer.view.alpha = 1.0000f;
            gestureRecognizer.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0000, 1.0000);

            UICollectionView *sectionView = [self sectionViewFor:gestureRecognizer];

            if (sectionView != nil) {
                
                [self relayoutSectionView:sectionView];
                __weak NSManagedObjectContext *managedObjectContext = self.document.managedObjectContext;
                
                NSManagedObjectID *objectId = [gestureRecognizer.view objectIdTag];
                NSManagedObjectID *sectionId = [sectionView objectIdTag];
                
                CGRect frame = gestureRecognizer.view.frame;
                __weak UIView *weakGestureRecognizerView = gestureRecognizer.view;
                
                __weak RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: sectionId
                                                                                       inManagedObjectContext: managedObjectContext];
                __weak UICollectionView *weakSectionView = sectionView;
                __weak MTReportDesignerViewController *weakself = self;
                
                [sectionView performBatchUpdates:^(void) {
                    
                    [weakGestureRecognizerView removeFromSuperview];
                    
                    RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                                  managedObjectContext: managedObjectContext];
                    
                    NSIndexPath *indexPathInsert = [documentSection addDocumentObject: documentObject
                                                                        withDropPoint: frame.origin];
                    NSArray *indexPathsInserted = @[indexPathInsert];
                    [weakSectionView insertItemsAtIndexPaths:indexPathsInserted];
                    [documentSection.managedObjectContext save:nil];
                    
                } completion:^(BOOL finished) {
                    if (finished) {
                        [documentSection setHeight:@([weakSectionView intrinsicContentSize].height)];
                        [UIView animateWithDuration:0.6666f animations:^{
                            [weakSectionView invalidateIntrinsicContentSize];
                        }];
                        [managedObjectContext save:nil];
                        [weakself redrawAllElementViewsInCollectionView:weakSectionView];
                        [weakself.view setNeedsLayout];
                    }
                }];
                
            }
            
            [gestureRecognizer.view setNeedsDisplay];
            [self gestureEnded];
            break;
        }
        default:
            break;
    }
}

- (void)gestureBegan {
    [[UIMenuController sharedMenuController] setMenuVisible: NO
                                                   animated: YES];
    [self setScrollersEnabled: NO];
}

- (void)gestureEnded {
    [self setScrollersEnabled:YES];
}

- (void)singleTapToDeselectElementViews:(UITapGestureRecognizer *)sender {
    [[UIMenuController sharedMenuController] setMenuVisible: NO
                                                   animated: YES];
    [self hideToolbox];
}

- (void)toggleSectionControlPanel:(DesignerSectionLabel *)label {
    [[UIMenuController sharedMenuController] setMenuVisible: NO
                                                   animated: YES];
    
    if ([[self selectedElementViews] count] >= 1) {
        [self hideToolbox];
    } else {
        
        self.viewControllerToolbox.document = self.document;
        if ([label selected]) {
            
            
            [label normalView];
            [self hideToolbox];
            
        } else {
            
            [self deselectAllElementsAnimated:YES];
            
            self.lastSelectedSectionControlPanel = label.tag;
            
            RptqDocument *document = [self.document activeDocumentModel];
            RptqDatabase *database = [document.hasDatabaseSchemas anyObject];
            RptqQuery *query = [database.hasQueries anyObject];
            RptqDocumentSection *section = [query documentSectionForRow: self.lastSelectedSectionControlPanel];
            [label dimView];

            UIColor *borderColor = [UIColor tintColorAnalogous4];
            UIView *superView = [self getSectionViewForDocumentSection: section];
            superView.layer.borderColor = [borderColor CGColor];
            superView.layer.borderWidth = 1.0000f;
            
            self.viewControllerSectionLayoutSettings.initalHeightValue = section.height.floatValue;
            self.viewControllerSectionLayoutSettings.initalVisibility = section.visibility.boolValue;
            self.viewControllerSectionLayoutSettings.initalFormFeedEnabled = section.producesFormFeed;
            self.viewControllerSectionLayoutSettings.initalNumberOfRows = section.numberOfRows.integerValue;
            [self.viewControllerSectionLayoutSettings updateDisplay];
            
            UIEdgeInsets ei = self.viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets;
            self.viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(ei.top, ei.left, CGSizeZero.height + self.tabBarController.tabBar.bounds.size.height, ei.right);
            self.viewControllerSectionLayoutSettings.tableView.contentInset = self.viewControllerSectionLayoutSettings.tableView.scrollIndicatorInsets;
            
            if ([UIDevice isPad]) {
                [self.popoverControllerSectionSettings setPopoverContentSize: CGSizeMake(320.0000f, 260.00000f)
                                                                    animated: NO];
                self.popoverControllerSectionSettings.passthroughViews = @[label];
                [self.popoverControllerSectionSettings presentPopoverFromRect: label.bounds
                                                                       inView: label
                                                     permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                     animated:YES];
                [self setDisplayInactive];
                
            } else {
                [self showToolbox:MTToolboxTypeSection];
            }
        }
    }
}

- (void)redrawAllElementViewsInCollectionView:(UICollectionView *)collectionView {
    for (int i = 0; i < [collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *insertedPath = [NSIndexPath indexPathForItem:i inSection:0];
        MTElementView *elementView = [self elementViewAtIndexPath:insertedPath inCollectionView:collectionView];
        [elementView setNeedsDisplay];
    }
}

- (MTDocumentSectionView *)sectionViewFor:(UIGestureRecognizer *)gesture {
    MTDocumentSectionView *result = nil;
    CGPoint gestureLocation;
    // Try to find the section to place the element view into.
    CGPoint viewLocation = [gesture locationInView:self.container];
    
    //Find the section to add the element.
    for (UIView *sectionView in [self.container subviews]) {
        if ([sectionView isKindOfClass:[MTDocumentSectionView class]]) {
            if (CGRectContainsPoint([sectionView frame], viewLocation) && ![sectionView isEqual:self]) {
                result = (MTDocumentSectionView *)sectionView;
                gestureLocation = [gesture locationInView:result];
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [gesture.view setCenter: gestureLocation];
                break;
            }
        }
    }
    
    //Section not found, so add to the first one.
    if (result == nil) {
        for (UICollectionView *view in [self.container subviews]) {
            if ([view isKindOfClass: [MTDocumentSectionView class]]) {
                result = (MTDocumentSectionView *)view;
                gestureLocation = [gesture locationInView:result];
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [gesture.view setCenter: gestureLocation];
                break;
            }
        }
    }
    return result;
}

- (MTElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath
                         inCollectionView:(UICollectionView *)collectionView {
    
    return [self elementViewForCollectionViewCell:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (MTElementView *)elementViewForCollectionViewCell:(UICollectionViewCell *)cell {
    MTElementView *result = nil;
    
    for (id elementView in [cell.contentView subviews]) {
        if ([elementView isKindOfClass:[MTElementView class]]) {
            result = elementView;
            break;
        }
    }
    return result;
}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {
    [self setDisplayActive];
    
    
    RptqDocument *document = [self.document activeDocumentModel];
    
    RptqDocumentSection *section = [document hasDetailSection];
    
    __weak MTReportDesignerViewController *reportDesigner = self;
    __weak UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];
    
    [detailSection performBatchUpdates:^{
        
        RptqDocumentObject *documentObject = [document addDocumentObject:documentObjectDefination];
        [documentObject obtainPermanentID];
        reportDesigner.objectIdJustDisplayed = documentObject.objectID;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem: 0
                                                     inSection: 0];
        NSArray *indexPaths = @[indexPath];
        [detailSection insertItemsAtIndexPaths:indexPaths];
        
        [documentObject saveContext];
    } completion:^(BOOL finished) {
        
        
        RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID: detailSection.objectIdTag
                                                                        inManagedObjectContext: reportDesigner.document.managedObjectContext];
        documentSection.height = @([detailSection intrinsicContentSize].height);
        [reportDesigner.container setNeedsUpdateConstraints];
        [reportDesigner.document saveContext];
        [reportDesigner.document quickSave];
        
    }];
}

- (void)removeCollectionViewCellForElementView:(NSManagedObjectID *)elementViewId
                                    completion:(void (^)(BOOL finished))completion {
    
    RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: elementViewId
                                                                  managedObjectContext: self.document.managedObjectContext];
    
    RptqDocumentSectionRows *sectionRow = [documentObject inSectionRow];
    RptqDocumentSection *section = [sectionRow inSection];
    NSInteger deleteIndex = [sectionRow.hasObjects indexOfObject:documentObject];
    UICollectionView *sectionCollectionView = [self getSectionViewForDocumentSection:section];
    
    __weak MTReportDesignerViewController *weakself = self;
    
    __weak UICollectionView *weakSectionCollectionView = sectionCollectionView;
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [sectionRow hasObjects]];
    [hasObjects removeObjectAtIndex:deleteIndex];
    
    [sectionCollectionView performBatchUpdates:^{
        
        sectionRow.hasObjects = hasObjects;
        documentObject.inSectionRow = nil;
        
        NSError *error = nil;
        [weakself.document.managedObjectContext save:&error];
        
        NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
        [weakSectionCollectionView deleteItemsAtIndexPaths: @[deletePath]];
        
    } completion:^(BOOL finished) {
        if (finished) {
            
            CGSize size = [weakSectionCollectionView intrinsicContentSize];
            [section setHeight:@(size.height)];
            [UIView animateWithDuration:0.6666f animations:^{
                [weakSectionCollectionView invalidateIntrinsicContentSize];
            }];
            
            [weakself.document.managedObjectContext save:nil];
            [weakself redrawAllElementViewsInCollectionView:weakSectionCollectionView];
            if (completion != nil) {
                completion(YES);
            }
        }
    }];
}

- (CGFloat)toolbarBottomHeight {
    return self.toolboxVisible ? CGSizeZero.height : CGSizeZero.height;
}

- (CGRect)rectForSelectedElements {
    NSSet *views = [self selectedElementViews];
    return [self.container popoverRectForSelectedViews:views];
}

- (UIView *)viewForObjectID:(NSManagedObjectID *)objectID {
    return [self.container viewWithTag: objectID.hash];
}

#pragma mark Display Helpers

- (void)relayoutSectionView:(UICollectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];

    NSManagedObjectContext *managedObjectContect = [self.document managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection documentSectionForObjectID:objectId inManagedObjectContext:managedObjectContect];
    NSString *key = [documentSection sectionKey];
    NSLayoutConstraint *layoutConstraint = self.layoutConstraintsReportSectionHeight[key];
    layoutConstraint.constant = documentSection.height.floatValue;
    [self.view setNeedsUpdateConstraints];
}

- (void)enableUserInteraction:(id)sender {
    self.view.userInteractionEnabled = YES;
}

/*- (void)storeLayoutConstraintsForSectionHeights {
    for (NSLayoutConstraint *layoutConstraint in [self.container constraints]) {
        if (layoutConstraint.firstAttribute ==  NSLayoutAttributeHeight &&
            layoutConstraint.secondItem == nil &&
            [layoutConstraint.firstItem isKindOfClass:[MTDocumentSectionView class]]) {
            NSManagedObjectID *objectId = [layoutConstraint.firstItem objectIdTag];
            NSString *key = [objectId key];
            self.layoutConstraintsReportSectionHeight[key] = layoutConstraint;
        }
    }
}*/

+ (UIColor *)designerBackgroundColor {
    return [UIColor lightGrayColor];
}

+ (UIColor *)sectionBackgroundColor:(BOOL)isVisible {
    return isVisible ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.70000f];
}

- (void)setDisplayActive {
    self.barButtonAddReportObject.enabled = YES;
    [self enableTabBarItems];
}

- (void)setDisplayInactive {
    self.barButtonAddReportObject.enabled = NO;
    [self disableTabBarItems];
}

- (void)setScrollersEnabled:(BOOL)enabled {
    @synchronized(self.scroller) {
        if ([self.scroller respondsToSelector:@selector(setScrollEnabled:)]) {
            self.scroller.scrollEnabled = enabled;
            [self.scroller flashScrollIndicators];
            for (UICollectionView *collectionView in [self.container subviews]) {
                if ([collectionView isKindOfClass: [UICollectionView class]]) {
                    [collectionView setScrollEnabled:enabled];
                    [collectionView flashScrollIndicators];
                }
            }
        }
    }
}

#pragma mark - Helpers

#pragma mark Element View helpers

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if ([UIDevice isPad]) {
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
        if (self.popoverControllerInformation != nil) [allpopovers addObject:self.popoverControllerInformation];
        if ([self popoverControllerObjectSelector] != nil) [allpopovers addObject:[self popoverControllerObjectSelector]];
        if (self.popoverControllerSectionSettings != nil) [allpopovers addObject:self.popoverControllerSectionSettings];
        
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
    
    RptqDocument *document = [self.document activeDocumentModel];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    for (RptqDocumentSection *documentSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:documentSection.identifier.integerValue];
        NSInteger numberOfSectionsInCollectionView = [documentSectionView numberOfSections];
        
        for (NSUInteger section = 0; section < numberOfSectionsInCollectionView; section++) {
            NSInteger numberOfItemsInSection = [documentSectionView numberOfItemsInSection:section];
            
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                MTElementView *elementView = [self elementViewAtIndexPath: [NSIndexPath indexPathForItem:item inSection:section]
                                                         inCollectionView: documentSectionView];
                if (elementView != nil) {
                    [results addObject:elementView];
                }
            }
        }
    }
    return results;
}

- (MTDocumentSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifer {
    MTDocumentSectionView *documentSectionView = nil;
    for (id subview in [self.container subviews]) {
        if ([subview tag] == identifer && [subview isKindOfClass:[MTDocumentSectionView class]]) {
            documentSectionView = subview;
            break;
        }
    }
    return documentSectionView;
}

- (NSSet *)selectedElementViews {
    
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    if ([[self selectedObjectIds] count] > 0) {
        //Try quick hash method...
        BOOL quickHashWorks = YES;
        for (NSManagedObjectID *selectedObjectId in [self selectedObjectIds]) {
            UIView *selectedView = [self viewForObjectID:selectedObjectId];
            if (selectedView != nil) {
                [results addObject:selectedView];
            } else {
                quickHashWorks = NO;
            }
        }
        
        //NSAssert(quickHashWorks, @"Maybe not such a good idea.");
        if (quickHashWorks == NO) {     //Case when views are off screen.
            
            RptqDocument *document = [self.document activeDocumentModel];
            SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
            
            for (RptqDocumentSection *documentSection in sectionEnumerator) {
                MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]];
                
                for (NSUInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
                    for (NSUInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                        MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:documentSectionView];
                        if ([[self selectedObjectIds] containsObject: [elementView objectIdTag]]) {
                            [results addObject:elementView];
                        }
                    }
                }
            }
        }
    }
    return results;
}

- (UICollectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return self.sectionViews[[documentSection sectionKey]];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return self.sectionControlViews[[documentSection sectionKey]];
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
    
    //Remove border from element views
    for (MTElementView *elementView in [self selectedElementViews]) {
        [self deselectElementView:elementView animated:animated];
    }
    
    [self removeBorderFromSectionViews];
    
    [self.promptManager removeAll];
    self.navigationItem.prompt = self.promptManager.prompt;
}

- (void)deselectLastElementViewToShowMenu {
    if ([self lastElementViewToShowMenu]) {
        [self deselectElementView:[self lastElementViewToShowMenu] animated:YES];
    }
}

- (void)removeBorderFromSectionViews {
    //Remove border from the section views
    [self.sectionControlViews enumerateKeysAndObjectsUsingBlock:^(id key, DesignerSectionLabel *view, BOOL *stop) {
        [view normalView];
    }];
    
    //Remove border from the section views
    [self.sectionViews enumerateKeysAndObjectsUsingBlock:^(id key, UICollectionView *view, BOOL *stop) {
        view.layer.borderWidth = 0.0000f;
    }];
}

- (void)applyBorderToView:(UIView *)view {
    NSNumber *key = @([view tag]);
    [self borderAppliedToView][key] = @YES;
    UIColor *tintColor = [UIColor tintColorAnalogous4];
    view.layer.borderColor = [tintColor CGColor];
    view.layer.borderWidth = [view borderWidthThin];
}

- (BOOL)removeBorderFromView:(UIView *)view {
    BOOL result;
    if ([self isBorderAppliedToView:view]) {
        NSNumber *key = @([view tag]);
        self.borderAppliedToView[key] = @NO;
        result = YES;
        
        view.layer.borderColor = [[UIColor blackColor] CGColor];
        view.layer.borderWidth = 0.0000f;
    } else {
        result = NO;
    }
    return result;
}

- (BOOL)isBorderAppliedToView:(UIView *)view {
    NSNumber *key = @([view tag]);
    return [self.borderAppliedToView[key] boolValue];
}

- (MTElementView *)elementViewForManagedObject:(NSManagedObject *)managedObject {
    MTElementView *elementView = nil;
    elementView = (MTElementView *)[self viewForObjectID:managedObject.objectID];
    if (!elementView) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObject:managedObject];
        if (documentObject) {
            elementView = (MTElementView *)[self.container viewWithTag:documentObject.objectID.hash];
            if (!elementView) {
                
                elementView = [[MTElementView alloc] initWithObjectId: documentObject.objectID
                                                      inObjectContext: documentObject.managedObjectContext];
                elementView.tag = documentObject.objectID.hash;
                elementView.delegate = self;
                elementView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [elementView updateForManagedObjectContent:documentObject.managedObjectContext];
            }
        }
    }
    return elementView;
}

- (RptqDocumentObject *)documentObjectForElementView:(MTElementView *)elementView inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectID *objectID = [elementView objectIdTag];
    return (RptqDocumentObject *)[managedObjectContext objectWithID:objectID];
}

+ (NSString *)reuseIdentifierSection:(NSInteger)sectionNumber {
    return [[MTCollectionViewCellElement reuseIdentifier] stringByAppendingFormat:@"%ld", (long)sectionNumber];
}


- (CGFloat)heightTopBars {
    CGFloat height = self.navigationController.navigationBar.bounds.size.height;
    return UIDeviceOrientationIsLandscape([self interfaceOrientation]) ?
                                            (height += [UIApplication sharedApplication].statusBarFrame.size.width) :
                                            (height += [UIApplication sharedApplication].statusBarFrame.size.height);
}

- (CGFloat)heightScrollViewAdjustment {
    return [self heightTopBars] * self.scroller.zoomScale;
}

#pragma mark Segue Helpers

- (void)performSegueShowObjects:(UIStoryboardSegue *)segue {
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
        [self setDisplayInactive];
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        UIPopoverController *popoverController = [popoverSegue popoverController];
        popoverController.delegate = self;
        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f + 44.0000f);
        [popoverController setPopoverContentSize:popoverSize animated:YES];
        
        [self setPopoverControllerObjectSelector:popoverController];
    }
    
    MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = nil;
    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *d = segue.destinationViewController;
        d.delegate = self;
        viewControllerObjectSelector = (MTReportDesignerObjectSelectorViewController *)d.topViewController;
        viewControllerObjectSelector.objectSelectorDelegate = self;
        viewControllerObjectSelector.document = self.document;
    } else {
        viewControllerObjectSelector = segue.destinationViewController;
        viewControllerObjectSelector.objectSelectorDelegate = self;
        viewControllerObjectSelector.document = self.document;
    }
}

- (void)performSegueShowReportViewer:(UIStoryboardSegue *)segue {
    if ([UIDevice isPad]) {
        MTReportViewerController *viewControllerReportViewer;
        UINavigationController *d = segue.destinationViewController;
        viewControllerReportViewer = (MTReportViewerController *)[d topViewController];
        viewControllerReportViewer.viewControllerDelegate = self;
    }
    [self.scroller scrollRectToVisible:CGRectZero animated:NO];
}

- (void)performSegueShowReportViewerFromDesigner:(UIStoryboardSegue *)segue {
    [self.scroller scrollRectToVisible:CGRectZero animated:NO];
}

- (void)performSegueEditBarcode:(UIStoryboardSegue *)segue {
    MTViewControllerBarcode *barcodeViewController = segue.destinationViewController;
    barcodeViewController.document = self.document;
    
    NSManagedObjectContext *managedObjectContext = [self.document managedObjectContext];
    NSManagedObjectID *objectId = [self objectIdEditBarcode];
    RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
    RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
    [barcodeViewController setBarcodeToEdit: barcodeObject];
}

- (void)performSegueEditAggregate:(UIStoryboardSegue *)segue {
    MTDocumentObjectNewAggregateViewController *aggregateViewController = segue.destinationViewController;
    aggregateViewController.document = self.document;
    NSManagedObjectID *objectId = [self objectIdEditAggregateFunction];
    RptqDocumentObject *documentObject = (RptqDocumentObject *)[self.document.managedObjectContext objectWithID:objectId];
    RptqDocumentObjectAggregate *aggregateObject = [documentObject isAggregate];
    [aggregateViewController setAggregateObjectToEdit:aggregateObject];
}

#pragma mark Constraints Helpers

- (void)contentViewRemoveAllConstraints {
    NSArray *constraints = [self.container constraints];
    if (constraints.count > 0) {
        [self.container removeConstraints:constraints];
    }
}

- (void)scrollerRemoveAllConstraints {
    NSArray *constraints = [self.scroller constraints];
    if (constraints.count > 0) {
        [self.scroller removeConstraints:constraints];
    }
}

#pragma mark UIPopoverController Helpers

- (void)setupPopoverControllers {
    UIPopoverController *popoverControllerInformation = [MTReportDesignerViewController popoverWithContoller:self.viewControllerToolbox];
    popoverControllerInformation.delegate = self;
    self.popoverControllerInformation = popoverControllerInformation;
    
    UIPopoverController *popoverControllerSectionSettings = [MTReportDesignerViewController popoverWithContoller:self.navigationControllerSectionLayoutSettings];
    popoverControllerSectionSettings.delegate = self;
    self.popoverControllerSectionSettings = popoverControllerSectionSettings;
}

#pragma mark NSNotificationCenter Helpers

- (void)addObservers {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidChange:)
                          name: NSManagedObjectContextObjectsDidChangeNotification
                        object: self.document.managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: self.document.managedObjectContext];
    
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
                        object: self.document];
}

- (void)removeObservers {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextObjectsDidChangeNotification
                           object: self.document.managedObjectContext];
    
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextDidSaveNotification
                           object: self.document.managedObjectContext];
    
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
                           object: self.document];
}

#pragma mark - Creators

+ (UIBarButtonItem *)buttonDone:(id)target {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                          target: target
                                                                          action: @selector(hideToolbox)];
    return done;
}

+ (UITapGestureRecognizer *)tapGestureRecognizerSingle:(id)target {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(singleTapToDeselectElementViews:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.delegate = target;
    return tap;
}

+ (UITapGestureRecognizer *)tapGestureRecognizerDouble:(id)target {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(doubleTapZoom:)];
    tap.numberOfTapsRequired = 2;
    tap.numberOfTouchesRequired = 1;
    tap.delegate = target;
    return tap;
}

+ (UIPopoverController *)popoverWithContoller:(UIViewController *)controller {
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:controller];
    [popover setPopoverContentSize:CGSizeMake(320.0000f, 480.0000f) animated:NO];
    return popover;
}

+ (MTReportDesignerToolBoxViewController *)toolbox {
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    return [storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"];
}

+ (MTReportDesignerSectionLayoutSettingsViewController *)toolboxSettings {
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    return [storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier];
}

+ (UINavigationController *)navigationControllerSectionLayoutSettings:()controller {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    UIColor *whiteColor = [UIColor whiteColor];
    NSDictionary *textAttribues = @{NSForegroundColorAttributeName : whiteColor};
    [navigationController.navigationBar setTitleTextAttributes:textAttribues];
    return navigationController;
}

+ (MTDocumentSectionView *)documentSectionView:(RptqDocumentSection *)section delegate:(id)layoutDelegate {
    MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
    [backgroundView setNumberOfRowsInBackground:section.numberOfRows.integerValue];
    backgroundView.backgroundColor = [UIColor clearColor];
    
    MTReportDesignerSectionViewLayoutLiquid *flowLayoutDesignerSection = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];
    flowLayoutDesignerSection.delegate = layoutDelegate;
    MTDocumentSectionView *collectionView = [[MTDocumentSectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
    [collectionView setObjectIdTag: section.objectID];
    
    NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
    collectionView.tag = section.identifier.integerValue;
    NSString *documentElementReuseIdentifier = [MTReportDesignerViewController reuseIdentifierSection:collectionView.tag];
    [collectionView registerClass: [MTCollectionViewCellElement class]
       forCellWithReuseIdentifier: documentElementReuseIdentifier];
    [collectionView registerClass: [MTCollectionReuseableViewDefault class]
       forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
              withReuseIdentifier: supplmentaryViewReuseIdHeader];
    [collectionView registerClass: [MTCollectionReuseableViewDefault class]
       forSupplementaryViewOfKind: UICollectionElementKindSectionFooter
              withReuseIdentifier: supplmentaryViewReuseIdHeader];
    
    UIColor *bgcolor = [MTReportDesignerViewController sectionBackgroundColor:section.visibility.boolValue];
    collectionView.backgroundColor = bgcolor;
    collectionView.clipsToBounds = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    collectionView.allowsSelection = YES;
    collectionView.allowsMultipleSelection = YES;
    collectionView.backgroundView = backgroundView;
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.layer.borderColor = [UIColor borderColor].CGColor;
    
    [collectionView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                      forAxis: UILayoutConstraintAxisVertical];
    [collectionView setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
                                                    forAxis: UILayoutConstraintAxisVertical];
    return collectionView;
}

#pragma mark - NSLayoutConstraint
#pragma mark Content View

- (NSLayoutConstraint *)layoutConstraintViewContentLeft {
    return [NSLayoutConstraint constraintWithItem: self.container
                                        attribute: NSLayoutAttributeLeft
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: [UIDevice isModernOS] ? self.scroller : self.view
                                        attribute: NSLayoutAttributeLeft
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewContentRight {
    return [NSLayoutConstraint constraintWithItem: self.container
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: [UIDevice isModernOS] ? self.scroller : self.view
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewLeft:(UIView *)view {
    return [NSLayoutConstraint constraintWithItem: view
                                        attribute: NSLayoutAttributeLeft
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.container
                                        attribute: NSLayoutAttributeLeft
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewRight:(UIView *)view {
    return [NSLayoutConstraint constraintWithItem: view
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.container
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewContentTop {
    return [NSLayoutConstraint constraintWithItem: self.container
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.scroller
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

#pragma mark Scroll View

- (NSLayoutConstraint *)layoutConstraintViewScrollerTop {
    return [NSLayoutConstraint constraintWithItem: self.scroller
                                        attribute: NSLayoutAttributeTop
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.topLayoutGuide
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewScrollerBottom {
    return [NSLayoutConstraint constraintWithItem: self.scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.bottomLayoutGuide
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintViewToolbarHeightHidden {
    return [NSLayoutConstraint constraintWithItem: self.toolbarBottom
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintToolbarBottomToToolboxView {
    return [NSLayoutConstraint constraintWithItem: self.toolbarBottom
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.toolbox
                                        attribute: NSLayoutAttributeTop
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}
- (NSLayoutConstraint *)layoutConstraintToolBoxViewBottom {
    return [NSLayoutConstraint constraintWithItem: self.toolbox
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: self.view
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

- (NSLayoutConstraint *)layoutConstraintToolBoxViewHeight {
    return [NSLayoutConstraint constraintWithItem: self.toolbox
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.000f
                                         constant: [self toolboxHeightCalculated]];
}

- (NSLayoutConstraint *)layoutConstraintToolboxHeightHidden {
    return [NSLayoutConstraint constraintWithItem: self.toolbox
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 0.0000f
                                         constant: 0.0000f];
}

+ (NSArray *)layoutConstraintsRuler:(MTRulerView *)ruler inDesigner:(UIView *)designer {
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeHeight
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: nil
                                                                   attribute: NSLayoutAttributeNotAnAttribute
                                                                  multiplier: 1.0000f
                                                                    constant: MTReportDesignerRulerHeight];
    
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeTop
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeTop
                                                                  multiplier: 1.0000f
                                                                    constant: MTReportDesignerBorderPaddingVertical];
    
    return @[constraint1, constraint2];
}

+ (NSArray *)layoutConstraintsRulerSide:(MTRulerView *)ruler inDesigner:(UIView *)designer {
    NSLayoutConstraint *constraint3 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeLeft
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeLeft
                                                                  multiplier: 1.0000f
                                                                    constant: MTReportDesignerBorderPaddingSides];
    
    NSLayoutConstraint *constraint4 = [NSLayoutConstraint constraintWithItem: ruler
                                                                   attribute: NSLayoutAttributeRight
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: designer
                                                                   attribute: NSLayoutAttributeRight
                                                                  multiplier: 1.0000f
                                                                    constant: -MTReportDesignerBorderPaddingSides];
    return @[constraint3, constraint4];
}

+ (NSLayoutConstraint *)layoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelBottom:(UIView *)label {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: -MTReportDesignerBufferPaddingVertical];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toLabelRight:(UIView *)label {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeRight
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: section
                                        attribute: NSLayoutAttributeRight
                                       multiplier: 1.0000f
                                                    constant: -MTReportDesignerBufferPaddingVertical];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toHeight:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: section
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

+ (NSLayoutConstraint *)layoutConstraintSection:(UIView *)section toItemBottom:(UIView *)item {
    return  [NSLayoutConstraint constraintWithItem: item
                                         attribute: NSLayoutAttributeBottom
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: section
                                         attribute: NSLayoutAttributeTop
                                        multiplier: 1.0000f
                                          constant: -MTReportDesignerBufferPaddingVertical];
}

+ (NSArray *)layoutConstraintsForSection:(UIView *)section content:(UIView *)content {
    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem: section
                                                           attribute: NSLayoutAttributeLeft
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: content
                                                           attribute: NSLayoutAttributeLeft
                                                          multiplier: 1.0000f
                                                            constant: MTReportDesignerBorderPaddingSides];
    
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem: section
                                                           attribute: NSLayoutAttributeRight
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: content
                                                           attribute: NSLayoutAttributeRight
                                                          multiplier: 1.0000f
                                                            constant: -MTReportDesignerBorderPaddingSides];
    
    return @[lc1, lc2];
}

+ (NSLayoutConstraint *)layoutConstraintsForSectionLabel:(UIView *)label content:(UIView *)content {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeWidth
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: content
                                        attribute: NSLayoutAttributeWidth
                                       multiplier: MADSizeWidthSectionLabel
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintsForSectionLabel2:(UIView *)label content:(UIView *)content {
    return [NSLayoutConstraint constraintWithItem: label
                                        attribute: NSLayoutAttributeWidth
                                        relatedBy: NSLayoutRelationLessThanOrEqual
                                           toItem: content
                                        attribute: NSLayoutAttributeWidth
                                       multiplier: 0.9500f
                                         constant: 0.0000f];
}



+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view toScrollerBottom:(UIScrollView *)scroller {
    return [NSLayoutConstraint constraintWithItem: scroller
                                        attribute: NSLayoutAttributeBottom
                                        relatedBy: NSLayoutRelationEqual
                                           toItem: view
                                        attribute: NSLayoutAttributeBottom
                                       multiplier: 1.0000f
                                         constant: 0.0000f];
}

+ (NSLayoutConstraint *)layoutConstraintViewContent:(UIView *)view height:(CGFloat)height {
    return [NSLayoutConstraint constraintWithItem: view
                                        attribute: NSLayoutAttributeHeight
                                        relatedBy: NSLayoutRelationGreaterThanOrEqual
                                           toItem: nil
                                        attribute: NSLayoutAttributeNotAnAttribute
                                       multiplier: 1.0000f
                                         constant: height];
}

#pragma mark - Save after Unwind from Modal View Controller

- (void)saveStaticLabel:(MTDocumentObjectNewStaticLabelViewController *)viewController {
    NSString *labelText = [viewController userInputedText];
    [self insertDocumentObjectNewLabel: labelText];
}

- (void)saveWhiteSpace {
    __weak MTReportDesignerViewController *reportDesigner = self;
    block_insertObject insert = ^(UIViewController *action) {
        NSNumber *type = @(MTDocumentObjectTypeWhtiespace);
        NSDictionary *options = @{MTDocumentObjectDefinationType: type};
        [reportDesigner insertDocumentObjectWithDefination: options];
    };
    insert(nil);
}

- (void)saveDynamicLabel:(MTQueryBuilderChooseFieldViewController *)viewController {
    
    __weak MTReportDesignerViewController *reportDesigner = self;
    block_insertObject insert = ^(UIViewController *sourceViewController) {
        MTQueryBuilderChooseFieldViewController *dynamicFieldController = (MTQueryBuilderChooseFieldViewController *)sourceViewController;
        RptqQueryField *queryField = [dynamicFieldController queryField];
        [reportDesigner insertDocumentObjectWithDefination:
         @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
           MTDocumentObjectDefinationObject : [queryField objectID]}];
    };
    
    insert(viewController);
}

- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController {
    if (self.aggregateToEdit && self.editAggregate) {
        if ([viewController fieldObject] != nil) {
            [self.aggregateToEdit updateAggregateFunctionWithFunctionType: viewController.aggregateFunctionType
                                                                inputType: MTAggregateFunctionInputTypeField
                                                                groupType: viewController.aggregateGroupByType
                                                          aggregateObject: viewController.fieldObject
                                                              groupNumber: viewController.groupTypeSectionNumber];
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
}

- (void)saveBarcodeLabel:(MTViewControllerBarcode *)viewController {
    
    if ([self objectIdEditBarcode]  != nil) {
        
        MTBarcode *barcode = [viewController barcode];
        
        NSManagedObjectContext *managedObjectContext = [self.document managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditBarcode];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
        [barcodeObject updateWithBarcode: barcode
                                fieldOne: viewController.queryField1
                                fieldTwo: viewController.queryField2];
        [self setObjectIdEditBarcode:nil];
        
    } else {
        
        NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
        defination[MTDocumentObjectDefinationType] = @(MTDocumentObjectTypeBarcode);
        defination[MTDocumentObjectDefinationObject] = [viewController barcode];
        
        RptqQueryField *queryField1 = viewController.queryField1;
        if (queryField1 != nil) {
            NSManagedObjectID *objectId = [queryField1 objectID];
            defination[MTDocumentObjectDefinationField1] = objectId;
        }
        
        RptqQueryField *queryField2 = viewController.queryField2;
        if (queryField2 != nil) {
            NSManagedObjectID *objectId = [queryField2 objectID];
            defination[MTDocumentObjectDefinationField2] = objectId;
        }
        [self insertDocumentObjectWithDefination:defination];
        
    }
}

#pragma mark - Delegates
#pragma mark MTTabBarImageProtocol

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:@"UIBarButtonItemMadDesigner"];
}

@end
