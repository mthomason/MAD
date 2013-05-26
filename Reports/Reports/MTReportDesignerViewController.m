//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerViewController.h"

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
};

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

@property (nonatomic, retain) NSMutableDictionary *sectionViews;
@property (nonatomic, retain) NSMutableDictionary *sectionControlViews;
@property (nonatomic, retain) NSMutableDictionary *sectionBackgroundViews;
@property (nonatomic, retain) NSMutableDictionary *sectionControlViewsHeighConstraint;

@property (nonatomic, retain) IBOutlet UIScrollView *designScrollView;

@property (nonatomic, retain) UIToolbar *toolboxToolbar;
@property (nonatomic, retain) UIView *toolboxBackgroundView; 
@property (nonatomic, retain) UIScrollView *toolboxScrollView;

@property (nonatomic, retain) NSArray *toolboxToolbarItemsPrimary;
@property (nonatomic, retain) NSArray *toolboxToolbarItemsFontChooser;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxHidden;
@property (nonatomic, retain) NSArray *toolbarTopItems;
@property (nonatomic, retain) NSArray *toolbarBottomItems;

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

@end

@implementation MTReportDesignerViewController

#pragma mark - NSObject

- (void)dealloc {
    [_sectionControlViewsHeighConstraint release];
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
    [_designScrollView release];
    [_informationButton release];
    [_barButtonItemInfo release];
    [_barButtonItemSettings release];
    [_barButtonItemObjects release];
    [_toolbarBottom release];
    [_toolbarTop release];
    [_toolboxView release];
    [_layoutConstraintsToRemove release];
    [super dealloc];
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];

    MTReportDesignerToolBoxViewController *viewControllerToolbox = [[storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"] retain];
    [viewControllerToolbox setDelegate:self];

    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [[storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier] retain];
    [viewControllerSectionLayoutSettings setDelegate:self];
    [self setViewControllerSectionLayoutSettings: viewControllerSectionLayoutSettings];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideToolbox:)];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self viewControllerSectionLayoutSettings]];
    [self setNavigationControllerSectionLayoutSettings:navigationController];
    [navigationController release];
    
    [[[self viewControllerSectionLayoutSettings] navigationItem] setRightBarButtonItem:doneButton animated:NO];
    [doneButton release];

    if ([UIDevice isPad]) {
        
        UIPopoverController *popoverControllerInformation = [[UIPopoverController alloc] initWithContentViewController:viewControllerToolbox];
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
    
    [viewControllerSectionLayoutSettings release];
    
    [self setViewControllerToolbox:viewControllerToolbox];
    [viewControllerToolbox release];

    NSMutableDictionary *holderForLastTouchesByCollectionView = [[NSMutableDictionary alloc] init];
    [self setHolderForLastTouchesByCollectionView:holderForLastTouchesByCollectionView];
    [holderForLastTouchesByCollectionView release];
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [self setSelectedObjectIds:set];
    [set release];
    
    [self setToolbarTopItems:[[self toolbarTop] items]];
    [self setToolbarBottomItems:[[self toolbarBottom] items]];
    
    NSString *collectionViewReuseId = [MTCollectionViewCellElement reuseIdentifier];
    NSMutableString *stringContstraintsVertical = [[NSMutableString alloc] initWithString:@"V:|"];
    NSMutableDictionary *dictionaryViewsVertical = [[NSMutableDictionary alloc] init];
    CGFloat paddingBorder = 3.0000f, paddingLabel = 2.0000f, heightLabel = 22.0000f, cornerRadius = 5.0000f;
    UICollectionView *lastCollectionView = nil;
    NSInteger sectionCounter = 0;
    
    NSManagedObjectContext *managedObjectContect = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:managedObjectContect];

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

    NSMutableDictionary *dictionarySectionControlViewsHeighConstraint = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setSectionControlViewsHeighConstraint:dictionarySectionControlViewsHeighConstraint];
    [dictionarySectionControlViewsHeighConstraint release];

    
    // MARK: Setup horizontal constraints.
    [[self view] removeConstraints:[self layoutConstraintsToRemove]];
    
    NSLayoutConstraint *layoutConstraintToolboxHeight = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.5000f constant: 0.0000f];
    NSLayoutConstraint *layoutConstraintToolbarTopHeight = [NSLayoutConstraint constraintWithItem: [self toolbarTop] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarTop] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
    NSLayoutConstraint *layoutConstraintToolbarBottomHeight = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];

    [self setLayoutConstraintsToolboxVisiable:@[layoutConstraintToolboxHeight, layoutConstraintToolbarTopHeight, layoutConstraintToolbarBottomHeight]];
    
    NSLayoutConstraint *layoutConstraintToolbarTopHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarTop] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarTop] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
    NSLayoutConstraint *layoutConstraintToolbarBottomHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
    NSLayoutConstraint *layoutConstraintToolboxHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
    [[self view] addConstraint:layoutConstraintToolboxHeightHidden];

    [self setLayoutConstraintsToolboxHidden:@[layoutConstraintToolboxHeightHidden, layoutConstraintToolbarTopHeightHidden, layoutConstraintToolbarBottomHeightHidden]];

     NSLayoutConstraint *layoutConstraintToolbarTopBottomToDesignViewTop = [NSLayoutConstraint constraintWithItem: [self toolbarTop] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeTop multiplier: 1.0000f constant: 0.0000f];
     [[self view] addConstraint:layoutConstraintToolbarTopBottomToDesignViewTop];
     
     NSLayoutConstraint *layoutConstraintToolbarBottomTopToDesignerBottom = [NSLayoutConstraint constraintWithItem: [self designScrollView] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeTop multiplier: 1.0000f constant: 0.0000f];
     [[self view] addConstraint:layoutConstraintToolbarBottomTopToDesignerBottom];
     
     NSLayoutConstraint *layoutConstraintToolboxTopToBottomToolbarBottom = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolboxView] attribute: NSLayoutAttributeTop multiplier: 1.0000f constant: 0.0000f];
     [[self view] addConstraint:layoutConstraintToolboxTopToBottomToolbarBottom];
    
     NSLayoutConstraint *layoutConstraintToolboxVisible = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeBottom multiplier: 1.0000f constant: 0.0000f];
    [[self view] addConstraint:layoutConstraintToolboxVisible];
    
    [self setToolboxIsVisible:NO];
    
    NSMutableDictionary *collectionViewReuseIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setCollectionViewReuseIdentifiers:collectionViewReuseIdentifiers];
    [collectionViewReuseIdentifiers release];
    
    MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
    CGColorRef shadowColor = [[UIColor darkGrayColor] CGColor];
    [[viewRuler layer] setCornerRadius: 6.0000f];
    [[viewRuler layer] setMasksToBounds: YES];
    [[viewRuler layer] setBorderColor: shadowColor];
    [[viewRuler layer] setBorderWidth: 3.0000f];

    NSLayoutConstraint *rulerConstraintHeight = [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:24.0000f];
    NSLayoutConstraint *rulerConstraintWidth = [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[self designScrollView] attribute:NSLayoutAttributeWidth multiplier:1.0000f constant: -(paddingBorder * 2.0000f)];
    NSLayoutConstraint *rulerConstraintLeading = [NSLayoutConstraint constraintWithItem:viewRuler attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[self designScrollView] attribute:NSLayoutAttributeLeading multiplier:1.0000f constant: paddingBorder];
    [[self designScrollView] addConstraint:rulerConstraintHeight];
    [[self designScrollView] addConstraint:rulerConstraintWidth];
    [[self designScrollView] addConstraint:rulerConstraintLeading];
    
    [viewRuler setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[self designScrollView] addSubview:viewRuler];
    [stringContstraintsVertical appendFormat:@"-(==%f@1000)-[%@]", 2.0, @"viewRuler"];
    [dictionaryViewsVertical setValue:viewRuler forKey:@"viewRuler"];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {

        CGFloat paddingTop = sectionCounter == 0 ? paddingBorder : (2 * paddingBorder);
        [lastCollectionView  release];  //Should be nil on first pass.

        
        // MARK: Create collection view for report document section.
        
        MTReportDesignerSectionViewLayoutLiquid *flowLayoutDesignerSection = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];
        [flowLayoutDesignerSection setDelegate:self];

        MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
        [backgroundView setNumberOfRowsInBackground:[[reportSection numberOfRows] integerValue]];
