//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerViewController.h"
#import "DesignerSectionLabel.h"

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
};

const CGFloat MTReportDesignerRulerHeight           = 24.0000f;
const CGFloat MTReportDesignerSectionLabelHeight    = 22.0000f;
const CGFloat MTReportDesignerBorderPadding         =  3.0000f;
const CGFloat MTReportDesignerCornerRadius          =  5.0000f;

const CGFloat previousScaleWeight                   =  0.6666f;

@interface MTReportDesignerViewController()

@property (nonatomic, retain) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, retain) UINavigationController *navigationControllerSectionLayoutSettings;
@property (nonatomic, retain) MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings;

@property (nonatomic, assign) NSUInteger lastSelectedSectionControlPanel;

@property (nonatomic, retain) UIPopoverController *popoverControllerInformation;
@property (nonatomic, retain) UIPopoverController *popoverControllerObjectSelector;
@property (nonatomic, retain) UIPopoverController *popoverControllerSectionSettings;

@property (nonatomic, assign) BOOL toolboxIsVisible;
@property (nonatomic, retain) MTElementView *lastElementViewToShowMenu;
@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *layoutConstraintsToRemove;
@property (nonatomic, retain) MTRulerView *rulerView;

@property (nonatomic, retain) NSMutableDictionary *sectionViews;
@property (nonatomic, retain) NSMutableDictionary *sectionControlViews;
@property (nonatomic, retain) NSMutableDictionary *sectionBackgroundViews;

@property (nonatomic, retain) IBOutlet UIScrollView *designerScrollView;
@property (nonatomic, retain) IBOutlet UIView *designerContentView;

@property (nonatomic, retain) UIToolbar *toolboxToolbar;
@property (nonatomic, retain) UIView *toolboxBackgroundView; 
@property (nonatomic, retain) UIScrollView *toolboxScrollView;

@property (nonatomic, retain) NSArray *toolboxToolbarItemsPrimary;
@property (nonatomic, retain) NSArray *toolboxToolbarItemsFontChooser;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxHidden;
@property (nonatomic, retain) NSArray *toolbarTopItems;
@property (nonatomic, retain) NSArray *toolbarBottomItems;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *layoutConstraintContainerToDesignerVertSpace;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *layoutConstraintContainerToDesignerCenterY;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *layoutConstraintContainerToDesignerCenterX;
@property (nonatomic, retain) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;
@property (nonatomic, retain) NSMutableDictionary *collectionViewReuseIdentifiers;

@property (nonatomic, retain) IBOutlet UIView *toolboxView;

@property (nonatomic, retain) IBOutlet UIButton *informationButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemObjects;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbarTop;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbarBottom;

@property (nonatomic, retain) NSMutableSet *selectedObjectIds;

@property (nonatomic, retain) NSMutableDictionary *holderForLastTouchesByCollectionView;
@property (nonatomic, retain) NSMutableDictionary *layoutConstraintsReportSectionHeight;

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;   //Not implemented

@property (nonatomic, retain) MAReportDocument *activeDocument;

@property (nonatomic, retain) IBOutlet DocumentStatusView *documentStatusView;

@property (nonatomic, retain) NSMutableArray *widthConstraints;

@property (nonatomic, retain) MTDocumentSectionView *reportFooterView;

@property (nonatomic, assign) CGPoint pinchInitalPointA;
@property (nonatomic, assign) CGPoint pinchInitalPointB;
@property (nonatomic, assign) CGAffineTransform pinchBeginTransform;

@property (nonatomic, assign) CGFloat currentNewPointAX;
@property (nonatomic, assign) CGFloat currentNewPointAY;
@property (nonatomic, assign) CGFloat currentNewPointBX;
@property (nonatomic, assign) CGFloat currentNewPointBY;
@property (nonatomic, assign) CGSize currentScaleSize;

@end

@implementation MTReportDesignerViewController

#pragma mark - NSObject

