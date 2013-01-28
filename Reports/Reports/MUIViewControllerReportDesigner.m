//
//  ReportDesignerTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerReportDesigner.h"
#import "UIViewControllerToolBox.h"

@interface MUIViewControllerReportDesigner()
    <FontSettingsTableViewControllerDelegate,
        UITableViewControllerFontSelectorDelegate>

@property (nonatomic, retain) UIViewControllerToolBox *viewControllerToolbox;

@property (nonatomic, retain) UIPopoverController *popoverControllerInformation;
@property (nonatomic, retain) UIPopoverController *popoverControllerObjectSelector;

@property (assign) BOOL toolboxIsVisible;

@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *layoutConstraintsToRemove;

@property (nonatomic, retain) NSMutableDictionary *sectionViews;
@property (nonatomic, retain) IBOutlet UIScrollView *designScrollView;

@property (nonatomic, retain) UIToolbar *toolboxToolbar;
@property (nonatomic, retain) UIView *toolboxBackgroundView;
@property (nonatomic, retain) UIScrollView *toolboxScrollView;
@property (nonatomic, retain) UITableViewControllerFontSettings *tableViewControllerTextLayoutSettings;
@property (nonatomic, retain) UITableViewControllerFontSelector *tableViewControllerFontSelector;

@property (nonatomic, retain) NSArray *toolboxToolbarItemsPrimary;
@property (nonatomic, retain) NSArray *toolboxToolbarItemsFontChooser;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxHidden;
@property (nonatomic, retain) NSArray *toolbarTopItems;
@property (nonatomic, retain) NSArray *toolbarBottomItems;

@property (nonatomic, retain) NSMutableDictionary *collectionViewReuseIdentifiers;

@property (nonatomic, retain) IBOutlet UIView *toolboxView;
@property (nonatomic, retain) IBOutlet UIView *toolboxContainerView;

@property (nonatomic, retain) IBOutlet UIButton *informationButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemObjects;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbarTop;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbarBottom;

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBarToolbox;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemStyle;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemLayout;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemFontChooser;
@property (nonatomic, retain) NSMutableSet *selectedObjectIds;

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlToolbox;

@property (nonatomic, retain) NSMutableDictionary *holderForLastTouchesByCollectionView;

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;   //Not implemented

@end

@implementation MUIViewControllerReportDesigner