//        [backgroundView setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];
        [backgroundView setBackgroundColor:[UIColor edaGreenLight]];

        NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];

        MTDocumentSectionView *collectionView = [[MTDocumentSectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
        
        [collectionView setObjectIdTag:[reportSection objectID]];
        NSString *reuse = [collectionViewReuseId stringByAppendingFormat:@"%d", [[reportSection identifier] integerValue]];
        NSMutableDictionary *lastTouches = [[NSMutableDictionary alloc] init];
        [[self holderForLastTouchesByCollectionView] setObject:lastTouches forKey:@(collectionView.tag)];
        [lastTouches release];
        [[self collectionViewReuseIdentifiers] setObject:reuse forKey:[reportSection identifier]];
        [collectionView registerClass: [MTCollectionViewCellElement class] forCellWithReuseIdentifier: reuse];

        [collectionView registerClass:[MTCollectionReuseableViewDefault class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:supplmentaryViewReuseIdHeader];
        
        [collectionView registerClass:[MTCollectionReuseableViewDefault class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                  withReuseIdentifier:supplmentaryViewReuseIdHeader];

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
        [[collectionView layer] setCornerRadius:cornerRadius];
        
        [[self designScrollView] addSubview:collectionView];

        // MARK: Create label to identify document section.
        UIView *sectionControlView = [[UIView alloc] init];
        [sectionControlView setBackgroundColor:[UIColor edaYellow]];
        [sectionControlView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[sectionControlView layer] setCornerRadius:cornerRadius];
        [sectionControlView setClipsToBounds:YES];
        [sectionControlView setTag:sectionCounter];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSectionControlPanel:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [tapGestureRecognizer setNumberOfTouchesRequired:1];
        [tapGestureRecognizer setDelegate: self];
        [sectionControlView addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];
        
        UILabel *labelSectionIdentifer = [[UILabel alloc] init];
        [labelSectionIdentifer setBackgroundColor:[UIColor clearColor]];
        [labelSectionIdentifer setTextAlignment:NSTextAlignmentCenter];
        [labelSectionIdentifer setFont:[UIFont systemFontOfSize:8.0000f]];
        [labelSectionIdentifer setText:[reportSection localizedDisplayName]];
        [labelSectionIdentifer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:YES];

        [sectionControlView addSubview:labelSectionIdentifer];
        
        [[self designScrollView] addSubview:sectionControlView];
        
        // MARK: Setup vert auto layout
        NSString *collectionViewKey = [reportSection sectionKey];
        NSString *labelKey = [NSString stringWithFormat:@"label%@", collectionViewKey];

        [[sectionControlView layer] setBorderColor: [[UIColor blackColor] CGColor]];
        [[sectionControlView layer] setBorderWidth: 1.0000f];

        [[collectionView layer] setBorderColor: shadowColor];
        [[collectionView layer] setBorderWidth: 3.0000f];

        [[self sectionViews] setValue:collectionView forKey:collectionViewKey];
        [[self sectionControlViews] setValue:sectionControlView forKey:collectionViewKey];
        [[self sectionBackgroundViews] setValue:backgroundView forKey:collectionViewKey];
        
        [dictionaryViewsVertical setValue:sectionControlView forKey:labelKey];
        [dictionaryViewsVertical setValue:collectionView forKey: collectionViewKey];
        
        [stringContstraintsVertical appendFormat:@"-(==%f@1000)-[%@(>=%f)]-(==%f@1000)-[%@(==%f)]", paddingTop, collectionViewKey, [[reportSection height] floatValue], - paddingLabel - heightLabel, labelKey, heightLabel];

        NSLayoutConstraint *layoutConstraintLeft = [NSLayoutConstraint constraintWithItem: collectionView
                                                                                attribute: NSLayoutAttributeLeft
                                                                                relatedBy: NSLayoutRelationEqual
                                                                                   toItem: [self designScrollView]
                                                                                attribute: NSLayoutAttributeLeft
                                                                               multiplier: 1.0000f
                                                                                 constant: paddingBorder];
        [[self designScrollView] addConstraint:layoutConstraintLeft];

        NSLayoutConstraint *layoutConstraintWidth = [NSLayoutConstraint constraintWithItem: collectionView
                                                                                 attribute: NSLayoutAttributeWidth
                                                                                 relatedBy: NSLayoutRelationEqual
                                                                                    toItem: [self designScrollView]
                                                                                 attribute: NSLayoutAttributeWidth
                                                                                multiplier: 1.0000f
                                                                                  constant: -(paddingBorder * 2.0000f)];
        [[self designScrollView] addConstraint:layoutConstraintWidth];

        NSLayoutConstraint *layoutConstraintLabelWidth = [NSLayoutConstraint constraintWithItem: sectionControlView
                                                                                      attribute: NSLayoutAttributeWidth
                                                                                      relatedBy: NSLayoutRelationEqual
                                                                                         toItem: [self designScrollView]
                                                                                      attribute: NSLayoutAttributeWidth
                                                                                     multiplier: 0.20000f
                                                                                       constant: 0.0000f];
        [[self designScrollView] addConstraint:layoutConstraintLabelWidth];
        
        NSLayoutConstraint *layoutConstraintLabelRight = [NSLayoutConstraint constraintWithItem: sectionControlView
                                                                                      attribute: NSLayoutAttributeTrailing
                                                                                      relatedBy: NSLayoutRelationEqual
                                                                                         toItem: collectionView
                                                                                      attribute: NSLayoutAttributeTrailing
                                                                                     multiplier: 1.0000f
                                                                                       constant: -paddingLabel];
        [[self designScrollView] addConstraint:layoutConstraintLabelRight];

        [labelSectionIdentifer release];
        [sectionControlView release];
        lastCollectionView = [collectionView retain];
        [collectionView release];
        [backgroundView release];
        [flowLayoutDesignerSection release];

        sectionCounter++;
    }
    
    [stringContstraintsVertical appendFormat:@"-(==%f@1000)-|", paddingBorder * 2];
    
    [lastCollectionView release];
    NSArray *labelconstraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat: stringContstraintsVertical
                                                                                options: 0
                                                                                metrics: nil
                                                                                  views: dictionaryViewsVertical];
    for (NSLayoutConstraint *layoutConstraint in labelconstraintsVertical) {
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
    
    [[self designScrollView] addConstraints:labelconstraintsVertical];
    [[self designScrollView] setScrollEnabled:YES];
    //[[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
    [[self designScrollView] setBackgroundColor: [UIColor whiteColor]];
    [[self designScrollView] setUserInteractionEnabled:YES];
    [[self designScrollView] flashScrollIndicators];

    [stringContstraintsVertical release];
    [dictionaryViewsVertical release];
    [sectionEnumerator release];
    [viewRuler release];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}
- (void)updateViewConstraints {
    [super updateViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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

    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navController = [[segue destinationViewController] retain];
        if (navController) {
            if ([[navController viewControllers] count] > 0) {
                MTSettingsViewController *tvcSettings = [[[navController viewControllers] objectAtIndex: 0] retain];
                [tvcSettings setDelegate:self];
                [tvcSettings release];
            }
        }
        [navController release];
    } else if ([[segue identifier] isEqualToString:@"showObjects"]) {
        //NSLog(@"Sender :%@", sender);
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            UIPopoverController *popoverController = [[popoverSegue popoverController] retain];
            [self setPopoverControllerObjectSelector:popoverController];
            [popoverController release];
        }
        MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = [segue destinationViewController];
        [viewControllerObjectSelector setObjectSelectorDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {

        MTReportViewerViewController *viewControllerReportViewer = [segue destinationViewController];
        [viewControllerReportViewer setDelegate:self];
        [viewControllerReportViewer setDocumentReport:[[MTActiveDocument sharedDocument] activeDocument]];
        
    }
}


#pragma mark - Layout Settings Delegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MTReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:[reportDocument managedObjectContext]];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                forQuery: query];

    [RptqDocumentSection setHeight:height forSectionAtRow:[self lastSelectedSectionControlPanel] inManagedObjectContext: [reportDocument managedObjectContext]];
    [[reportDocument managedObjectContext] save:nil];
    [reportDocument save:nil];
    
    MTReportDesignerSectionBackgroundView *backgroundView = [[[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]] retain];
    [backgroundView setNeedsDisplay];
    [backgroundView release];
    
    UICollectionView *documentSectionView = [[self getSectionViewForDocumentSection: documentSection] retain];
    [[documentSectionView collectionViewLayout] invalidateLayout];
    [documentSectionView release];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    MTReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    [RptqDocumentSection setVisibility: isVisible
                       forSectionAtRow: [self lastSelectedSectionControlPanel]
                inManagedObjectContext: managedObjectContext];
    [managedObjectContext save:nil];
    [reportDocument save:nil];
    
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MTReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    
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
    
    NSLog(@"error %@", error);
    
    [reportDocument save:^(BOOL success) {
        
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

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[documentSectionView objectIdTag] fromObjectContext:managedObjectContext];
    [documentSection setHeight:@([documentSectionView bounds].size.height)];
    

    [self relayoutSectionView:documentSectionView];
    
    [managedObjectContext save:nil];
}

- (void)relayoutSectionView:(MTDocumentSectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [[objectId URIRepresentation] retain];

    NSManagedObjectContext *managedObjectContect = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:objectId fromObjectContext:managedObjectContect];

    NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:[objectIdUrl absoluteString]];
    [layoutConstraint setConstant:documentSection.height.floatValue];
    [objectIdUrl release];
    

    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - Toolbox Delegate

- (void)heightChanged:(CGFloat)newHeight {
    //NSLog(@"Height changed to %f", newHeight);
    CGSize newSize = CGSizeMake(320.0000f, newHeight);
    [[self popoverControllerInformation] setPopoverContentSize:newSize animated:YES];
    [[[self popoverControllerInformation] contentViewController] setContentSizeForViewInPopover: newSize];

}

#pragma mark - Core Data Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    BOOL contextSaved = NO;

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
                    //RptqDocumentSection *documentSection = [[documentObject inSectionRow] inSection];
                    //[self checkAndUpdateHeightForSection:documentSection forHeight:[documentObject viewSize].height];
                }
                
            }

            //NSError *error = nil;
            //[[documentObject managedObjectContext] save:&error];
            //if (error != nil) {
            //    [error presentErrorToUser];
            //}

        } else if ([updatedObject isKindOfClass:[RptqDocumentSection class]]) {
            RptqDocumentSection *documentSection = updatedObject;
            NSDictionary *changes = [documentSection changedValues];
            for (id change in changes) {
                if ([change isEqualToString:NSStringFromSelector(@selector(height))]) {
                    MTDocumentSectionView *section = (MTDocumentSectionView *)[self getSectionViewForDocumentSection: documentSection];
                    [self relayoutSectionView:section];
                    [section invalidateIntrinsicContentSize];
                    [[section collectionViewLayout] invalidateLayout];
//                    CGRect newFrame = ;
//                    section setBounds:
                } else if ([change isEqualToString:NSStringFromSelector(@selector(numberOfRows))]) {
                    
                }
            }

        }
    }
}