- (void)dealloc {
    [_rulerView release];
    [_designerContentView release];
    [_activeDocument release];
    [_reportFooterView release];
    [_navigationControllerSectionLayoutSettings release];
    [_layoutConstraintsReportSectionHeight release];
    [_lastElementViewToShowMenu release];
    [_popoverControllerSectionSettings release];
    [_popoverControllerObjectSelector release];
    [_popoverControllerInformation release];
    [_viewControllerSectionLayoutSettings release];
    [_viewControllerToolbox release];
    [_holderForLastTouchesByCollectionView release];
    [_selectedObjectIds release];
    [_toolbarTopItems release];
    [_toolbarBottomItems release];
    [_layoutConstraintsToolboxHidden release];
    [_layoutConstraintsToolboxVisiable release];
    [_toolboxBackgroundView release];
    [_toolboxScrollView release];
    [_toolboxToolbarItemsFontChooser release];
    [_toolboxToolbarItemsPrimary release];
    [_toolboxToolbar release];
    [_sectionControlViews release];
    [_sectionBackgroundViews release];
    [_sectionViews release];
    [_settingsPopoverController release];
    [_designerScrollView release];
    [_informationButton release];
    [_barButtonItemInfo release];
    [_barButtonItemSettings release];
    [_barButtonItemObjects release];
    [_toolbarBottom release];
    [_toolbarTop release];
    [_toolboxView release];
    [_layoutConstraintsToRemove release];
    [_documentStatusView release];
    [_layoutConstraintDesignerContentViewHeight release];
    [_layoutConstraintContainerToDesignerVertSpace release];
    [_layoutConstraintContainerToDesignerCenterY release];
    [_layoutConstraintContainerToDesignerCenterX release];
    [super dealloc];
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [[self rulerView] setNeedsDisplay];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect statusViewBounds;
    if (self.toolbarBottom.frame.size.height < 40.0000f) {
        statusViewBounds = CGRectMake(CGPointZero.x, CGPointZero.y, 24.0000f, 24.0000f);
    } else {
        statusViewBounds = CGRectMake(CGPointZero.x, CGPointZero.y, 32.0000f, 32.0000f);
    }
    [[self documentStatusView] setBounds:statusViewBounds];
    [[self documentStatusView] setNeedsDisplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self designerContentView] removeConstraints:[[self designerContentView] constraints]];
    [[self designerScrollView] removeConstraints:[[self designerScrollView] constraints]];
    
    [[self view] addConstraints:@[
     [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeLeft   multiplier:1.0000f constant:0.0000f],
     [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeRight  multiplier:1.0000f constant:0.0000f],
     [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self toolbarTop]    attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f]
     ]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];

    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    [self setActiveDocument:activeDocument];
    [activeDocument release];
    
    MTReportDesignerToolBoxViewController *viewControllerToolbox = [[storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"] retain];
    [viewControllerToolbox setDelegate:self];
    [self setViewControllerToolbox:viewControllerToolbox];
    [viewControllerToolbox release];

    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [[storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier] retain];
    [viewControllerSectionLayoutSettings setDelegate:self];
    [self setViewControllerSectionLayoutSettings: viewControllerSectionLayoutSettings];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self viewControllerSectionLayoutSettings]];
    [self setNavigationControllerSectionLayoutSettings:navigationController];
    [navigationController release];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideToolbox:)];
    [[[self viewControllerSectionLayoutSettings] navigationItem] setRightBarButtonItem:doneButton animated:NO];
    [doneButton release];

    [viewControllerSectionLayoutSettings release];

    if ([UIDevice isPad]) {
        UIPopoverController *popoverControllerInformation = [[UIPopoverController alloc] initWithContentViewController:[self viewControllerToolbox]];
        [popoverControllerInformation setDelegate:self];
        [popoverControllerInformation setPopoverContentSize:CGSizeMake(320.0000f, 320.0000f) animated:NO];
        [self setPopoverControllerInformation:popoverControllerInformation];
        [popoverControllerInformation release];

        UIPopoverController *popoverControllerSectionSettings = [[UIPopoverController alloc] initWithContentViewController:[self navigationControllerSectionLayoutSettings]];
        [popoverControllerSectionSettings setDelegate:self];
        [popoverControllerSectionSettings setPopoverContentSize:CGSizeMake(320.0000f, 320.0000f) animated:NO];
        [self setPopoverControllerSectionSettings:popoverControllerSectionSettings];
        [popoverControllerSectionSettings release];
    }
    
    NSMutableDictionary *holderForLastTouchesByCollectionView = [[NSMutableDictionary alloc] init];
    [self setHolderForLastTouchesByCollectionView:holderForLastTouchesByCollectionView];
    [holderForLastTouchesByCollectionView release];
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [self setSelectedObjectIds:set];
    [set release];
    
    [self setToolbarTopItems:[[self toolbarTop] items]];
    [self setToolbarBottomItems:[[self toolbarBottom] items]];
    [self setToolboxIsVisible:NO];

    MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
    CGColorRef shadowColor = [[UIColor darkGrayColor] CGColor];
    [[viewRuler layer] setCornerRadius: MTReportDesignerCornerRadius];
    [[viewRuler layer] setMasksToBounds: YES];
    [[viewRuler layer] setBorderColor: shadowColor];
    [[viewRuler layer] setBorderWidth: 1.0000f];
    [viewRuler setTranslatesAutoresizingMaskIntoConstraints:NO];


    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    
    UICollectionView *lastCollectionView = nil;
    NSInteger sectionCounter = 0;
    
    NSMutableDictionary *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setLayoutConstraintsReportSectionHeight:layoutConstraintsReportSectionHeight];
    [layoutConstraintsReportSectionHeight release];
    
    NSMutableDictionary *dictionarySectionBackgroundViews = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setSectionBackgroundViews:dictionarySectionBackgroundViews];
    [dictionarySectionBackgroundViews release];
    
    NSMutableDictionary *dictionarySections = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setSectionViews: dictionarySections];
    [dictionarySections release];
    
    NSMutableDictionary *dictionarySectionControls = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setSectionControlViews:dictionarySectionControls];
    [dictionarySectionControls release];

    if ([self layoutConstraintsToRemove] != nil) {
        [[self view] removeConstraints:[self layoutConstraintsToRemove]];
    }
    
    BOOL skipLayout = [UIDevice isModernOS] || [UIDevice isPad] == NO;
    BOOL skipTopBar = [UIDevice isPad] == NO || [UIDevice isModernOS];
    if (skipLayout == NO) {

        NSLayoutConstraint *layoutConstraintToolboxHeight = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.5000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolbarTopHeight = [NSLayoutConstraint constraintWithItem: [self toolbarTop] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarTop] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolbarBottomHeight = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        
        [self setLayoutConstraintsToolboxVisiable:@[layoutConstraintToolboxHeight, layoutConstraintToolbarTopHeight, layoutConstraintToolbarBottomHeight]];
        
        NSLayoutConstraint *layoutConstraintToolbarTopHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarTop] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarTop] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolbarBottomHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolboxHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        
        [self setLayoutConstraintsToolboxHidden:@[layoutConstraintToolboxHeightHidden, layoutConstraintToolbarTopHeightHidden, layoutConstraintToolbarBottomHeightHidden]];
        
        [[self view] addConstraints:@[layoutConstraintToolboxHeightHidden,
            [NSLayoutConstraint constraintWithItem: [self toolbarTop]         attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self designerScrollView] attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self designerScrollView] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom]      attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self toolbarBottom]      attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolboxView]        attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self toolboxView]        attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self view]               attribute: NSLayoutAttributeBottom multiplier: 1.0000f constant: 0.0000f]
         ]];
        
    } else if (skipTopBar) {

        NSLayoutConstraint *layoutConstraintToolboxHeight = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.5000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolbarBottomHeight = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        [self setLayoutConstraintsToolboxVisiable:@[layoutConstraintToolboxHeight, layoutConstraintToolbarBottomHeight]];
        
        NSLayoutConstraint *layoutConstraintToolbarBottomHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolboxHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        [self setLayoutConstraintsToolboxHidden:@[layoutConstraintToolboxHeightHidden, layoutConstraintToolbarBottomHeightHidden]];
                
        [[self view] addConstraints:@[layoutConstraintToolboxHeightHidden,
            [NSLayoutConstraint constraintWithItem: [self view]               attribute: NSLayoutAttributeTop    relatedBy: NSLayoutRelationEqual toItem: [self designerScrollView] attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self designerScrollView] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom]      attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self toolbarBottom]      attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolboxView]        attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f],
            [NSLayoutConstraint constraintWithItem: [self toolboxView]        attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self view]               attribute: NSLayoutAttributeBottom multiplier: 1.0000f constant: 0.0000f]
         ]];

    }
    
    NSMutableDictionary *collectionViewReuseIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setCollectionViewReuseIdentifiers:collectionViewReuseIdentifiers];
    [collectionViewReuseIdentifiers release];
    
    [[self designerScrollView] addConstraints:
        @[[NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil                        attribute:NSLayoutAttributeNotAnAttribute multiplier: 1.0000f constant: MTReportDesignerRulerHeight],
          [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeTop            multiplier: 1.0000f constant: MTReportDesignerBorderPadding],
          [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeLeft           multiplier: 1.0000f constant: MTReportDesignerBorderPadding],
          [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeRight          multiplier: 1.0000f constant: -MTReportDesignerBorderPadding]
     ]];

    [[self designerContentView] addSubview:viewRuler];

    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPadding;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {

        sectionHeights += MTReportDesignerBorderPadding;
        
        [lastCollectionView  release];  //Should be nil on first pass.

        // MARK: Create collection view for report document section.
        
        MTReportDesignerSectionViewLayoutLiquid *flowLayoutDesignerSection = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];
        [flowLayoutDesignerSection setDelegate:self];

        MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
        [backgroundView setNumberOfRowsInBackground:[[reportSection numberOfRows] integerValue]];
        [backgroundView setBackgroundColor:[UIColor edaGreenLight]];

        NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];

        MTDocumentSectionView *collectionView = [[MTDocumentSectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
        [collectionView setObjectIdTag:[reportSection objectID]];
        NSMutableDictionary *lastTouches = [[NSMutableDictionary alloc] init];
        [[self holderForLastTouchesByCollectionView] setObject:lastTouches forKey:@(collectionView.tag)];
        [lastTouches release];

        NSString *documentElementReuseIdentifier = [[MTCollectionViewCellElement reuseIdentifier] stringByAppendingFormat:@"%d", [[reportSection identifier] integerValue]];
        [[self collectionViewReuseIdentifiers] setObject:documentElementReuseIdentifier forKey:[reportSection identifier]];
        [collectionView registerClass: [MTCollectionViewCellElement class] forCellWithReuseIdentifier: documentElementReuseIdentifier];
        [collectionView registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader  withReuseIdentifier:supplmentaryViewReuseIdHeader];
        [collectionView registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:supplmentaryViewReuseIdHeader];

        NSUInteger collectionViewTag = [[reportSection identifier] integerValue];
        [collectionView setTag: collectionViewTag];
        [collectionView setDelegate:self];
        [collectionView setSectionDelegate:self];
        [collectionView setDataSource:self];
        [collectionView setBackgroundColor:[UIColor whiteColor]];
        [collectionView setClipsToBounds:YES];
        [collectionView setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        [collectionView setAllowsSelection:YES];
        [collectionView setAllowsMultipleSelection:YES];
        [collectionView setBackgroundView:backgroundView];
        [collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[collectionView layer] setCornerRadius:MTReportDesignerCornerRadius];
        

        // MARK: Create label to identify document section.
        DesignerSectionLabel *sectionControlView = [[DesignerSectionLabel alloc] initWithDisplayText:[reportSection localizedDisplayName]];
        [sectionControlView setBackgroundColor:[UIColor edaYellow]];
        [sectionControlView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[sectionControlView layer] setCornerRadius:MTReportDesignerCornerRadius];
        [sectionControlView setClipsToBounds:YES];
        [sectionControlView setTag:sectionCounter];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSectionControlPanel:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [tapGestureRecognizer setNumberOfTouchesRequired:1];
        [tapGestureRecognizer setDelegate: self];
        [sectionControlView addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];
        
        [collectionView     setContentHuggingPriority:UILayoutPriorityDefaultLow                forAxis:UILayoutConstraintAxisVertical];
        [collectionView     setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [sectionControlView setContentHuggingPriority:UILayoutPriorityDefaultLow                forAxis:UILayoutConstraintAxisHorizontal];
        [sectionControlView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

        
        // MARK: Setup vert auto layout
        NSString *collectionViewKey = [reportSection sectionKey];


        [[sectionControlView layer] setBorderColor: [[UIColor blackColor] CGColor]];
        [[sectionControlView layer] setBorderWidth: 1.0000f];
        [[collectionView layer] setBorderColor: shadowColor];
        [[collectionView layer] setBorderWidth: 1.0000f];

        [[self sectionBackgroundViews] setValue:backgroundView forKey:collectionViewKey];
        
        CGFloat reportSectionHeight = [[reportSection height] floatValue];
        sectionHeights += reportSectionHeight;

        id constraintItem =  sectionCounter == 0 ? viewRuler : lastCollectionView;
        
        [[self designerContentView] addConstraints:@[
         [NSLayoutConstraint constraintWithItem: constraintItem     attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeTop            multiplier:1.0000f constant: -MTReportDesignerBorderPadding],
         [NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationGreaterThanOrEqual toItem: nil             attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant: reportSectionHeight],
         [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeRight  relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeRight          multiplier:1.0000f constant: -MTReportDesignerBorderPadding],
         [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeBottom         multiplier:1.0000f constant: -MTReportDesignerBorderPadding],
         [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual              toItem: nil             attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant: MTReportDesignerSectionLabelHeight]
         ]];

        [[self designerScrollView] addConstraint:[NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeLeft  relatedBy: NSLayoutRelationEqual toItem: [self designerContentView] attribute: NSLayoutAttributeLeft  multiplier: 1.0000f constant: MTReportDesignerBorderPadding]];
        [[self designerScrollView] addConstraint:[NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeRight relatedBy: NSLayoutRelationEqual toItem: [self designerContentView] attribute: NSLayoutAttributeRight multiplier: 1.0000f constant: -MTReportDesignerBorderPadding]];
        [[self designerScrollView] addConstraint:[NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationGreaterThanOrEqual toItem: [self designerContentView] attribute: NSLayoutAttributeWidth multiplier: 0.2000f constant: 0.0000f]];
        
        
        if ([[reportSection type] integerValue] == MNSDocumentSectionTypeReportFooter) {
            [self setReportFooterView:collectionView];
        }
        
        [[self sectionViews] setValue:collectionView forKey:collectionViewKey];
        [[self sectionControlViews] setValue:sectionControlView forKey:collectionViewKey];

        [[self designerContentView] addSubview:collectionView];
        [[self designerContentView] addSubview:sectionControlView];

        lastCollectionView = [collectionView retain];
        
        [collectionView release];
        [sectionControlView release];
        [backgroundView release];
        [flowLayoutDesignerSection release];

        sectionCounter++;
    }
    sectionHeights += MTReportDesignerBorderPadding;
    
    [lastCollectionView release];

    [self setRulerView:viewRuler];
    [viewRuler release];

    for (NSLayoutConstraint *layoutConstraint in [[self designerContentView] constraints]) {
        if ([layoutConstraint firstAttribute] ==  NSLayoutAttributeHeight &&
            [layoutConstraint secondItem] == nil &&
            [[layoutConstraint firstItem] isKindOfClass:[MTDocumentSectionView class]]) {
            NSManagedObjectID *objectId = [[layoutConstraint firstItem] objectIdTag];
            NSString *key =[[NSString alloc] initWithString: [[objectId URIRepresentation] absoluteString]];
            NSLayoutConstraint *constraint = [layoutConstraint retain];
            [[self layoutConstraintsReportSectionHeight] setObject:constraint forKey:key];
            [key release];
            [constraint release];
        }
    }
    [[self designerContentView] setBackgroundColor:[UIColor clearColor]];
    [[self designerContentView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint *layoutConstraintDesignerContentViewHeight = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:sectionHeights];
    [self setLayoutConstraintDesignerContentViewHeight:layoutConstraintDesignerContentViewHeight];
    [[self designerScrollView] addConstraint: layoutConstraintDesignerContentViewHeight];
    [[self designerScrollView] addConstraint: [NSLayoutConstraint constraintWithItem:[self designerScrollView] attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f]];
    
    [[self designerScrollView] removeConstraints:@[[self layoutConstraintContainerToDesignerCenterY], [self layoutConstraintContainerToDesignerCenterX], [self layoutConstraintContainerToDesignerVertSpace]]];
    [[self designerScrollView] setScrollEnabled:YES];
    [[self designerScrollView] setMaximumZoomScale:10.0000f];
    [[self designerScrollView] setMinimumZoomScale:1.0000f];
    [[self designerScrollView] setDelegate:self];
    [[self designerScrollView] setUserInteractionEnabled:YES];
    [[self designerScrollView] setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    [[self designerScrollView] setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    [[self designerScrollView] flashScrollIndicators];
    
    [sectionEnumerator release];
}

- (CGSize)designerContentViewSize {
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    CGSize designerContentViewSize = CGSizeMake([[self view] bounds].size.width, CGSizeZero.height);
    designerContentViewSize.height += MTReportDesignerRulerHeight + MTReportDesignerBorderPadding;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        designerContentViewSize.height += MTReportDesignerBorderPadding;
        designerContentViewSize.height += [[reportSection height] floatValue];
    }
    designerContentViewSize.height += MTReportDesignerBorderPadding;
    [sectionEnumerator release];
    return designerContentViewSize;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    CGSize designerContentViewSize = CGSizeMake([[self view] bounds].size.width, CGSizeZero.height);
    designerContentViewSize.height += MTReportDesignerRulerHeight + MTReportDesignerBorderPadding;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        CGFloat height = [[reportSection height] floatValue];
        NSString *key = [reportSection sectionKey];
        NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:key];
        [layoutConstraint setConstant:height];
        designerContentViewSize.height += MTReportDesignerBorderPadding;
        designerContentViewSize.height += [[reportSection height] floatValue];
    }
    designerContentViewSize.height += MTReportDesignerBorderPadding;
    [sectionEnumerator release];

    [[self layoutConstraintDesignerContentViewHeight] setConstant:designerContentViewSize.height];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];


    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidChange:)
                          name: NSManagedObjectContextObjectsDidChangeNotification
                        object: managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(didHideMenuNotification:)
                          name: UIMenuControllerDidHideMenuNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(didShowMenuNotification:)
                          name: UIMenuControllerDidShowMenuNotification
                        object: nil];
    

    [defaultCenter addObserver: self
                      selector: @selector(documentStateChanged)
                          name: UIDocumentStateChangedNotification
                        object: [self activeDocument]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self designerScrollView] setZoomScale:1.0000f animated:animated];
    
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextObjectsDidChangeNotification
                           object: managedObjectContext];
    [defaultCenter removeObserver: self
                             name: NSManagedObjectContextDidSaveNotification
                           object: managedObjectContext];
    [defaultCenter removeObserver: self
                             name: UIMenuControllerDidHideMenuNotification
                           object: nil];
    [defaultCenter removeObserver: self
                             name: UIMenuControllerDidShowMenuNotification
                           object: nil];
    [defaultCenter removeObserver: self
                             name: UIDocumentStateChangedNotification
                           object: [self activeDocument]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showObjects"]) {
        
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            UIPopoverController *popoverController = [[popoverSegue popoverController] retain];
            [self setPopoverControllerObjectSelector:popoverController];
            [popoverController release];
        }
        MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = [segue destinationViewController];
        [viewControllerObjectSelector setObjectSelectorDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"MTSegueShowReportViewer"]) {

        MTReportViewerController *viewControllerReportViewer;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            viewControllerReportViewer = (MTReportViewerController *)[[segue destinationViewController] topViewController];
        } else {
            viewControllerReportViewer = [segue destinationViewController];
        }
        [viewControllerReportViewer setViewControllerDelegate:self];
        [viewControllerReportViewer setDocumentReport:[self activeDocument]];
        
        [[self designerScrollView] scrollRectToVisible:CGRectZero animated:NO];

    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {
        
        MTReportViewerController *viewControllerReportViewer;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            viewControllerReportViewer = (MTReportViewerController *)[[segue destinationViewController] topViewController];
        } else {
            viewControllerReportViewer = [segue destinationViewController];
        }
        [viewControllerReportViewer setViewControllerDelegate:self];
        [viewControllerReportViewer setDocumentReport:[self activeDocument]];
        
        [[self designerScrollView] scrollRectToVisible:CGRectZero animated:NO];
        
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [self designerContentView];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    //[[self view] setNeedsUpdateConstraints];
    [[self rulerView] setNeedsDisplay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    //[[self view] setNeedsUpdateConstraints];
    [[self rulerView] setNeedsDisplay];
}

