//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerViewController.h"

@interface MTReportDesignerViewController()

@property (nonatomic, retain) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, retain) UIPopoverController *popoverControllerInformation;
@property (nonatomic, retain) UIPopoverController *popoverControllerObjectSelector;

@property (nonatomic, assign) BOOL toolboxIsVisible;
@property (nonatomic, retain) MTElementView *lastElementViewToShowMenu;
@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *layoutConstraintsToRemove;

@property (nonatomic, retain) NSMutableDictionary *sectionViews;
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
    [_layoutConstraintsReportSectionHeight release];
    [_lastElementViewToShowMenu release];
    [_popoverControllerObjectSelector release];
    [_popoverControllerInformation release];
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

    if ([UIDevice isPad]) {
        
        UIPopoverController *popoverControllerInformation = [[UIPopoverController alloc] initWithContentViewController:viewControllerToolbox];
        [popoverControllerInformation setDelegate:self];
        [popoverControllerInformation setPopoverContentSize:CGSizeMake(320.0000f, 320.0000f) animated:NO];
        [self setPopoverControllerInformation:popoverControllerInformation];
        [popoverControllerInformation release];

    } else {

        [[viewControllerToolbox view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.toolboxView.frame.size.width, self.toolboxView.frame.size.height)];
        [[viewControllerToolbox view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[self toolboxView] addSubview:[viewControllerToolbox view]];
    }
    
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
    CGFloat paddingBorder = 3.0000f, paddingLabel = 2.0000f, heightLabel = 12.0000f,cornerRadius = 5.0000f;
    UICollectionView *lastCollectionView = nil;
    NSInteger sectionCounter = 0;
    
    NSManagedObjectContext *managedObjectContect = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:managedObjectContect];

    NSMutableDictionary *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setLayoutConstraintsReportSectionHeight:layoutConstraintsReportSectionHeight];
    [layoutConstraintsReportSectionHeight release];
    
    NSMutableDictionary *dictionarySections = [[NSMutableDictionary alloc] initWithCapacity:[sectionEnumerator count]];
    [self setSectionViews: dictionarySections];
    [dictionarySections release];

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
    [[viewRuler layer] setCornerRadius: 6.0f];
    [[viewRuler layer] setMasksToBounds: YES];
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
        
        MTReportDesignerSectionViewLayout *flowLayoutDesignerSection = [[MTReportDesignerSectionViewLayout alloc] init];
        [flowLayoutDesignerSection setDelegate:self];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        [backgroundView setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];

        MTDocumentSectionView *collectionView = [[MTDocumentSectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
        [collectionView setObjectIdTag:[reportSection objectID]];
        NSString *reuse = [collectionViewReuseId stringByAppendingFormat:@"%d", [[reportSection identifier] integerValue]];
        NSMutableDictionary *lastTouches = [[NSMutableDictionary alloc] init];
        [[self holderForLastTouchesByCollectionView] setObject:lastTouches forKey:@(collectionView.tag)];
        [lastTouches release];
        [[self collectionViewReuseIdentifiers] setObject:reuse forKey:[reportSection identifier]];
        [collectionView registerClass: [MTCollectionViewCellElement class] forCellWithReuseIdentifier: reuse];
        [collectionView setTag:[[reportSection identifier] integerValue]];
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
        UILabel *labelSectionIdentifer = [[UILabel alloc] init];
        [labelSectionIdentifer setTextAlignment:NSTextAlignmentCenter];
        [[labelSectionIdentifer layer] setCornerRadius:cornerRadius];
        [labelSectionIdentifer setFont:[UIFont systemFontOfSize:8.0000f]];
        [labelSectionIdentifer setText:[reportSection localizedDisplayName]];
        [labelSectionIdentifer setBackgroundColor:[UIColor edaYellow]];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:NO];

        [[self designScrollView] addSubview:labelSectionIdentifer];
        
        
        // MARK: Setup vert auto layout
        NSString *collectionViewKey = [reportSection sectionKey];
        NSString *labelKey = [NSString stringWithFormat:@"label%@", collectionViewKey];
        [self setCollectionView:collectionView forSection:reportSection];
        [[self sectionViews] setValue:collectionView forKey:collectionViewKey];
        [dictionaryViewsVertical setValue:labelSectionIdentifer forKey:labelKey];
        [dictionaryViewsVertical setValue:collectionView forKey: collectionViewKey];
        
        [stringContstraintsVertical appendFormat:@"-(==%f@1000)-[%@(>=%f)]-(==%f@1000)-[%@(==%f)]", paddingTop, collectionViewKey, [[reportSection height] floatValue], - paddingLabel - heightLabel, labelKey, heightLabel];

        NSLayoutConstraint *layoutConstraintLeft = [NSLayoutConstraint constraintWithItem: collectionView attribute: NSLayoutAttributeLeft relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeLeft multiplier: 1.0000f constant: paddingBorder];
        [[self designScrollView] addConstraint:layoutConstraintLeft];

        NSLayoutConstraint *layoutConstraintWidth = [NSLayoutConstraint constraintWithItem: collectionView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeWidth multiplier: 1.0000f constant: -(paddingBorder * 2.0000f)];
        [[self designScrollView] addConstraint:layoutConstraintWidth];

        NSLayoutConstraint *layoutConstraintLabelWidth = [NSLayoutConstraint constraintWithItem: labelSectionIdentifer attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeWidth multiplier: 0.20000f constant: 0.0000f];
        [[self designScrollView] addConstraint:layoutConstraintLabelWidth];
        
        NSLayoutConstraint *layoutConstraintLabelRight = [NSLayoutConstraint constraintWithItem: labelSectionIdentifer attribute: NSLayoutAttributeTrailing relatedBy: NSLayoutRelationEqual toItem: collectionView attribute: NSLayoutAttributeTrailing multiplier: 1.0000f constant: -paddingLabel];
        [[self designScrollView] addConstraint:layoutConstraintLabelRight];

        [labelSectionIdentifer release];
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
    [[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
    [[self designScrollView] setUserInteractionEnabled:YES];
    [[self designScrollView] flashScrollIndicators];

    [stringContstraintsVertical release];
    [dictionaryViewsVertical release];
    [sectionEnumerator release];
    [viewRuler release];

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

    [defaultCenter removeObserver:self
                             name:NSManagedObjectContextObjectsDidChangeNotification
                           object:managedObjectContext];

    [defaultCenter removeObserver:self
                             name:NSManagedObjectContextDidSaveNotification
                           object:managedObjectContext];
    [defaultCenter removeObserver:self
                             name:UIMenuControllerDidHideMenuNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:UIMenuControllerDidShowMenuNotification
                           object:nil];

    
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

#pragma mark - MTSectionViewDelegate

- (void)didUpdateLayout:(id)sender {
    MTDocumentSectionView *documentSectionView = (MTDocumentSectionView *)sender;
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [[objectId URIRepresentation] retain];
    NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:[objectIdUrl absoluteString]];
    [layoutConstraint setConstant:[documentSectionView bounds].size.height];
    [objectIdUrl release];
    
    NSManagedObjectContext *managedObjectContect = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[sender objectIdTag] fromObjectContext:managedObjectContect];
    [documentSection setHeight:@([sender bounds].size.height)];
    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - UIViewControllerToolboxDelegate

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
                    [change isEqualToString:NSStringFromSelector(@selector(sizeheight))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginRight))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginTop))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(marginBottom))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingLeft))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingRight))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingTop))] ||
                    [change isEqualToString:NSStringFromSelector(@selector(paddingBottom))]) {
                    
                    if (contextSaved == NO) [[documentObject managedObjectContext] save:nil];
                    UICollectionView *section = [self getCollectionViewForRptqSection: [documentObject inSection]];
                    [[section collectionViewLayout] invalidateLayout];
                    MTLog(@"Change that size.");
                }
            }
        }
    }    
}