#pragma mark - MTCollectionViewLineLayoutDelegate

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if ([AppDelegate isPad]) {
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

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout initialLayoutCenterPointForIndexPath:(NSIndexPath *)indexPath {
    NSValue *result = [[[self holderForLastTouchesByCollectionView] objectForKey:@([collectionView tag])] objectForKey:indexPath];
    return [result CGPointValue];
}

- (void)didSelectElementView:(id)sender {
    if ([sender isKindOfClass:[MTElementView class]]) {
        MTElementView *elementView = sender;
        [[self selectedObjectIds] addObject:[elementView objectIdTag]];
        [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
        [[elementView layer] setBorderColor:[[UIColor redColor] CGColor]];
        [[elementView layer] setBorderWidth:3.0000f];
        
        if ([AppDelegate isPad]) {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
            [passThroughViews addObject:elementView];
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
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
            
            [[self popoverControllerInformation] presentPopoverFromRect:popoverRect inView:[self designScrollView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            
        }
    }
}
- (void)didDeselectElementView:(id)sender {
    if ([sender isKindOfClass:[MTElementView class]]) {
        MTElementView *elementView = sender;
        [[self selectedObjectIds] removeObject:[elementView objectIdTag]];
        [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
        [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
        [[elementView layer] setBorderWidth:0.0000f];
        
        if ([AppDelegate isPad]) {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
            [passThroughViews removeObject:elementView];
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
            [passThroughViews release];
            
            if ([[self popoverControllerInformation] isPopoverVisible]) {   //Should always eval to true
                if ([[self selectedObjectIds] count] > 0) {
                    CGRect popoverRect = [self rectForSelectedElements];
                    [[self popoverControllerInformation] presentPopoverFromRect:popoverRect inView:[self designScrollView] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    
                } else {
                    [[self popoverControllerInformation] dismissPopoverAnimated:YES];
                }
            }
        }
    }
}
- (void)didHighlightElementView:(id)sender { }
- (void)didUnhighlightElementView:(id)sender { }

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

#pragma mark - NSObject

- (void)dealloc {
    [_popoverControllerObjectSelector release];
    [_popoverControllerInformation release];

    [_viewControllerToolbox release];
    [_holderForLastTouchesByCollectionView release];
    
    [_selectedObjectIds release];
    
    [_toolbarTopItems release];
    [_toolbarBottomItems release];
    
    [_layoutConstraintsToolboxHidden release];
    [_layoutConstraintsToolboxVisiable release];
    
    [_navigationItemStyle release];
    [_navigationItemLayout release];
    [_navigationItemFontChooser release];
    
    [_tableViewControllerTextLayoutSettings release];
    [_tableViewControllerFontSelector release];
    
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
    [_toolboxContainerView release];
    [_navigationBarToolbox release];
    [_layoutConstraintsToRemove release];
    [_segmentedControlToolbox release];
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
    
    UIStoryboard *sbFontTableView = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
    
    if ([AppDelegate isPad]) {
        
        UIViewControllerToolBox *viewControllerToolbox = [[UIViewControllerToolBox alloc] initWithNibName:@"MTViewToolbox" bundle:nil];
        [viewControllerToolbox setFontDelegates:self];
        [self setViewControllerToolbox:viewControllerToolbox];
        [viewControllerToolbox release];
        
        UIPopoverController *popoverControllerInformation = [[UIPopoverController alloc] initWithContentViewController:[self viewControllerToolbox]];
        [popoverControllerInformation setDelegate:self];
        [self setPopoverControllerInformation:popoverControllerInformation];
        [popoverControllerInformation release];

    } else {
    
        UITableViewControllerFontSettings *tb1 = [[sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewController"] retain];
        [tb1 setDelegate: self];
        [self setTableViewControllerTextLayoutSettings:tb1];
        [tb1 release];
        
        UITableViewControllerFontSelector *tb2 = [[sbFontTableView instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"] retain];
        [tb2 setDelegate: self];
        [self setTableViewControllerFontSelector:tb2];
        [tb2 release];
        
    }

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
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];

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
    
    for (RptqDocumentSection *reportSection in sectionEnumerator) {

        CGFloat paddingTop = sectionCounter == 0 ? paddingBorder : (2 * paddingBorder);
        [lastCollectionView  release];  //Should be nil on first pass.

        
        // MARK: Create collection view for report document section.
        
        MTCollectionViewLineLayout *flowLayoutDesignerSection = [[MTCollectionViewLineLayout alloc] init];
        [flowLayoutDesignerSection setDelegate:self];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        [backgroundView setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];

        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
        [collectionView setObjectIdTag:[reportSection objectID]];
        NSString *reuse = [collectionViewReuseId stringByAppendingFormat:@"%d", [[reportSection identifier] integerValue]];
        NSMutableDictionary *lastTouches = [[NSMutableDictionary alloc] init];
        [[self holderForLastTouchesByCollectionView] setObject:lastTouches forKey:@(collectionView.tag)];
        [lastTouches release];
        [[self collectionViewReuseIdentifiers] setObject:reuse forKey:[reportSection identifier]];
        [collectionView registerClass: [MTCollectionViewCellElement class] forCellWithReuseIdentifier: reuse];
        [collectionView setTag:[[reportSection identifier] integerValue]];
        [collectionView setDelegate:self];
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
        
        NSLayoutConstraint *layoutConstraintCenter = [NSLayoutConstraint constraintWithItem: collectionView attribute: NSLayoutAttributeCenterX relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeCenterX multiplier: 1.0000f constant: 0.0000f];
        [[self designScrollView] addConstraint:layoutConstraintCenter];
        
        NSLayoutConstraint *layoutConstraintRight = [NSLayoutConstraint constraintWithItem: collectionView attribute: NSLayoutAttributeRight relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeRight multiplier: 1.0000f constant: paddingLabel];
        [[self designScrollView] addConstraint:layoutConstraintRight];

        NSLayoutConstraint *layoutConstraintWidth = [NSLayoutConstraint constraintWithItem: collectionView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeWidth multiplier: 1.0000f constant: -(paddingBorder * 2.0000f)];
        [[self designScrollView] addConstraint:layoutConstraintWidth];

        NSLayoutConstraint *layoutConstraintLabelWidth = [NSLayoutConstraint constraintWithItem: labelSectionIdentifer attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeWidth multiplier: 0.20000f constant: 0.0000f];
        [[self designScrollView] addConstraint:layoutConstraintLabelWidth];
        
        NSLayoutConstraint *layoutConstraintLabelRight = [NSLayoutConstraint constraintWithItem: labelSectionIdentifer attribute: NSLayoutAttributeRight relatedBy: NSLayoutRelationEqual toItem: [self designScrollView] attribute: NSLayoutAttributeRight multiplier: 1.0000f constant: 0.0000f];
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
    
    [[self designScrollView] addConstraints:labelconstraintsVertical];
    [[self designScrollView] setScrollEnabled:YES];
    [[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
    [[self designScrollView] setUserInteractionEnabled:YES];
    [[self designScrollView] flashScrollIndicators];

    [stringContstraintsVertical release];
    [dictionaryViewsVertical release];
    [sectionEnumerator release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidChange:)
                          name: NSManagedObjectContextObjectsDidChangeNotification
                        object: managedObjectContext];
    
    [defaultCenter addObserver: self
                      selector: @selector(managedObjectContextDidSave:)
                          name: NSManagedObjectContextDidSaveNotification
                        object: managedObjectContext];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter removeObserver:self
                             name:NSManagedObjectContextObjectsDidChangeNotification
                           object:managedObjectContext];

    [defaultCenter removeObserver:self
                             name:NSManagedObjectContextDidSaveNotification
                           object:managedObjectContext];

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
                UITableViewControllerSettings *tvcSettings = [[[navController viewControllers] objectAtIndex: 0] retain];
                [tvcSettings setDelegate:self];
                [tvcSettings release];
            }
        }
        [navController release];
    } else if ([[segue identifier] isEqualToString:@"showObjects"]) {
        NSLog(@"Sender :%@", sender);
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            [self setPopoverControllerObjectSelector:[popoverSegue popoverController]];
        }
        MUIViewControllerObjectSelector *viewControllerObjectSelector = [segue destinationViewController];
        [viewControllerObjectSelector setObjectSelectorDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {
        [[AppDelegate activeDocument] refresh];
        
        MUIViewControllerReportViewer *viewControllerReportViewer = [segue destinationViewController];
        [viewControllerReportViewer setDelegate:self];
        
        
    }
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

- (void)managedObjectContextDidSave:(NSNotification *)notification {

}

#pragma mark - Actions

- (NSSet *)elementViews {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
    for (RptqDocumentSection *documentSection in enumerator) {
        UIView *subview = [[self designScrollView] viewWithTag:[[documentSection identifier] integerValue]];
        if ([subview isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)subview;
            for (NSUInteger section = 0; section < [collectionView numberOfSections]; section++) {
                for (NSUInteger item = 0; item < [collectionView numberOfItemsInSection:section]; item++) {
                    MTElementView *elementView = [self elementViewAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] inCollectionView:collectionView];
                    [results addObject:elementView];
                }
            }
        }
    }
    return [results autorelease];
}

- (NSSet *)selectedElementViews {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
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
    return [results autorelease];
}

- (UICollectionView *)getCollectionViewForRptqSection:(RptqDocumentSection *)documentSection {
    return [[self sectionViews] objectForKey:[documentSection sectionKey]];
}

- (void)setCollectionView:(UICollectionView *)collectionView forSection:(RptqDocumentSection *)documentSection {
    [[self sectionViews] setValue:collectionView forKey:[documentSection sectionKey]];
}

- (void)cut:(id)sender {
    NSLog(@"Fake a cut.");
}

- (void)copy:(id)sender {
    NSLog(@"Fake a copy.");
}

- (void)select:(id)sender {
    NSLog(@"Fake a select.");
}

- (void)selectAll:(id)sender {
    NSLog(@"Fake a select all.");
}

- (void)paste:(id)sender {
    NSLog(@"Fake a paste.");
}

- (void)delete:(id)sender {
    NSLog(@"Fake a delete.");
}

- (void)toggleUnderline:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)toggleItalics:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)toggleBoldface:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)showFontChooser:(id)sender {
    
}

- (void)hideFontChooser:(id)sender {
    
}

- (void)customAction:(id)sender {
    NSLog(@"custom action! %@", sender);
}

- (IBAction)segmentedControlToolboxValueChanged:(id)sender {
    if ([sender selectedSegmentIndex] == 0) {
        [[self tableViewControllerTextLayoutSettings] displayStyleSettings];
    } else  if ([sender selectedSegmentIndex] == 1) {
        [[self tableViewControllerTextLayoutSettings] displayLayoutSettings];
    }
}

- (void)openReport:(NSURL *)url {
    UIManagedDocumentPreferencesUser *trvFile = [[UIManagedDocumentPreferencesUser alloc] initWithFileURL:url];
    
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
        [[self delegate] viewControllerDidFinish:self];
    }
}

- (IBAction)showObjects:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showObjects" sender:sender];
    }
}

- (IBAction)showSettings:(id)sender {
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showSettings" sender:sender];
    }
}

- (IBAction)info:(id)sender {
    if (![self dismissAllPopovers]) {
        [self showToolbox:sender];
    }
}

- (IBAction)showToolbox:(id)sender {
    
    if ([AppDelegate isPad]) {
        [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
        [[self popoverControllerInformation] presentPopoverFromBarButtonItem:[self barButtonItemInfo]
                                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                    animated:YES];
        [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
    } else {
        if (![self toolboxIsVisible]) {
            [self setToolboxIsVisible:YES];
            [[self informationButton] setEnabled: NO];
            
            [[[self tableViewControllerTextLayoutSettings] tableView] setFrame: [[self toolboxContainerView] bounds]];
            [[[self tableViewControllerTextLayoutSettings] tableView] setBounds: [[self toolboxContainerView] bounds]];
            [[self tableViewControllerTextLayoutSettings] initalizeDocumentObjects:[self selectedObjectIds]];
            
            [[self toolboxContainerView] addSubview:[[self tableViewControllerTextLayoutSettings] tableView]];
            
            [[self toolbarBottom] setItems:nil animated:YES];
            [[self toolbarTop] setItems:nil animated:YES];
            
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
            [[[self tableViewControllerTextLayoutSettings] tableView] removeFromSuperview];
            [[self informationButton] setEnabled: YES];
        }];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSLog(@"Action %@ with %@", NSStringFromSelector(action), sender);
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
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
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
    NSLog(@"Size for item at %@: %@", indexPath, NSStringFromCGSize(result));
    return result;
}

#pragma mark - Collection View Data Source

// MARK: Load the elements into the sections.

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger row = [indexPath row];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];

    NSString *resuseId = [[self collectionViewReuseIdentifiers] objectForKey:[documentSection identifier]];
    MTCollectionViewCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath];
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
    
        CGSize documentObjectSize = [documentObject viewSize];
        CGRect cellFrame = CGRectMake(CGPointZero.x, CGPointZero.y, documentObjectSize.width, documentObjectSize.height);
        
        switch ([documentObject getType]) {
            case MNSObjectTypeLabel: {
                
                break;
            }
            case MNSObjectTypeLabelDataField: {
                
                for (UIView *subview in [[cell contentView] subviews]) {
                    [subview removeFromSuperview];
                }
                
                RptqDocumentObjectLabelDataField *documentObjectCast = documentObject.isLabelDataField;

                MTElementView *elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID]
                                                                  inObjectContext:managedObjectContext];
                
                [elementView setDelegate:self];
                [cell setBackgroundColor:[UIColor greenColor]];
                [elementView setFrame:cellFrame];
                [[elementView layer] setCornerRadius: 3.0000f];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                [elementView addGestureRecognizer:panGesture];
                [panGesture release];
                
                [cell setTag:[[[documentObjectCast parentObjectLabelDataField] identifier] integerValue] + 3838];
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setFrame: cellFrame];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];

                [elementView release];
                
                break;
            }
            case MNSObjectTypeLabelFormula: {
                break;
            }
            case MNSObjectTypeLabelLabelLink: {
                break;
            }
            default: {
                break;
            }
        }
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[AppDelegate activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [documentSection hasObjects];
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
        NSLog(@"%@", [[cell contentView] subviews]);
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
                //if ([elementView isSelected]) {
                    [result addObject:[elementView objectIdTag]];
                //}
            }
        }
    }
    return [result autorelease];
}