#pragma mark - Document State

- (void)documentStateChanged {
    UIDocumentState state = [[self activeDocument] documentState];
    switch ([[self activeDocument] documentState]) {
        case UIDocumentStateClosed:
            [self enableUserInteraction:[self view]];
            break;
        case UIDocumentStateInConflict:
            [self enableUserInteraction:[self view]];
            break;
        case UIDocumentStateSavingError:
            [self enableUserInteraction:[self view]];
            break;
        case UIDocumentStateEditingDisabled:
            [self disableUserInteraction:[self view]];
            break;
        case UIDocumentStateNormal:
        default:
            [self enableUserInteraction:[self view]];
            break;
    }
    [[self documentStatusView] setDocumentState: state];
}

- (void)enableUserInteraction:(id)sender {
    if ([sender isKindOfClass:[UIControl class]]) {
        [sender setEnabled:YES];
    } else if ([sender isKindOfClass:[UIView class]]) {
        [sender setUserInteractionEnabled:YES];
        for (UIView *subview in [sender subviews]) {
            [self enableUserInteraction:sender];
        }
    }
    [[self view] setUserInteractionEnabled:NO];
}

- (void)disableUserInteraction:(id)sender {
    if ([sender isKindOfClass:[UIControl class]]) {
        [sender setEnabled:NO];
    } else if ([sender isKindOfClass:[UIView class]]) {
        [sender setUserInteractionEnabled:NO];
        for (UIView *subview in [sender subviews]) {
            [self disableUserInteraction:sender];
        }
    }
    [[self view] setUserInteractionEnabled:NO];
}