- (void)managedObjectContextDidSave:(NSNotification *)notification { }

#pragma mark - UIMenu Notifications

- (void)didHideMenuNotification:(NSNotification *)notification {
    [self removeBorderToElementView:[self lastElementViewToShowMenu]];
}

- (void)didShowMenuNotification:(NSNotification *)notification { }

#pragma mark - Methods

- (void)applyBorderToElementView:(MTElementView *)elementView {
    [[elementView layer] setBorderColor:[[UIColor redColor] CGColor]];
    [[elementView layer] setBorderWidth:3.0000f];
}

- (void)removeBorderToElementView:(MTElementView *)elementView {
    [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[elementView layer] setBorderWidth:0.0000f];
}

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

#pragma mark - Actions

- (void)deselectAllElements {
    for (MTElementView *elementView in [self selectedElementViews]) {
        [self didDeselectElementView:elementView animated:YES];
    }
}

- (void)deselectAllElementsAnimated:(BOOL)animated {
    for (MTElementView *elementView in [self selectedElementViews]) {
        [self didDeselectElementView:elementView animated:animated];
    }
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
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        UIView *subview = [[self designScrollView] viewWithTag:[[documentSection identifier] integerValue]];
        if ([subview isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)subview;
            for (NSUInteger section = 0; section < [collectionView numberOfSections]; section++) {
                for (NSUInteger item = 0; item < [collectionView numberOfItemsInSection:section]; item++) {
                    MTElementView *elementView = [[self elementViewAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] inCollectionView:collectionView] retain];
                    if (elementView != nil) {
                        [results addObject:elementView];
                    } else {
                        //NSLog(@"Nil element view!  WTF");
                    }
                    [elementView release];
                }
            }
        }
    }
    [enumerator release];
    return [results autorelease];
}