- (void)managedObjectContextDidSave:(NSNotification *)notification { }

#pragma mark - Menu Notifications

- (void)didHideMenuNotification:(NSNotification *)notification {
    //[self removeBorderFromView:[self lastElementViewToShowMenu]];
}

- (void)didShowMenuNotification:(NSNotification *)notification { }

#pragma mark - Methods

- (CGRect)rectForSelectedElements {
    CGRect popoverRect = CGRectZero;
    if ([[self selectedObjectIds] count] == 1) {
        MTElementView *elementView = [[self selectedElementViews] anyObject];
        popoverRect = [elementView convertRect:[elementView frame] toView:[self designScrollView]];
    } else if ([[self selectedObjectIds] count] > 1) {
        CGFloat minx = 0.0000f, miny = 0.0000f, maxx = 0.0000f, maxy = 0.0000f;
        NSUInteger counter = 0;
        for (MTElementView *elementView in [self selectedElementViews]) {
            CGRect frame = [elementView convertRect:[elementView frame] toView:[self designScrollView]];
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

#pragma mark - Element View Delegate

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
            
            if ([[elementView objectIdTag] isTemporaryID]) {
                NSLog(@"Fix HERE");
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
                    popoverRect = [elementView convertRect:[elementView frame] toView:[self designScrollView]];
                } else if ([[self selectedObjectIds] count] > 1) {
                    CGFloat minx = 0.0000f, miny = 0.0000f, maxx = 0.0000f, maxy = 0.0000f;
                    NSUInteger counter = 0;
                    for (MTElementView *elementView in [self selectedElementViews]) {
                        CGRect frame = [elementView convertRect:[elementView frame] toView:[self designScrollView]];
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
                                                                     inView: [self designScrollView]
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
                    [[self popoverControllerInformation] presentPopoverFromRect:popoverRect inView:[self designScrollView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
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
                
                NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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
    [[view layer] setBorderWidth:3.0000f];
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
        
        for (UIPopoverController *popoverController in allpopovers) {
            if ([popoverController isPopoverVisible]) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }
        [allpopovers release];
    }
    return result;
}

- (NSSet *)elementViews {
    
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:
                                     [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
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
    for (id subview in [[self designScrollView] subviews]) {
        if ([subview tag] == identifer && [subview isKindOfClass:[MTDocumentSectionView class]]) {
            documentSectionView = [subview retain];
            break;
        }
    }
    return [documentSectionView autorelease];
}

- (NSSet *)selectedElementViews {

    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
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

- (void)cut:(id)sender {
    //NSLog(@"Fake a cut.");
}

- (void)copy:(id)sender {
    //NSLog(@"Fake a copy.");
}

- (void)select:(id)sender {
    //NSLog(@"Fake a select.");
}

- (void)selectAll:(id)sender {
    //NSLog(@"Fake a select all.");
}

- (void)paste:(id)sender {
    //NSLog(@"Fake a paste.");
}

- (void)delete:(id)sender {
    //NSLog(@"Fake a delete.");
}

- (void)toggleUnderline:(id)sender {
    //NSLog(@"Fake a delete.");
    
}

- (void)toggleItalics:(id)sender {
    //NSLog(@"Fake a delete.");
    
}

- (void)toggleBoldface:(id)sender {
    //NSLog(@"Fake a delete.");
    
}

- (void)showFontChooser:(id)sender {
    
}

- (void)hideFontChooser:(id)sender {
    
}

- (void)customAction:(id)sender {
    //NSLog(@"custom action! %@", sender);
}

- (void)openReport:(NSURL *)url {
    MTManagedDocumentPreferencesUser *trvFile = [[MTManagedDocumentPreferencesUser alloc] initWithFileURL:url];
    
    [trvFile release];
}

- (void)openTemplate:(NSURL *)url {
    
    NSString *origionalFileName = [[url lastPathComponent] retain];
    
    NSURL *urlLibraryTemplate = [[NSFileManager applicationLibraryTemplatesDirectoryUrl] retain];
    NSURL *urlFilenameWithoutExtention = [[[urlLibraryTemplate URLByAppendingPathComponent:origionalFileName] URLByDeletingPathExtension] retain];
    
    NSURL *templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
    NSString *templateDestinationName = [[templateDestination lastPathComponent] retain];
    
    BOOL fileWritten = NO;
    
    NSInteger ctr = 0;
    while (!fileWritten) {
        NSError *error;
        fileWritten = [[NSFileManager defaultManager] copyItemAtURL:url toURL:templateDestination error:&error];
        if (!fileWritten) {
            [templateDestination release];
            NSString *p = [[[urlFilenameWithoutExtention path] stringByAppendingFormat:@" %d", (ctr + 1)] retain];
            templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
            [p release];
        }
    }
    [urlFilenameWithoutExtention release];
    [urlLibraryTemplate release];
    [templateDestinationName release];
    [origionalFileName release];
    
    
    //Now that we copied the file, we open it.  Yay!
    [self openReport:templateDestination];
    
    [templateDestination release];
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

- (IBAction)showSettings:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showSettings" sender:sender];
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
    
    UIPopoverController *popoverController;
    UIViewController *viewController;

    switch (tooboxType) {

        case MTToolboxTypeElement:
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            popoverController = [self popoverControllerInformation];
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
            viewController = [[self viewControllerToolbox] retain];
            break;
            
        case MTToolboxTypeSection: {
            popoverController = [self popoverControllerSectionSettings];
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
                        
                        MTReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
                        
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

                    if (CGRectIntersectsRect(rectToShow, self.designScrollView.frame) == NO) {
                        
                        CGFloat offsetPointY = rectToShow.origin.y + rectToShow.size.height + 5.0000f - [[self designScrollView] frame].size.height;
                        CGPoint offsetPoint = CGPointMake(CGPointZero.x, offsetPointY);
                        [[self designScrollView] setContentOffset:offsetPoint animated:YES];
                        
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

- (void)dismissObjectSelectorViewController {
    if ([UIDevice isPad]) {
        if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
            [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)resizeCollectionView:(UICollectionView *)collectionView forSectionWithId:(NSManagedObjectID *)sectionObjectId {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForObjectID:sectionObjectId fromObjectContext:managedObjectContext];
    CGSize contentSize = [(MTReportDesignerSectionViewLayoutLiquid *)[collectionView collectionViewLayout] collectionViewContentSize];
    [section setHeight:@(contentSize.height + 44.0000f)];
    NSError *error = nil;
    [managedObjectContext save:&error];
    if (error != nil) {
        [error presentErrorToUser];
    }
    
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
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(cut:) ||
            action == @selector(copy:) ||
            action == @selector(paste:) ||
            action == @selector(delete:) ||
            action == @selector(select:) ||
            action == @selector(selectAll:) ||
            action == @selector(toggleBoldface:) ||
            action == @selector(toggleItalics:) ||
            action == @selector(toggleUnderline:) ||
            action == @selector(customAction:) ||
            [super canPerformAction:action withSender:sender];
}

#pragma mark -
#pragma mark Collection View Line Layout Delegate
/*
- (NSUInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    return [[documentSection hasRows] count];
}
*/


- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView {
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    return [[documentSection height] floatValue];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
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

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
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
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    
    CGPoint result;
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [documentObject setDropPointX:@(dropPoint.x)];
        [documentObject setDropPointY:@(dropPoint.y)];
        NSError *error = nil;
        [managedObjectContext save:&error];
    } else {
        result = CGPointZero;
    }
}


#pragma mark Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"Display number cell at index path %@", indexPath);
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    NSString *resuseId = [[self collectionViewReuseIdentifiers] objectForKey:[documentSection identifier]];
    MTCollectionViewCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath];
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
                    NSLog(@"Fix HERE");
                }
                
                
                MTElementView *elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID]
                                                                     inObjectContext:managedObjectContext];
                [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
                [[elementView layer] setBorderWidth:1.0000f];
                
                [elementView setDelegate:self];
                [cell setBackgroundColor:[UIColor clearColor]];
                [elementView setFrame:cellFrame];
                [[elementView layer] setCornerRadius: 5.0000f];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                [elementView addGestureRecognizer:panGesture];
                [panGesture release];
                
                [cell setTag:[[documentObject identifier] integerValue] + 3838];
                [cell setObjectIdTag:[documentObject objectID]];
                //[cell setFrame: cellFrame];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];
                
                [elementView release];

                break;
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    //NSLog(@"Number of items: %d in section: %d", [objects count], section);
    return [objects count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"viewForSupplementaryElementOfKind: %@ atIndexPath %@", kind, indexPath);

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
                                                                            fromObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    //NSLog(@"numberOfSectionsInCollectionView: %d", [[documentSection hasRows] count]);
    return [[documentSection hasRows] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView {
    //NSLog(@"numberOfItemsInSection");
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
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
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
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
    return result || [self respondsToSelector:action];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"Perform action yo!!! %@", NSStringFromSelector(action));
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    } else {
        if ([UIDevice isPad]) {
            if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
                [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                
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

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDocumentSection *section = [document hasDetailSection];
    NSManagedObjectID *sectionID = [section objectID];
    
    __block UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];
    
    [detailSection performBatchUpdates:^{
        
        MTReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
        NSManagedObjectContext *managedObjectContextBlock = [reportDocument managedObjectContext];
        
        
        RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination
                                                                        toDocument:document];
        [documentObject obtainPermanentID];
        
        NSError *error = nil;
        [managedObjectContextBlock save:&error];
        [detailSection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            [self resizeCollectionView:detailSection forSectionWithId:sectionID];
        }
        
    }];
    
}

- (void)insertDocumentObjectNewFormula {
    [self dismissObjectSelectorViewController];
}

- (void)insertDocumentObjectNewChart {
    [self dismissObjectSelectorViewController];
}
- (void)insertDocumentObjectNewHyperlink {
    [self dismissObjectSelectorViewController];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)pinchView:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStatePossible: {    // MARK: UIPinchGestureRecognizer UIGestureRecognizerStatePossible
            break;
        }
        case UIGestureRecognizerStateBegan: {       // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateBegan
            if ([gestureRecognizer numberOfTouches] >= 2) {
                CGPoint locationStart0 = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint locationStart1 = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                CGFloat differenceY = locationStart0.y - locationStart1.y;
                //NSLog(@"Start difference y = %f", differenceY);
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateChanged
            if ([gestureRecognizer numberOfTouches] >= 2) {
                CGPoint locationStart0 = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint locationStart1 = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                CGFloat differenceY = locationStart0.y - locationStart1.y;
                //NSLog(@"Change difference y = %f", differenceY);
            }
            break;
        }
        case UIGestureRecognizerStateCancelled: {   // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateCancelled
            break;
        }
        case UIGestureRecognizerStateFailed: {      // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateFailed
            break;
        }
        case UIGestureRecognizerStateEnded: {       // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateEnded
            break;
        }
    }
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    //CGPoint adjustedCenter = [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            [[gestureRecognizer view] setAlpha:0.6000f];
            
            [[self designScrollView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [self setScrollersEnabled: NO];

            [[gestureRecognizer view] setCenter: newCenter];

            {
                NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
                
                RptqDocumentSection *section = [[documentObject inSectionRow] inSection];
                UICollectionView *svSection = [self getSectionViewForDocumentSection:section];
                
                RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];

                
                NSUInteger deleteSection = 0;

                for (RptqDocumentSectionRows *row in [documentSection hasRows]) {

                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [row hasObjects]];
                    NSUInteger deleteIndex = 0;
                    
                    BOOL found = NO;

                    for (RptqDocumentObject *object in hasObjects) {
                        
                        if ([[object objectID] isEqual: [[gestureRecognizer view] objectIdTag]]) {
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
                            [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
                            NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: deleteSection];

                            [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];

                        } completion:^(BOOL finished) {
                            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
                            [[gestureRecognizer view] setCenter: newCenter];
                            [[self designScrollView] addSubview: [gestureRecognizer view]];
                            
                            [svSection setDelegate:self];
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
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
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
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            UICollectionView *reportSectionCollectionView = nil;
            
            // Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designScrollView] subviews]) {
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
                for (UICollectionView *view in [[self designScrollView] subviews]) {
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

                    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                    
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
                        [self resizeCollectionView:reportSectionCollectionView forSectionWithId:[reportSectionCollectionView objectIdTag]];
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
    @synchronized([self designScrollView]) {
        if ([[self designScrollView] respondsToSelector:@selector(setScrollEnabled:)]) {
            [[self designScrollView] setScrollEnabled:enabled];
            [[self designScrollView] flashScrollIndicators];
            for (UICollectionView *collectionView in [[self designScrollView] subviews]) {
                if ([collectionView isKindOfClass: [UICollectionView class]]) {
                    [collectionView setScrollEnabled:enabled];
                    [collectionView flashScrollIndicators];
                }
            }
        }
    }
}

@end