#pragma mark - Layout Settings Delegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MAReportDocument *reportDocument = [self activeDocument];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[reportDocument managedObjectContext]];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                forQuery: query];

    [RptqDocumentSection setHeight:height forSectionAtRow:[self lastSelectedSectionControlPanel] inManagedObjectContext: [reportDocument managedObjectContext]];
    UICollectionView *documentSectionView = [[self getSectionViewForDocumentSection: documentSection] retain];

    [documentSection setLayoutHeight:@([[documentSectionView collectionViewLayout] collectionViewContentSize].height)];
    [[reportDocument managedObjectContext] save:nil];
    [reportDocument save:nil];
    
    MTReportDesignerSectionBackgroundView *backgroundView = [[[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]] retain];
    [backgroundView setNeedsDisplay];
    [backgroundView release];
    
    [[documentSectionView collectionViewLayout] invalidateLayout];
    [documentSection setLayoutHeight:@([[documentSectionView collectionViewLayout] collectionViewContentSize].height)];
    [documentSectionView release];

    [[self view] setNeedsUpdateConstraints];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    MAReportDocument *reportDocument = [self activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    [RptqDocumentSection setVisibility: isVisible
                       forSectionAtRow: [self lastSelectedSectionControlPanel]
                inManagedObjectContext: managedObjectContext];
    [managedObjectContext save:nil];
    [reportDocument save:nil];
    
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MAReportDocument *reportDocument = [self activeDocument];
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[reportDocument managedObjectContext]];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                        forQuery: query];
    
    BOOL insertNewSection = numberOfRows > documentSection.numberOfRows.integerValue;
    BOOL deleteLastSection = numberOfRows < documentSection.numberOfRows.integerValue;
    
    __block UICollectionView *documentSectionView = [[self getSectionViewForDocumentSection: documentSection] retain];

    //RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel] forQuery: query];
    
    if ([[documentSection numberOfRows] integerValue] == numberOfRows) {
        
        //No change
        
    } else if (numberOfRows > [[documentSection numberOfRows] integerValue]) {
        
        //Add row
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: [reportDocument managedObjectContext]];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[documentSection hasRows] array]];
        [newRowToAppend setInSection:documentSection];
        [hasRows addObject:newRowToAppend];
        [documentSection setHasRows:hasRows];
        [hasRows release]; hasRows = nil;
        
    } else if (numberOfRows < [[documentSection numberOfRows] integerValue]) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[documentSection hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[documentSection hasRows] array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [documentSection setHasRows:hasRows];
//        [section setNumberOfRows:[[section numberOfRows] integerValue] -1];
        [hasRows release]; hasRows = nil;
        [rowToDelete setInSection:nil];
        
    }
    [documentSection setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
    
    MTReportDesignerSectionBackgroundView *backgroundView = [[[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]] retain];
    [backgroundView setNumberOfRowsInBackground:numberOfRows];
    [backgroundView release];

    NSError *error = nil;
    [[reportDocument managedObjectContext] save:&error];
    
    [reportDocument saveToURL:[reportDocument fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
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

    [documentSectionView release];
    
}

#pragma mark - Section View Delegate

- (void)didUpdateLayout:(id)sender {
    MTDocumentSectionView *documentSectionView = (MTDocumentSectionView *)sender;

    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[documentSectionView objectIdTag] fromObjectContext:managedObjectContext];
    [documentSection setHeight:@([documentSectionView bounds].size.height)];
    

    [self relayoutSectionView:documentSectionView];
    
    [managedObjectContext save:nil];
}

- (void)relayoutSectionView:(MTDocumentSectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [[objectId URIRepresentation] retain];

    NSManagedObjectContext *managedObjectContect = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:objectId fromObjectContext:managedObjectContect];

    NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:[objectIdUrl absoluteString]];
    [layoutConstraint setConstant:documentSection.height.floatValue];
    [objectIdUrl release];
    

    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - Toolbox Delegate

- (void)heightChanged:(CGFloat)newHeight {
    CGSize newSize = CGSizeMake(320.0000f, newHeight);
    [[self popoverControllerInformation] setPopoverContentSize:newSize animated:YES];
    [[[self popoverControllerInformation] contentViewController] setContentSizeForViewInPopover: newSize];

}

#pragma mark - Core Data Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    //BOOL contextSaved = NO;

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
                    
                    
                    UICollectionView *section = [self getSectionViewForDocumentSection: [[documentObject inSectionRow] inSection]];
                    [[section collectionViewLayout] invalidateLayout];
                    
                } else if ([change isEqualToString:NSStringFromSelector(@selector(sizeheight))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(marginBottom))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingTop))] ||
                           [change isEqualToString:NSStringFromSelector(@selector(paddingBottom))]) {
                    
                    UICollectionView *section = [self getSectionViewForDocumentSection: [[documentObject inSectionRow] inSection]];
                    [[section collectionViewLayout] invalidateLayout];
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
                    [[section collectionViewLayout] invalidateLayout];
                } else if ([change isEqualToString:NSStringFromSelector(@selector(numberOfRows))]) {
                    
                }
            }

        }
    }
}

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

- (void)managedObjectContextDidSave:(NSNotification *)notification { }

#pragma mark - Menu Notifications

- (void)didHideMenuNotification:(NSNotification *)notification {
    [[self elementViews] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self didDeselectElementView:obj animated:YES];
    }];
}

- (void)didShowMenuNotification:(NSNotification *)notification { }

#pragma mark - Methods

- (CGRect)rectForSelectedElements {
    CGRect popoverRect = CGRectZero;
    if ([[self selectedObjectIds] count] == 1) {
        MTElementView *elementView = [[self selectedElementViews] anyObject];
        popoverRect = [elementView convertRect:[elementView frame] toView:[self designerContentView]];
    } else if ([[self selectedObjectIds] count] > 1) {
        CGFloat minx = 0.0000f, miny = 0.0000f, maxx = 0.0000f, maxy = 0.0000f;
        NSUInteger counter = 0;
        for (MTElementView *elementView in [self selectedElementViews]) {
            CGRect frame = [elementView convertRect:[elementView frame] toView:[self designerContentView]];
            if (counter == 0) {
                minx = frame.origin.x;
                miny = frame.origin.y;
                maxx = frame.origin.x + frame.size.width;
                maxy = frame.origin.y + frame.size.height;
            } else {
                minx = minx < frame.origin.x ? minx : frame.origin.x;
                miny = miny < frame.origin.y ? miny : frame.origin.y;
                maxx = maxx > frame.origin.x + frame.size.width ? maxx : frame.origin.x + frame.size.width;
                maxy = maxy > frame.origin.y + frame.size.height ? maxy : frame.origin.y + frame.size.height;
            }
            counter++;
        }
        popoverRect = CGRectMake(minx, miny, maxx - minx, maxy - miny);
    }
    return popoverRect;
}

#pragma mark - MTElementViewDelegate

- (void)sizeChanged:(id)sender {
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[reportSection identifier] integerValue]];
        if ([(UIView *)sender isDescendantOfView: documentSectionView]) {
            [[documentSectionView collectionViewLayout] invalidateLayout];
        }
    }
    [(MTElementView *)sender updateDisplayLabel];
    [sender setNeedsDisplay];
    [sectionEnumerator release];
}