- (NSSet *)selectedElementViews {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        UIView *subview = [[self designScrollView] viewWithTag:[[documentSection identifier] integerValue]];
        if ([subview isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)subview;
            for (NSUInteger section = 0; section < [collectionView numberOfSections]; section++) {
                for (NSUInteger item = 0; item < [collectionView numberOfItemsInSection:section]; item++) {
                    MTElementView *elementView = [self elementViewAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] inCollectionView:collectionView];
                    if ([[self selectedObjectIds] containsObject: [elementView objectIdTag]]) {
                        [results addObject:elementView];
                    }
                }
            }
        }
    }
    [enumerator release];
    return [results autorelease];
}

- (UICollectionView *)getCollectionViewForRptqSection:(RptqDocumentSection *)documentSection {
    return [[self sectionViews] objectForKey:[documentSection sectionKey]];
}

- (void)setCollectionView:(UICollectionView *)collectionView forSection:(RptqDocumentSection *)documentSection {
    [[self sectionViews] setValue:collectionView forKey:[documentSection sectionKey]];
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
        [self deselectAllElements];
    }
}

- (IBAction)doneReports:(id)sender {
    if (![self dismissAllPopovers]) {
        [[self delegate] viewControllerDidFinish:@(YES) animated:NO];
    } else {
        [self deselectAllElements];
    }
}

- (IBAction)showObjects:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showObjects" sender:sender];
    } else {
        [self deselectAllElements];
    }
}

- (IBAction)showSettings:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showSettings" sender:sender];
    } else {
        [self deselectAllElements];
    }
}

- (IBAction)info:(id)sender {
    if (![self dismissAllPopovers]) {
        [self showToolbox:sender];
    }
}

- (IBAction)showToolbox:(id)sender {
    
    if ([UIDevice isPad]) {
        
        [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
        [[self popoverControllerInformation] presentPopoverFromBarButtonItem:[self barButtonItemInfo]
                                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                    animated:YES];
        
        [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];

    } else {

        if ([self toolboxIsVisible] == NO) {
            [self setToolboxIsVisible:YES];
            [[self informationButton] setEnabled: NO];
            
            [[self toolbarBottom] setItems:nil animated:YES];
            [[self toolbarTop] setItems:nil animated:YES];
            
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];

            [[self view] layoutIfNeeded];
            [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
                [self setWantsFullScreenLayout:YES];
                [[self view] removeConstraints:[self layoutConstraintsToolboxHidden]];
                [[self view] addConstraints:[self layoutConstraintsToolboxVisiable]];
                [[self view] layoutIfNeeded];
            } completion:nil];
        }
    }
}

- (void)hideToolbox {
    if ([UIDevice isPad]) {
        if ([[self popoverControllerInformation] isPopoverVisible]) {
            [[self popoverControllerInformation] dismissPopoverAnimated:YES];
            [self deselectAllElementsAnimated:YES];
        }
    } else {
        [self hideToolbox:self];
    }
}

- (IBAction)hideToolbox:(id)sender {

    if ([self toolboxIsVisible]) {
        [self setToolboxIsVisible:NO];

        [[self view] layoutIfNeeded];
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
            [[self view] removeConstraints:[self layoutConstraintsToolboxVisiable]];
            [[self view] addConstraints:[self layoutConstraintsToolboxHidden]];
            [[self view] layoutIfNeeded];
        } completion:^(BOOL finished) {
            [[self toolbarBottom] setItems:[self toolbarBottomItems] animated:YES];
            [[self toolbarTop] setItems:[self toolbarTopItems] animated:YES];
            [[self informationButton] setEnabled: YES];
        }];
    }
}