- (NSSet *)selectedObjectIdsCalculated {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
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

/*
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
 
 }
 
*/

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    /*
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    //[elementView setSelected:NO];
    [[self selectedObjectIds] removeObject:[elementView objectIdTag]];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
    [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[elementView layer] setBorderWidth:0.0000f];
    MTLog(@"Deselect");
     */
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    /*
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setHighlight:YES];
    MTLog(@"Highlight");
     */
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    /*
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    //[elementView setSelected:YES];
    [[self selectedObjectIds] addObject:[elementView objectIdTag]];
   [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
    [[elementView layer] setBorderColor:[[UIColor redColor] CGColor]];
    [[elementView layer] setBorderWidth:3.0000f];
    MTLog(@"Select");
     */
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    /*
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setHighlight:NO];
    MTLog(@"Unhighlight");
    */
}

//- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
//    BOOL isSelected = [[collectionView cellForItemAtIndexPath:indexPath] isSelected];
//    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    //MTLog(@"Should deselect?\t%@", [elementView isSelected] ? @"YES" : @"NO");
    //return YES;
//    NSLog(@"shouldDeselectItemAtIndexPath: %@", isSelected ? @"YES" : @"NO");

//    return isSelected;
//}

//- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    //MTLog(@"Should highlight?\t%@", ![elementView highlight] ? @"YES" : @"NO");
//    return YES;
//}

//- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    //MTLog(@"Should select?\t%@", ![elementView isSelected] ? @"YES" : @"NO");
//    NSLog(@"shouldSelectItemAtIndexPath: %@", @"YES");
//    return YES;
//}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"Can Perform Action %@?  %@", NSStringFromSelector(action), [self respondsToSelector:action] ? @"YES" : @"NO");
    return [self respondsToSelector:action];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSLog(@"Perform action yo!!! %@", NSStringFromSelector(action));
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [documentSection hasObjects];

    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [self performSelector:action withObject:documentObject];
    }
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[UITableViewControllerSettings class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ([sender isKindOfClass:[MUIViewControllerObjectSelector class]]) {
        if ([AppDelegate isPad]) {
            if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
                [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
            }
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didSelectDataField:(RptqField *)field {
    if ([AppDelegate isPad]) {
        if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
            [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    if (document) {
        
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            RptqDocumentObject *documentObject = [RptqDocumentObjectLabelDataField addNewLabelDataFeildForField:field
                                                 toDetailSectionOfDocument:document
                                                  withManagedObjectContext:managedObjectContext];
            
            // MARK: Get a permanent id on insert.  Who gives a fuck if it's slow on insert.  Let's make sure it's correct.
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
            [[AppDelegate activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
         
        } completion:^(BOOL finished) {

        }];
    }
}

#pragma mark - Gesture Recognizers

- (CGPoint)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint result = CGPointZero;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        CGPoint anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            piece.layer.anchorPoint = anchorPoint;
            piece.center = locationInSuperview;
        }
        result = locationInSuperview;
    }
    return result;
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
    NSLog(@"pinchView");
    gestureRecognizer.view.transform  = CGAffineTransformMakeScale(gestureRecognizer.scale, gestureRecognizer.scale);
    gestureRecognizer.scale = 1.f;
    
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan: {       // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateBegan
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateChanged
            break;
        }
        case UIGestureRecognizerStatePossible: {    // MARK: UIPinchGestureRecognizer UIGestureRecognizerStatePossible
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
    //NSLog(@"panPiece %@, %@", gestureRecognizer.delaysTouchesBegan ? @"YES" : @"NO", gestureRecognizer.delaysTouchesEnded ? @"YES" : @"NO");

    CGPoint adjustedCenter = [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            [[self designScrollView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [self setScrollersEnabled: NO];
            
            [[gestureRecognizer view] setCenter: newCenter];
            
            [[self designScrollView] addSubview: [gestureRecognizer view]];
            
            
            {
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
                RptqDocumentObjectLabelDataField *datafield = [documentObject isLabelDataField];
                
                if (datafield) {
                    
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
                            [[AppDelegate activeDocument] saveContext];
                            UICollectionView *svSection = [self getCollectionViewForRptqSection:documentSection];
                            NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
                            [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                        } completion:^(BOOL finished) {
                            [svSection setDelegate:self];
                        }];
                    }
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
                                
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag]
                                                                             fromObjectContext:managedObjectContext];
                
                RptqDocumentObjectLabelDataField *datafield = [documentObject isLabelDataField];
                
                if (datafield) {
                    
                    documentObject.originx = @([gestureRecognizer view].frame.origin.x);
                    documentObject.originy = @([gestureRecognizer view].frame.origin.y);
                    documentObject.sizewidth = @([gestureRecognizer view].frame.size.width);
                    documentObject.sizeheight = @([gestureRecognizer view].frame.size.height);
                    
                    CGPoint newCenter = [[gestureRecognizer view] center];
                    [[gestureRecognizer view] removeFromSuperview];
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[newParent objectIdTag]
                                                                                            fromObjectContext:managedObjectContext];
                    //NSIndexPath *indexPath = [newParent indexPathForItemAtPoint:newCenter];
                    //if (indexPath == nil) {
                        NSIndexPath *indexPath = [newParent indexOfAlienViewWithCenterPoint:adjustedCenter];
                        if (indexPath == nil) {
                            indexPath = [NSIndexPath indexPathForItem:[newParent numberOfItemsInSection: 0] inSection:0];
                        }
                    //}
                    
                    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
                    
                    for (NSIndexPath *indexPath in indexPaths) {
                        [[[self holderForLastTouchesByCollectionView] objectForKey:@([newParent tag])] setObject:[NSValue valueWithCGPoint:newCenter] forKey:indexPath];
                    }
                    
                    // MARK: Add this to the data context and to the container for the sections collection view.
                    [newParent performBatchUpdates:^{
                        NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[documentSection hasObjects]];
                        [hasObjects insertObject:documentObject atIndex:[indexPath item]];
                        [documentSection setHasObjects:hasObjects];
                        [[AppDelegate activeDocument] saveContext];
                        [hasObjects release];
                        
                        [newParent insertItemsAtIndexPaths:indexPaths];
                        
                    } completion:^(BOOL finished) {
                    }];
                    
                }
                
            }
            [self setScrollersEnabled:YES];
            [[gestureRecognizer view] setNeedsDisplay];
            break;
        }
        default:
            break;
    }
}