- (void)didSelectElementView:(id)sender {
    
    NSUInteger deselectedSectionViewCounter = 0;
    //Remove border from the section views
    for (UIView *view in [[self sectionControlViews] objectEnumerator]) {
        deselectedSectionViewCounter += [self  removeBorderFromView:view] ? 1 : 0;
    }
    
    if (deselectedSectionViewCounter == 0) {

        if ([UIDevice isPad] == NO) {
            if (![self dismissAllPopovers]) {
                [self showToolbox:MTToolboxTypeElement];
            }
        }
        
        if ([sender isKindOfClass:[MTElementView class]]) {
            MTElementView *elementView = sender;
            
            NSManagedObjectID *objid = [elementView objectIdTag];
            if (objid != nil) {
                if ([objid isTemporaryID]) {
                    // FIXME: If temporary id.
                    MTLog(@"Fix HERE");
                }
            }
            
            [[self selectedObjectIds] addObject:[elementView objectIdTag]];
            [self applyBorderToView:elementView];
            [elementView setDisplaySelected:YES];
            
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
            if ([UIDevice isPad]) {
                
                NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
                [passThroughViews addObject:elementView];
                [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
                [passThroughViews release];
                
                CGRect popoverRect = CGRectZero;
                if ([[self selectedObjectIds] count] == 1) {
                    popoverRect = [elementView convertRect:[elementView frame] toView:[self designerContentView]];
                } else if ([[self selectedObjectIds] count] > 1) {
                    CGFloat minx = 0.0000f, miny = 0.0000f, maxx = 0.0000f, maxy = 0.0000f;
                    NSUInteger counter = 0;
                    for (MTElementView *elementView in [self selectedElementViews]) {
                        CGRect frame = [elementView convertRect:[elementView frame] toView:[self designerContentView]];
                        if (counter == 0) {
                            minx = frame.origin.x;
                            miny = frame.origin.y;
                            maxx = frame.origin.x + frame.size.width;
                            maxy = frame.origin.y + frame.size.height;
                        } else {
                            minx = minx < frame.origin.x ? minx : frame.origin.x;
                            miny = miny < frame.origin.y ? miny : frame.origin.y;
                            maxx = maxx > frame.origin.x + frame.size.width ? maxx : frame.origin.x + frame.size.width;
                            maxy = maxy > frame.origin.y + frame.size.height ? maxy : frame.origin.y + frame.size.height;
                        }
                        counter++;
                    }
                    popoverRect = CGRectMake(minx, miny, maxx - minx, maxy - miny);
                }
                [[self popoverControllerInformation] presentPopoverFromRect: popoverRect
                                                                     inView: [self designerContentView]
                                                   permittedArrowDirections: UIPopoverArrowDirectionAny
                                                                   animated: YES];
            }
        }

    } else {
        [self hideToolbox];
    }
    
}

- (void)didDeselectElementView:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MTElementView class]]) {
        MTElementView *elementView = sender;
        [[self selectedObjectIds] removeObject:[elementView objectIdTag]];
        [self removeBorderFromView: elementView];
        [elementView setDisplaySelected:NO];
        [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
        if ([UIDevice isPad]) {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
            [passThroughViews removeObject:elementView];
            [passThroughViews release];
            
            if ([[self popoverControllerInformation] isPopoverVisible]) {   //Should always eval to true
                if ([[self selectedObjectIds] count] > 0) {
                    CGRect popoverRect = [self rectForSelectedElements];
                    [[self popoverControllerInformation] presentPopoverFromRect:popoverRect inView:[self designerContentView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
                } else {
                    [[self popoverControllerInformation] dismissPopoverAnimated:animated];
                }
            }
        } else {
            if ([[self selectedObjectIds] count] == 0) {
                [self hideToolbox];
            }
        }
    }
}

- (void)didHighlightElementView:(id)sender { }
- (void)didUnhighlightElementView:(id)sender { }

#pragma mark - Actions

- (void)toggleSectionControlPanel:(UITapGestureRecognizer *)sender {
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        
        if ([[self selectedElementViews] count] >= 1) {
            [self deselectAllElementsAnimated:YES];
            [self hideToolbox];
        } else {
            
            
            if ([self isBorderAppliedToView:[sender view]]) {
                
                [self removeBorderFromView:[sender view]];
                if ([UIDevice isPad]) {
                    
                    if ([[self popoverControllerSectionSettings] isPopoverVisible]) {
                        [[self popoverControllerSectionSettings] dismissPopoverAnimated:YES];
                    }
                } else {
                    [self hideToolbox:self];
                }
                
            } else {
                
                [self deselectAllElementsAnimated:YES];
                
                [self applyBorderToView:[sender view]];
                
                [self setLastSelectedSectionControlPanel:[[sender view] tag]];
                
                NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
                RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
                RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                RptqQuery *query = [[database hasQueries] anyObject];
                RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                    forQuery: query];
                [[self viewControllerSectionLayoutSettings] setInitalStepperValue:([[section height] floatValue])];
                [[self viewControllerSectionLayoutSettings] setInitalSwitchValue:[[section visibility] boolValue]];
                [[self viewControllerSectionLayoutSettings] setInitalNumberOfRows:[[section numberOfRows] integerValue]];
                [[self viewControllerSectionLayoutSettings] updateDisplay];
                
                if ([UIDevice isPad]) {
                    
                    [[self popoverControllerSectionSettings] setPassthroughViews:@[[sender view]]];
                    [[self popoverControllerSectionSettings] presentPopoverFromRect:[[sender view] bounds]
                                                                             inView:[sender view]
                                                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                           animated:YES];
                    
                } else {
                    [self showToolbox:MTToolboxTypeSection];
                }
            }
            
        }
        
    } else {
        
    }
}

- (void)deselectAllElementsAnimated:(BOOL)animated {

    //Remove border from element views
    for (MTElementView *elementView in [self selectedElementViews]) {
        [self didDeselectElementView:elementView animated:animated];
    }

    //Remove border from the section views
    for (UIView *view in [[self sectionControlViews] objectEnumerator]) {
        [self  removeBorderFromView:view];
    }

}

- (void)applyBorderToView:(UIView *)view {
    [[view layer] setBorderColor:[[UIColor redColor] CGColor]];
    [[view layer] setBorderWidth:2.0000f];
}

- (BOOL)removeBorderFromView:(UIView *)view {
    BOOL result;
    if ([self isBorderAppliedToView:view]) {
        result = YES;
        [[view layer] setBorderColor:[[UIColor blackColor] CGColor]];
        [[view layer] setBorderWidth:1.0000f];
    } else {
        result = NO;
    }
    return result;
}

- (BOOL)isBorderAppliedToView:(UIView *)view {
    return ([[view layer] borderWidth] > 1.5000f);
}

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if ([UIDevice isPad]) {
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:2];
        if ([self popoverControllerInformation] != nil) [allpopovers addObject:[self popoverControllerInformation]];
        if ([self popoverControllerObjectSelector] != nil) [allpopovers addObject:[self popoverControllerObjectSelector]];
        if ([self popoverControllerSectionSettings] != nil) [allpopovers addObject:[self popoverControllerSectionSettings]];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if ([popoverController isPopoverVisible]) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }
        [allpopovers release];
        [self deselectAllElementsAnimated:YES];
    }
    return result;
}

- (NSSet *)elementViews {
    
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:
                                     [[self activeDocument] managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        MTDocumentSectionView *documentSectionView = [[self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]] retain];
        
        NSInteger numberOfSectionsInCollectionView = [documentSectionView numberOfSections];
        
        for (NSUInteger section = 0; section < numberOfSectionsInCollectionView; section++) {
            NSInteger numberOfItemsInSection = [documentSectionView numberOfItemsInSection:section];
            
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                MTElementView *elementView = [[self elementViewAtIndexPath: [NSIndexPath indexPathForItem:item inSection:section]
                                                          inCollectionView: documentSectionView] retain];
                
                if (elementView != nil) {
                    [results addObject:elementView];
                }
                [elementView release];
            }
        }
        [documentSectionView release];
    }
    [enumerator release];
    return [results autorelease];
}

- (MTDocumentSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifer {
    MTDocumentSectionView *documentSectionView = nil;
    for (id subview in [[self designerContentView] subviews]) {
        if ([subview tag] == identifer && [subview isKindOfClass:[MTDocumentSectionView class]]) {
            documentSectionView = [subview retain];
            break;
        }
    }
    return [documentSectionView autorelease];
}

- (NSSet *)selectedElementViews {

    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        MTDocumentSectionView *documentSectionView = [[self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]] retain];
        
        for (NSUInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
            for (NSUInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
                MTElementView *elementView = [self elementViewAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] inCollectionView:documentSectionView];
                if ([[self selectedObjectIds] containsObject: [elementView objectIdTag]]) {
                    [results addObject:elementView];
                }
            }
        }
        [documentSectionView release];
    }
    [enumerator release];
    
    return [results autorelease];

}

- (UICollectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return [[self sectionViews] objectForKey:[documentSection sectionKey]];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return [[self sectionControlViews] objectForKey:[documentSection sectionKey]];
}