- (void)dismissObjectSelectorViewController {
    if ([UIDevice isPad]) {
        if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
            [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
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
    //NSLog(@"Action %@ with %@", NSStringFromSelector(action), sender);
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

#pragma mark - MTCollectionViewLineLayoutDelegate

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout initialLayoutCenterPointForIndexPath:(NSIndexPath *)indexPath {
    NSValue *result = [[[self holderForLastTouchesByCollectionView] objectForKey:@([collectionView tag])] objectForKey:indexPath];
    return [result CGPointValue];
}

#pragma mark - Collection View Flow Layout Delegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = [documentObject viewSize];
    } else {
        result = CGSizeZero;
    }
    //NSLog(@"Size for item at %@: %@", indexPath, NSStringFromCGSize(result));
    return result;
}

#pragma mark - Collection View Data Source

// MARK: Load the elements into the sections.

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [documentSection hasObjects];
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
                
                MTElementView *elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID]
                                                                     inObjectContext:managedObjectContext];
                
                [elementView setDelegate:self];
                [cell setBackgroundColor:[UIColor clearColor]];
                [elementView setFrame:cellFrame];
                [[elementView layer] setCornerRadius: 3.0000f];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                [elementView addGestureRecognizer:panGesture];
                [panGesture release];
                
                [cell setTag:[[documentObject identifier] integerValue] + 3838];
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setFrame: cellFrame];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];
                
                [elementView release];

                break;
            }
        }
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [documentSection hasObjects];
    NSLog(@"Number of items: %d", [objects count]);
    return [objects count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

    MTCollectionReuseableViewDefault *result = nil;
    
    if ([kind isEqualToString:MTCollectionElementKindSectionLabel]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReusableViewFloatingLabel reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 100.0000f, 22.0000f)];
        [label setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];
        [label setText:@"Floating Label"];
        [result addSubview:label];
        [label release];
    } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
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
    return 1;
}

#pragma mark - Collection View Delegate

- (MTElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    MTElementView *result = nil;
    for (id elementView in [[cell contentView] subviews]) {
        //NSLog(@"%@", [[cell contentView] subviews]);
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
        UIView *subview = [[self designScrollView] viewWithTag:[[documentSection identifier] integerValue]];
        if ([subview isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)subview;
            NSArray *selectedObjects = [[self selectedObjectIdsInCollectionView:collectionView] allObjects];
            [results addObjectsFromArray: selectedObjects];
        }
    }
    [enumerator release];
    return [results autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath { }

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return [self respondsToSelector:action];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"Perform action yo!!! %@", NSStringFromSelector(action));
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [documentSection hasObjects];

    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [self performSelector:action withObject:documentObject];
    }
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissAllPopovers];
    [self deselectAllElementsAnimated:NO];
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [self applyBorderToElementView:elementView];
    [self setLastElementViewToShowMenu:elementView];
    return YES;
}

#pragma mark - Delegates
#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[MTSettingsViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        if ([UIDevice isPad]) {
            if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
                [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)insertDocumentObjectDataField:(RptqDatabaseSchemaField *)field {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    if (document) {
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
                                                       MTDocumentObjectDefinationObject : [field objectID]};
            
            RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination toDocument:document];
            
            // MARK: Get a permanent id on insert.  Let's make sure it's correct.
            if ([[documentObject objectID] isTemporaryID]) {
                NSError *error = nil;
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                if (error != nil) {
                    error = nil;
                    [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                    if (error != nil) {
                        [error presentErrorToUser];
                    }
                }
            }
            
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
         
        } completion:^(BOOL finished) {

        }];
    }
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber {
    
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    
    if (document) {
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeAggregate),
                                                       MTDocumentObjectDefinationObject :  @{MTDocumentObjectDefinationAggregateType : @(functionType),
                                                                                             MTDocumentObjectDefinationAggregatePivotNumber : groupNumber,
                                                                                             MTDocumentObjectDefinationAggregatePivotType : @(groupType),
                                                                                             MTDocumentObjectDefinationAggregateObjectId : inputObject,
                                                                                             MTDocumentObjectDefinationAggregateFunctionInputType : @(inputType)}};
            
            RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination toDocument:document];
            
            // MARK: Get a permanent id on insert.  Let's make sure it's correct.
            if ([[documentObject objectID] isTemporaryID]) {
                NSError *error = nil;
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                if (error != nil) {
                    error = nil;
                    [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                    if (error != nil) {
                        [error presentErrorToUser];
                    }
                }
            }
            
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
}