- (NSIndexPath *)insertPathForItemWithCenterPoint:(CGPoint)center {
    
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

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {

    if ([item isEqual:[self navigationItemFontChooser]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {

}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL shouldPopItem = NO;

    if ([item isEqual:[self navigationItemFontChooser]]) {
        shouldPopItem = YES;
        
        CGRect offScreen = CGRectMake([[[self tableViewControllerFontSelector] tableView] frame].origin.x + [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y,
                                      [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self toolboxContainerView] bounds]];
        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[[self tableViewControllerFontSelector] tableView] removeFromSuperview];
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {

    } else if ([item isEqual:[self navigationItemStyle]]) {
    
    }
    
    return shouldPopItem;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL shouldPushItem = NO;
    
    if ([item isEqual:[self navigationItemFontChooser]]) {
        shouldPushItem = YES;

        NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
        NSString *frontName = @"";
        for (NSManagedObjectID *objectId in [self selectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            frontName = [documentObject fontname];
            break;
        }
        [[self tableViewControllerFontSelector] setSelectedFont:[MTFont fontWithFamilyName:frontName]];

        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self toolboxContainerView] bounds]];
        [[[self tableViewControllerFontSelector] tableView] setBounds: [[self toolboxContainerView] bounds]];
        CGRect newRect = [[[self tableViewControllerFontSelector] tableView] frame];
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[self toolboxContainerView] bounds].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y, [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: newRectOffscreen];
        [[self toolboxContainerView] addSubview:[[self tableViewControllerFontSelector] tableView]];

        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame:newRect];
        } completion:^(BOOL finished) {
            
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    return shouldPushItem;
}

#pragma mark - UITableViewControllerFontSelectorDelegate

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    CGFloat currentPointSize = [[[[self tableViewControllerTextLayoutSettings] labelFontName] font] pointSize];
    
    MTFont *font = [[MTFont alloc] initWithFamilyName:fontName andPointSize:currentPointSize];


    [[self tableViewControllerTextLayoutSettings] chooseFont:font];
    
    [font release];
    [[self navigationBarToolbox] popNavigationItemAnimated:YES];
}

#pragma mark - FontSettingsTableViewControllerDelegate

- (void)fontSettingsTableViewControllerDidSelectFontList:(UITableViewControllerFontSettings *)controller {
    [[self navigationBarToolbox] pushNavigationItem:[self navigationItemFontChooser] animated:YES];
}

@end