- (IBAction)done:(id)sender {
    if (![self dismissAllPopovers]) {
        [[self delegate] viewControllerDidFinish:@(NO)];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (IBAction)doneReports:(id)sender {
    if (![self dismissAllPopovers]) {
        [[self delegate] viewControllerDidFinish:@(YES) animated:NO];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (IBAction)showObjects:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showObjects" sender:sender];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (IBAction)info:(id)sender {
    if (![self dismissAllPopovers]) {
        [self showToolbox:MTToolboxTypeElement];
    }
}

- (IBAction)showToolbox:(MTToolboxType)tooboxType {
    
    UIViewController *viewController;

    switch (tooboxType) {

        case MTToolboxTypeElement:
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
            viewController = [[self viewControllerToolbox] retain];
            break;
            
        case MTToolboxTypeSection: {
            viewController = [[self navigationControllerSectionLayoutSettings] retain];
            [[self navigationControllerSectionLayoutSettings] setNavigationBarHidden:NO animated:NO];
            break;
        }
        default:
            break;
    }
    
    [[viewController view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.toolboxView.frame.size.width, self.toolboxView.frame.size.height)];
    [[viewController view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];

    if ([[viewController view] superview] == nil) {
        [[self toolboxView] addSubview:[viewController view]];
    }
    
    if ([UIDevice isPad]) {
        [[self popoverControllerInformation] presentPopoverFromBarButtonItem:[self barButtonItemInfo]
                                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                    animated:YES];
    } else {
        
        if ([self toolboxIsVisible] == NO) {
            [self setToolboxIsVisible:YES];
            [[self informationButton] setEnabled: NO];
            
            [[self toolbarBottom] setItems:nil animated:YES];
            [[self toolbarTop] setItems:nil animated:YES];
                        
            [[self view] layoutIfNeeded];
            
            [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
                [self setWantsFullScreenLayout:YES];
                [[self view] removeConstraints:[self layoutConstraintsToolboxHidden]];
                [[self view] addConstraints:[self layoutConstraintsToolboxVisiable]];
                [[self view] layoutIfNeeded];
            } completion:^(BOOL finished) {
                
                if (finished) {
                    
                    CGRect rectToShow = CGRectZero;
                    
                    if (tooboxType == MTToolboxTypeSection) {
                        
                        MAReportDocument *reportDocument = [self activeDocument];
                        
                        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[reportDocument managedObjectContext]];
                        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                        RptqQuery *query = [[database hasQueries] anyObject];
                        RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                                    forQuery: query];
                        
                        UIView *selectedSectionView = [self getSectionViewForDocumentSection:documentSection];
                        
                        rectToShow = selectedSectionView.frame;
                        
                    } else if (tooboxType == MTToolboxTypeElement) {
                        rectToShow = [self rectForSelectedElements];
                    }

                    if (CGRectIntersectsRect(rectToShow, self.designerScrollView.frame) == NO) {
                        
                        CGFloat offsetPointY = rectToShow.origin.y + rectToShow.size.height + 5.0000f - [[self designerScrollView] frame].size.height;
                        CGPoint offsetPoint = CGPointMake(CGPointZero.x, offsetPointY);
                        [[self designerScrollView] setContentOffset:offsetPoint animated:YES];
                        
                    }
                }            
            }];
        }
    }
    
    [viewController release];
    
}

- (void)hideToolbox {
    if ([UIDevice isPad]) {
        if ([[self popoverControllerInformation] isPopoverVisible]) {
            [[self popoverControllerInformation] dismissPopoverAnimated:YES];
        }
        if ([[self popoverControllerSectionSettings] isPopoverVisible]) {
            [[self popoverControllerSectionSettings] dismissPopoverAnimated:YES];
        }
        [self deselectAllElementsAnimated:YES];
    } else {
        [self hideToolbox:self];
    }
}

- (IBAction)hideToolbox:(id)sender {
    if ([UIDevice isPad]) {
        [self dismissAllPopovers];
    } else {
        if ([self toolboxIsVisible]) {
            [self setToolboxIsVisible:NO];
            
            [[self view] layoutIfNeeded];
            [[self navigationControllerSectionLayoutSettings] setNavigationBarHidden:YES animated:YES];
            [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
                [[self view] removeConstraints:[self layoutConstraintsToolboxVisiable]];
                [[self view] addConstraints:[self layoutConstraintsToolboxHidden]];
                [[self view] layoutIfNeeded];
                
            } completion:^(BOOL finished) {
                if (finished) {
                    if ([[[self navigationControllerSectionLayoutSettings] view] superview] != nil) {
                        [[[self navigationControllerSectionLayoutSettings] view] removeFromSuperview];
                    }
                    if ([[[self viewControllerToolbox] view] superview] != nil) {
                        [[[self viewControllerToolbox] view] removeFromSuperview];
                    }
                    [[self toolbarBottom] setItems:[self toolbarBottomItems] animated:YES];
                    [[self toolbarTop] setItems:[self toolbarTopItems] animated:YES];
                    [[self informationButton] setEnabled: YES];
                }
            }];
            [self deselectAllElementsAnimated:YES];
        }
    }
}

- (void)dismissObjectSelectorViewController {
    if ([UIDevice isPad]) {
        if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
            [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
        }
    } else {
        [[self designerScrollView] setContentOffset:CGPointZero animated:NO];
        [self dismissViewControllerAnimated:YES completion:^{
        
        }];
    }
}

- (void)resizeCollectionView:(UICollectionView *)collectionView forSectionWithId:(NSManagedObjectID *)sectionObjectId {
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForObjectID:sectionObjectId fromObjectContext:managedObjectContext];
    //[self relayoutSectionView:section];
    CGSize contentSize = [(MTReportDesignerSectionViewLayoutLiquid *)[collectionView collectionViewLayout] collectionViewContentSize];
    [section setLayoutHeight:@(contentSize.height)];
    [section setHeight:@(contentSize.height + 44.0000f)];
    NSError *error = nil;
    [managedObjectContext save:&error];
    if (error != nil) {
        [error presentErrorToUser];
    }
    
    [[self designerContentView] setNeedsLayout];
    [[self view] setNeedsUpdateConstraints];

}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self deselectAllElementsAnimated:YES];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    return result;
}

#pragma mark -
#pragma mark MTCollectionViewCellElement Delegate

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = [cell objectIdTag];
    [self removeCollectionViewCellForElementView:objectId completion:^(BOOL finished) {
        if (finished) {
            NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            [RptqDocumentObject removeDocumentObject:documentObject];
        }
    }];
}

#pragma mark -
#pragma mark Collection View Layout Delegate

- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView {
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    return [[documentSection height] floatValue];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = [documentObject viewSize];
    } else {
        result = CGSizeZero;
    }

    return result;
}

- (MTCollectionViewLayoutLiquidAttributes *)collectionView: (UICollectionView *)collectionView
                                                    layout: (UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {

    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    MTCollectionViewLayoutLiquidAttributes *result = [[MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath] retain];
    
    if ([objects count] > [indexPath item]) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath item]];
        [result setDropPoint: CGPointMake([[documentObject dropPointX] floatValue], [[documentObject dropPointY] floatValue])];
        [result setFrame:CGRectMake(result.dropPoint.x, result.dropPoint.y, documentObject.viewSize.width, documentObject.viewSize.height)];
        [result setLastTouchPoint: CGPointMake([[documentObject touchPointX] floatValue], [[documentObject touchPointY] floatValue])];
        [result setDropIndex: [[documentObject dropIndex] integerValue]];
        [result setDescription:[documentObject toStringHumanReadable]];
    } else {
        [result setDropPoint: CGPointZero];
        [result setLastTouchPoint:CGPointZero];
        [result setDropIndex:0];
        [result setFrame:CGRectZero];
    }
    [result setLastTouchPointValid: NO];

    return [result autorelease];
}

- (NSUInteger)collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];

    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    NSUInteger dropIndex = 0;
    if ([objects count] > [indexPath row]) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath row]];
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

    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];

    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
        
    if ([objects count] > row) {
        NSError *error;

        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [documentObject setDropPointX:@(dropPoint.x)];
        [documentObject setDropPointY:@(dropPoint.y)];
        [[documentObject managedObjectContext] save:&error];
    }
}


#pragma mark Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    NSString *resuseId = [[self collectionViewReuseIdentifiers] objectForKey:[documentSection identifier]];
    MTCollectionViewCellElement *cell = [[collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath] retain];
    [cell setDelegate:self];
    if ([objects count] > [indexPath row]) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath row]];
    
        CGSize documentObjectSize = [documentObject viewSize];
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
                if ([[documentObject objectID] isTemporaryID]) {
// FIXME: What's happening here.
                }
                
                
                [cell setBackgroundColor:[UIColor clearColor]];
                [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                MTElementView *elementView = [[self elementViewForObjectId:[documentObject objectID]
                                                                inContext:managedObjectContext] retain];
                [elementView setFrame:cellFrame];
                [elementView setContainer: cell];
                [elementView setContainerGroup: collectionView];
                                
                [cell setTag:[[documentObject identifier] integerValue] + 3838];
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];
                
                [elementView release];

                break;
            }
        }
    }
    
    return [cell autorelease];
}