- (void)insertDocumentObjectNewLabel:(NSString *)labelText {

    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    
    if (document) {
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelStatic),
                                                       MTDocumentObjectDefinationObject : labelText};

            RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination toDocument:document];
            
            if ([[documentObject objectID] isTemporaryID]) {
                NSError *error = nil;
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                if (error != nil) {
                    error = nil;
                    [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                    if (error != nil) {
                        [error presentErrorToUser];
                    }
                }
            }
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)insertDocumentObjectNewImage:(UIImage *)image {
    
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    
    if (document) {
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeImage),
                                                       MTDocumentObjectDefinationObject : image};
            
            RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination toDocument:document];
            
            if ([[documentObject objectID] isTemporaryID]) {
                NSError *error = nil;
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                if (error != nil) {
                    error = nil;
                    [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                    if (error != nil) {
                        [error presentErrorToUser];
                    }
                }
            }
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
            
        }];
    }
    
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

    CGPoint adjustedCenter = [UIGestureRecognizer adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            [[self designScrollView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [self setScrollersEnabled: NO];

            [[gestureRecognizer view] setCenter: newCenter];

            {
                NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
                
                RptqDocumentSection *section = [documentObject inSection];
                UICollectionView *svSection = [self getCollectionViewForRptqSection:section];
                
                RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
                
                NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [documentSection hasObjects]];
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
                        [hasObjects removeObjectAtIndex:deleteIndex];
                        [documentSection setHasObjects:hasObjects];
                        [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
                        NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
                        [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                    } completion:^(BOOL finished) {
                        CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
                        [[gestureRecognizer view] setCenter: newCenter];
                        [[self designScrollView] addSubview: [gestureRecognizer view]];
                        
                        [svSection setDelegate:self];
                    }];
                }
                [hasObjects release];
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
            
            
            // MARK: Remove the element from one section and place it into the next new section
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            UICollectionView *newParent = nil;
            
            // MARK: Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designScrollView] subviews]) {
                if (CGRectContainsPoint([view frame], [[gestureRecognizer view] center]) && ![view isEqual:self]) {
                    if ([view isKindOfClass:[UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = [gestureRecognizer locationInView:newParent];
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            if (!addedToNewParent) {
                for (UICollectionView *view in [[self designScrollView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
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
                                
                NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
                
                NSManagedObjectID *objectId = [[gestureRecognizer view] objectIdTag];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID: objectId
                                                                             fromObjectContext: managedObjectContext];
                
                [documentObject setOriginx: @([gestureRecognizer view].frame.origin.x)];
                [documentObject setOriginy: @([gestureRecognizer view].frame.origin.y)];
                [documentObject setSizewidth: @([gestureRecognizer view].frame.size.width)];
                [documentObject setSizeheight: @([gestureRecognizer view].frame.size.height)];
                
                CGPoint newCenter = [[gestureRecognizer view] center];
                [[gestureRecognizer view] removeFromSuperview];
                
                objectId = [newParent objectIdTag];
                RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: objectId
                                                                                        fromObjectContext: managedObjectContext];
                
                NSIndexPath *indexPath = [newParent indexOfAlienViewWithCenterPoint:adjustedCenter];
                if (indexPath == nil) {
                    indexPath = [NSIndexPath indexPathForItem:[newParent numberOfItemsInSection: 0] inSection:0];
                }
                
                NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
                
                for (NSIndexPath *indexPath in indexPaths) {
                    NSMutableDictionary *holderForLastTouches = [[self holderForLastTouchesByCollectionView] objectForKey:@([newParent tag])];
                    [holderForLastTouches setObject:[NSValue valueWithCGPoint:newCenter] forKey:indexPath];
                }
                
                // MARK: Add this to the data context and to the container for the sections collection view.
                [newParent performBatchUpdates:^{
                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[documentSection hasObjects]];
                    [hasObjects insertObject:documentObject atIndex:[indexPath item]];
                    [documentSection setHasObjects:hasObjects];
                    [[[MTActiveDocument sharedDocument] activeDocument] saveContext];
                    [hasObjects release];
                    
                    [newParent insertItemsAtIndexPaths:indexPaths];
                    
                } completion:^(BOOL finished) {
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

#pragma mark - MTElementViewDelegate

- (void)didSelectElementView:(id)sender {
    if ([sender isKindOfClass:[MTElementView class]]) {
        MTElementView *elementView = sender;
        [[self selectedObjectIds] addObject:[elementView objectIdTag]];
        [[elementView layer] setBorderColor:[[UIColor redColor] CGColor]];
        [[elementView layer] setBorderWidth:3.0000f];
        [elementView setDisplaySelected:YES];

        [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
        if ([UIDevice isPad]) {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
            [passThroughViews addObject:elementView];
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            [passThroughViews release];
            
            CGRect popoverRect;
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
}

- (void)didDeselectElementView:(id)sender animated:(BOOL)animated {
    if ([sender isKindOfClass:[MTElementView class]]) {
        MTElementView *elementView = sender;
        [[self selectedObjectIds] removeObject:[elementView objectIdTag]];
        [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
        [[elementView layer] setBorderWidth:0.0000f];
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
        }
    }
}

- (void)didHighlightElementView:(id)sender { }
- (void)didUnhighlightElementView:(id)sender { }

@end