- (MTElementView *)elementViewForObjectId:(NSManagedObjectID *)objectId inContext:(NSManagedObjectContext *)objectContext {
    MTElementView *elementView = [[MTElementView alloc] initWithObjectId:objectId
                                                         inObjectContext:objectContext];
    [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[elementView layer] setBorderWidth:1.0000f];
    [elementView setDelegate:self];
    [elementView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[elementView layer] setCornerRadius: MTReportDesignerCornerRadius];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
    [panGesture setMaximumNumberOfTouches:1];

    //UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchPiece:)];
    
    [panGesture setDelegate:self];
    //[pinchGesture setDelegate:self];
    
    
    [[[self designerScrollView] panGestureRecognizer] requireGestureRecognizerToFail:panGesture];
    //[[[self designerScrollView] pinchGestureRecognizer] requireGestureRecognizerToFail:pinchGesture];
    
    [elementView addGestureRecognizer:panGesture];
    //[elementView addGestureRecognizer:pinchGesture];
    
    [panGesture release];
    //[pinchGesture release];

    return [elementView autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    return [objects count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionReuseableViewDefault *result = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        [label setText:@"Header"];
        [result addSubview:label];
        [label release];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        [label setText:@"Footer"];
        [result addSubview:label];
        [label release];
    } else {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
    }
    return result;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[self activeDocument] managedObjectContext]];
    return [[documentSection hasRows] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[self activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    return [objects count];
}

#pragma mark Collection View Delegate

- (MTElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath
                         inCollectionView:(UICollectionView *)collectionView {

    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    MTElementView *result = nil;
    
    for (id elementView in [[cell contentView] subviews]) {
        if ([elementView isKindOfClass:[MTElementView class]]) {
            result = [elementView retain];
            break;
        }
    }

    return [result autorelease];

}

- (NSSet *)selectedObjectIdsInCollectionView:(UICollectionView *)collectionView {

    NSMutableSet *result = [[NSMutableSet alloc] init];
    
    for (NSUInteger section = 0; section < [collectionView numberOfSections]; section++) {
    
        for (NSUInteger item = 0; item < [collectionView numberOfItemsInSection:section]; item++) {
        
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            
            if ([cell isSelected]) {
                MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
                [result addObject:[elementView objectIdTag]];
            }
        }
    }

    return [result autorelease];

}

- (NSSet *)selectedObjectIdsCalculated {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self activeDocument] managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        MTDocumentSectionView *documentSectionView = [[self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]] retain];
        
        NSArray *selectedObjects = [[self selectedObjectIdsInCollectionView:documentSectionView] allObjects];
        [results addObjectsFromArray: selectedObjects];
        [documentSectionView release];
    }
    [enumerator release];
    return [results autorelease];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:)) {
        result = YES;
    }
    return result;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [self performSelector:action withObject:documentObject];
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

#pragma mark - Delegates
#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[MTSettingsViewController class]]) {
        [[self designerScrollView] setZoomScale:1.0000f animated:NO];
        //[[self designerScrollView] setContentOffset:CGPointZero animated:NO];
        [self dismissViewControllerAnimated:YES completion:^{
            [[self view] setNeedsUpdateConstraints];
            [[self designerContentView] setNeedsLayout];
            [[self designerContentView] setNeedsDisplay];
        }];
    } else {
        if ([UIDevice isPad]) {
            if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
                [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
            } else {
                [[self designerScrollView] setZoomScale:1.0000f animated:NO];
                //[[self designerScrollView] setContentOffset:CGPointZero animated:NO];
                [self dismissViewControllerAnimated:YES completion:^{
                    [[self view] setNeedsUpdateConstraints];
                    [[self designerContentView] setNeedsLayout];
                    [[self designerContentView] setNeedsDisplay];
                }];
            }
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                //[[self designerScrollView] setZoomScale:1.0000f animated:NO];
                //[[self designerScrollView] setContentOffset:CGPointZero animated:NO];
                //[[self view] setNeedsUpdateConstraints];
                //[[self designerContentView] setNeedsLayout];
                [[self designerContentView] setNeedsDisplay];
            }];
        }
    }
}

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
    [self insertDocumentObjectWithDefination:
     @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
           MTDocumentObjectDefinationObject : [field objectID]}];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber {

    NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeAggregate),
                                               MTDocumentObjectDefinationObject :  @{MTDocumentObjectDefinationAggregateType : @(functionType),
                                                                                     MTDocumentObjectDefinationAggregatePivotNumber : groupNumber,
                                                                                     MTDocumentObjectDefinationAggregatePivotType : @(groupType),
                                                                                     MTDocumentObjectDefinationAggregateObjectId : inputObject,
                                                                                     MTDocumentObjectDefinationAggregateFunctionInputType : @(inputType)}};

    [self insertDocumentObjectWithDefination: documentObjectDefination];
}

- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
    [self insertDocumentObjectWithDefination:
        @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelStatic),
           MTDocumentObjectDefinationObject : labelText}];

}

- (void)insertDocumentObjectNewImage:(UIImage *)image {
    [self insertDocumentObjectWithDefination:
        @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeImage),
           MTDocumentObjectDefinationObject : image}];
}

- (void)insertDocumentObjectWhitespace {
    [self insertDocumentObjectWithDefination:
     @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeWhtiespace)}];
    [self dismissObjectSelectorViewController];
}

- (void)insertDocumentObjectNewFormula {
    [self dismissObjectSelectorViewController];
    
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];

}

- (void)insertDocumentObjectNewChart {
    [self dismissObjectSelectorViewController];

    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];

}
- (void)insertDocumentObjectNewHyperlink {
    [self dismissObjectSelectorViewController];

    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];

}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {

    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDocumentSection *section = [document hasDetailSection];
    //NSManagedObjectID *sectionID = [section objectID];
    
    __block UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];
    
    [detailSection performBatchUpdates:^{
        
        MAReportDocument *reportDocument = [self activeDocument];
        NSManagedObjectContext *managedObjectContextBlock = [reportDocument managedObjectContext];
        
        
        RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination
                                                                        toDocument:document];
        [documentObject obtainPermanentID];
        
        NSError *error = nil;
        [managedObjectContextBlock save:&error];
        [detailSection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            //[self relayoutSectionView:detailSection];
            [UIView animateWithDuration:0.3 animations:^{
                [detailSection invalidateIntrinsicContentSize];
                RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [detailSection objectIdTag]
                                                                                        fromObjectContext: [[self activeDocument] managedObjectContext]];
                [documentSection setHeight:@([detailSection intrinsicContentSize].height)];
                [[self designerContentView] setNeedsUpdateConstraints];
            }];
            //[[self designerContentView] setNeedsLayout];
            //[self resizeCollectionView:detailSection forSectionWithId:[detailSection objectIdTag]];
//            [detailSection setNeedsUpdateConstraints];
//            [detailSection setNeedsLayout];
        }
        
    }];
    
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [[gestureRecognizer view] isEqual:[otherGestureRecognizer view]] == NO  &&
            [[gestureRecognizer view] isEqual:[self designerScrollView]] == NO &&
            [[otherGestureRecognizer view] isEqual:[self designerScrollView]] == NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    MTLog(@"Gesture: %@", gestureRecognizer);
    return YES;
}

- (void)removeCollectionViewCellForElementView:(NSManagedObjectID *)elementViewId
                                    completion:(void (^)(BOOL finished))completion {
    
    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:elementViewId fromObjectContext:managedObjectContext];
    
    RptqDocumentSection *section = [[documentObject inSectionRow] inSection];
    UICollectionView *svSection = [self getSectionViewForDocumentSection:section];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
    
    
    BOOL found = NO;
    NSUInteger deleteSection = 0;
    
    for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
        
        NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [row hasObjects]];
        NSUInteger deleteIndex = 0;
        
        
        for (RptqDocumentObject *object in hasObjects) {
            
            if ([[object objectID] isEqual: elementViewId]) {
                found = YES;
                break;
            }
            
            deleteIndex++;
        }
        
        if (found) {
            
            [svSection performBatchUpdates:^{
                
                RptqDocumentObject *objectToDelete = [hasObjects objectAtIndex:deleteIndex];
                [objectToDelete setInSectionRow:nil];
                [hasObjects removeObjectAtIndex:deleteIndex];
                RptqDocumentSectionRows *row = [[documentSection hasRows] objectAtIndex: deleteSection];
                [row setHasObjects:hasObjects];
                [[self activeDocument] saveContext];
                NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: deleteSection];
                
                [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                
            } completion:^(BOOL finished) {
                if (finished) {
                    [self resizeCollectionView:svSection];
                    completion(YES);
                }
            }];
        }
        
        [hasObjects release];
        if (found) {
            break;
        }
        found = NO;     // FIXME: Short circut this?
        deleteSection++;
    }
}

- (void)pinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan: {
            if ([gestureRecognizer numberOfTouches] >= 2) {
                [self setPinchBeginTransform:[[gestureRecognizer view] transform]];
                CGPoint locationA = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint locationB = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                [self addPointA:locationA andPointB:locationB];
                [self setPinchInitalPointA:locationA];
                [self setPinchInitalPointB:locationB];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if ([gestureRecognizer numberOfTouches] >= 2) {
                CGPoint newTouchA = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint newTouchB = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                [self addPointA:newTouchA
                      andPointB:newTouchB];
                
                CGFloat differenceX = fabsf([self pinchInitalPointA].x - [self pinchInitalPointB].x);
                CGFloat differenceY = fabsf([self pinchInitalPointA].y - [self pinchInitalPointB].y);
                
                CGFloat newDifferenceX = fabsf(_currentNewPointAX - _currentNewPointBX);
                CGFloat newDifferenceY = fabsf(_currentNewPointAY - _currentNewPointBY);
                CGFloat scaleWidth = differenceX != 0 ? newDifferenceX / differenceX : 1.0000f;
                CGFloat scaleHeight = differenceY != 0 ? newDifferenceY / differenceY : 1.0000f;
                gestureRecognizer.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleWidth, scaleHeight);
                gestureRecognizer.scale = 1.0000f;
                
                _currentScaleSize = CGSizeMake(scaleWidth, scaleHeight);
                
                //Save off the size to use at the end.
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            gestureRecognizer.view.transform = [self pinchBeginTransform];
            [(MTElementView *)[gestureRecognizer view] updateDisplayLabel];
            [[gestureRecognizer view] setNeedsDisplay];
            gestureRecognizer.scale = 1.0000f;
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[(MTElementView *)[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
            CGFloat sizeWidth = nearbyintf(_currentScaleSize.width * [[documentObject sizewidth] floatValue]);
            CGFloat sizeHeight = nearbyintf(_currentScaleSize.height * [[documentObject sizeheight] floatValue]);
            MTElementView *elementView = (MTElementView *)[gestureRecognizer view];
            [elementView setTransform: CGAffineTransformScale(CGAffineTransformIdentity, _currentScaleSize.width, _currentScaleSize.height)];
            [documentObject setSizewidth:@(sizeWidth)]; [documentObject setSizeheight:@(sizeHeight)];
            [managedObjectContext save:nil];
//            [elementView setTransform: CGAffineTransformIdentity];
            //[elementView setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, sizeWidth, sizeHeight)];
            
            
            
            //UIView *parentView = [[gestureRecognizer view] superview];
            //[[gestureRecognizer view] removeFromSuperview];
            //[documentObject performSelector:@selector(setSizewidth:) withObject:@(sizeWidth)];
            //MTElementView *elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID] inObjectContext:[documentObject managedObjectContext]];
            //[parentView addSubview:elementView];
            gestureRecognizer.scale = 1.0000f;
            //MTElementView *elementView = (MTElementView *)[gestureRecognizer view];
            //[elementView updateDisplayLabel];
            ///[elementView setNeedsLayout];
            //MTCollectionViewCellElement *cell = [[elementView container] retain];
            //[cell setNeedsLayout];
            //[cell setNeedsDisplay];
            //[cell release];
            dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            
            dispatch_async(queuePriorityBackground, ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UICollectionView *collectionView = [[elementView containerGroup] retain];
                    [[collectionView collectionViewLayout] invalidateLayout];
                    [collectionView release];
                    dispatch_async(queuePriorityBackground, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [elementView setNeedsLayout];
                            [elementView setNeedsDisplay];
                        });
                    });
                });
            });
            break;
        }
    }
}

- (void)addPointA:(CGPoint)pointA andPointB:(CGPoint)pointB {
    _currentNewPointAX *= previousScaleWeight;
    _currentNewPointAX += (1 - previousScaleWeight) * pointA.x;
    _currentNewPointAY *= previousScaleWeight;
    _currentNewPointAY += (1 - previousScaleWeight) * pointA.y;
    _currentNewPointBX *= previousScaleWeight;
    _currentNewPointBX += (1 - previousScaleWeight) * pointB.x;
    _currentNewPointBY *= previousScaleWeight;
    _currentNewPointBY += (1 - previousScaleWeight) * pointB.y;
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    //CGPoint adjustedCenter = [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designerContentView]];
            [[gestureRecognizer view] setCenter: newCenter];
            [[gestureRecognizer view] setAlpha:0.6000f];
            
            [[self designerContentView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designerContentView]];
            [self setScrollersEnabled: NO];

            [[gestureRecognizer view] setCenter: newCenter];

            {
                [self removeCollectionViewCellForElementView:[[gestureRecognizer view] objectIdTag] completion:^(BOOL finished) {
                    if (finished) {
                        CGPoint newCenter = [gestureRecognizer locationInView:[self designerContentView]];
                        [[gestureRecognizer view] setCenter: newCenter];
                        [[self designerScrollView] addSubview: [gestureRecognizer view]];
                    }

                }];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self designerContentView]];
            [[gestureRecognizer view] setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStatePossible: {    // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible

            break;
        }
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded

            [[gestureRecognizer view] setAlpha:1.0000f];
            
            // Remove the element from one section and place it into the next new section
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designerContentView]];
            UICollectionView *reportSectionCollectionView = nil;
            
            // Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designerContentView] subviews]) {
                if (CGRectContainsPoint([view frame], [[gestureRecognizer view] center]) && ![view isEqual:self]) {
                    if ([view isKindOfClass:[UICollectionView class]]) {
                        reportSectionCollectionView = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = [gestureRecognizer locationInView:reportSectionCollectionView];
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            if (!addedToNewParent) {
                for (UICollectionView *view in [[self designerContentView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        reportSectionCollectionView = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = CGPointMake([gestureRecognizer view].frame.size.width / 2.0000f, [gestureRecognizer view].frame.size.height / 2.0000f);
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            
            if (addedToNewParent) {
                newCenter = CGPointRoundPointToGrid(newCenter);
                [[gestureRecognizer view] setCenter: newCenter];
                
                [reportSectionCollectionView performBatchUpdates:^{

                    NSManagedObjectContext *managedObjectContext = [[self activeDocument] managedObjectContext];
                    
                    NSManagedObjectID *objectId = [[gestureRecognizer view] objectIdTag];
                    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID: objectId
                                                                                 fromObjectContext: managedObjectContext];
                    
                    [documentObject setOriginx: @([gestureRecognizer view].frame.origin.x)];
                    [documentObject setOriginy: @([gestureRecognizer view].frame.origin.y)];
                    
                    [[gestureRecognizer view] removeFromSuperview];
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [reportSectionCollectionView objectIdTag]
                                                                                            fromObjectContext: managedObjectContext];
                    
                    NSUInteger sectionZero = 0;
                    RptqDocumentSectionRows *sectionRow = [[documentSection hasRows] objectAtIndex: sectionZero];

                    CGPoint pointInView = [[gestureRecognizer view] frame].origin;
                    CGPoint touchPointInView = [gestureRecognizer locationInView:reportSectionCollectionView];
                    
                    [documentObject setDropPointX:@(pointInView.x)];
                    [documentObject setDropPointY:@(pointInView.y)];
                    
                    [documentObject setTouchPointX:@(touchPointInView.x)];
                    [documentObject setTouchPointY:@(touchPointInView.y)];
                    
                    NSUInteger dropIndex = [documentSection nextDropIndexForSection];
                    [documentObject setDropIndex:@(dropIndex)];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[[sectionRow hasObjects] count]
                                                                 inSection:sectionZero];
                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[sectionRow hasObjects]];
                    
                    
                    [hasObjects insertObject:documentObject atIndex:[indexPath item]];
                    
                    
                    
                    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
                    
                    for (NSIndexPath *indexPath in indexPaths) {
                        NSMutableDictionary *holderForLastTouches = [[self holderForLastTouchesByCollectionView] objectForKey:@([reportSectionCollectionView tag])];

                        [holderForLastTouches setObject:[NSValue valueWithCGPoint:pointInView] forKey:indexPath];

                    }
                    
                    [sectionRow setHasObjects:hasObjects];
                    
                    [managedObjectContext save:nil];
                    
                    [reportSectionCollectionView insertItemsAtIndexPaths:indexPaths];
                   
                    [hasObjects release];

                } completion:^(BOOL finished) {
                    if (finished) {
                        [self resizeCollectionView:reportSectionCollectionView];
                    }
                }];
                
            }
            [self setScrollersEnabled:YES];
            [[gestureRecognizer view] setNeedsDisplay];

            break;
        }
        default:
            break;
    }
}

- (void)resizeCollectionView:(UICollectionView *)collectionView {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: [[self activeDocument] managedObjectContext]];
    [documentSection setHeight:@([collectionView intrinsicContentSize].height)];
    [UIView animateWithDuration:0.6666f animations:^{
        [collectionView invalidateIntrinsicContentSize];
        [[self designerContentView] setNeedsUpdateConstraints];
    }];
}

- (BOOL)checkAndUpdateHeightForSection:(RptqDocumentSection *)documentSection forHeight:(CGFloat)height {
    BOOL heightUpdated;
    CGFloat sectionHeight = [[documentSection height] floatValue] / [[documentSection numberOfRows] integerValue];
    if (height > sectionHeight) {
        [documentSection setHeight:@(height * [[documentSection numberOfRows] integerValue])];
        [[documentSection managedObjectContext] save:nil];
        heightUpdated = YES;
    } else {
        heightUpdated = NO;
    }
    return heightUpdated;
}

- (void)setScrollersEnabled:(BOOL)enabled {
    @synchronized([self designerScrollView]) {
        if ([[self designerScrollView] respondsToSelector:@selector(setScrollEnabled:)]) {
            [[self designerScrollView] setScrollEnabled:enabled];
            [[self designerScrollView] flashScrollIndicators];
            for (UICollectionView *collectionView in [[self designerContentView] subviews]) {
                if ([collectionView isKindOfClass: [UICollectionView class]]) {
                    [collectionView setScrollEnabled:enabled];
                    [collectionView flashScrollIndicators];
                }
            }
        }
    }
}

@end
