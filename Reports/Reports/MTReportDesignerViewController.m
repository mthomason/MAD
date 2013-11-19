//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerViewController.h"
#import "DesignerSectionLabel.h"
#import "MTViewControllerBarcode.h"

typedef void (^block_insertObject)(UIStoryboardSegue *);

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
};

NSString * const MTSegueNewDocumentObjectStaticLabelSaveIdentifer = @"MTSegueNewDocumentObjectStaticLabelSaveIdentifer";
NSString * const MTSegueNewDocumentObjectDynamicLabelSaveIdentifer = @"MTSegueNewDocumentObjectDynamicLabelSaveIdentifer";
NSString * const MTSegueChooseWhitespaceSaveIdentifer = @"MTSegueChooseWhitespaceSaveIdentifer";
NSString * const MTSegueChooseImageSaveIdentifer = @"MTSegueChooseImageSaveIdentifer";

const CGFloat MTReportDesignerRulerHeight           = 16.0000f;
const CGFloat MTReportDesignerSectionLabelHeight    = 20.0000f;
CGFloat MTReportDesignerBorderPadding               =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingVertical =  3.0000f;
CGFloat MTReportDesignerCornerRadius                =  5.0000f;
const CGFloat previousScaleWeight                   =  0.6666f;

@interface MTReportDesignerViewController()

@property (nonatomic, retain) NSArray *sectionViewsArray;
@property (nonatomic, retain) NSArray *sectionControlViewsArray;

@property (nonatomic, assign) CGFloat zoomScaleRestore;
@property (nonatomic, assign) CGRect boundsOnDisappear;
@property (nonatomic, assign) BOOL shownAndHidden;

@property (nonatomic, retain) NSArray *viewDidAppearDesignerScrollViewConstraints;
@property (nonatomic, retain) NSArray *viewDidAppearDesignerContentViewConstraints;

@property (nonatomic, retain) NSArray *rulerConstraints;

@property (nonatomic, retain) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *toolbarBottomHeightConstraint;
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

@property (nonatomic, retain) NSMutableDictionary *layoutConstraintsReportSectionHeight;

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

@property (nonatomic, assign) BOOL toolbarBottomZero;

@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithToolbar;
@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithoutToolbar;

@property (nonatomic, assign) BOOL insetsSetup;

@end

@implementation MTReportDesignerViewController

#pragma mark - NSObject

- (void)dealloc {
    [_sectionViewsArray release];
    [_sectionControlViewsArray release];
    [_rulerConstraints release];
    [_viewDidAppearDesignerScrollViewConstraints release];
    [_viewDidAppearDesignerContentViewConstraints release];
    [_rulerView release];
    [_designerContentView release];
    [_reportFooterView release];
    [_navigationControllerSectionLayoutSettings release];
    [_layoutConstraintsReportSectionHeight release];
    [_lastElementViewToShowMenu release];
    [_popoverControllerSectionSettings release];
    [_popoverControllerObjectSelector release];
    [_popoverControllerInformation release];
    [_viewControllerSectionLayoutSettings release];
    [_viewControllerToolbox release];
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
    [_designerScrollView release];
    [_informationButton release];
    [_barButtonItemInfo release];
    [_barButtonItemSettings release];
    [_barButtonItemObjects release];
    [_toolbarBottom release];
    [_toolbarTop release];
    [_toolboxView release];
    [_layoutConstraintsToRemove release];
    [_layoutConstraintDesignerContentViewHeight release];
    [_layoutConstraintContainerToDesignerVertSpace release];
    [_layoutConstraintContainerToDesignerCenterY release];
    [_layoutConstraintContainerToDesignerCenterX release];
    [_toolbarBottomHeightConstraint release];
    [_collectionViewReuseIdentifiers release];
    [_widthConstraints release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];
        if ([UIDevice isLagacyOS]) {
            [[viewRuler layer] setCornerRadius: MTReportDesignerCornerRadius];
            [[viewRuler layer] setMasksToBounds: YES];
            CGColorRef shadowColor = [[UIColor darkGrayColor] CGColor];
            [[viewRuler layer] setBorderColor: shadowColor];
            [[viewRuler layer] setBorderWidth: 1.0000f];
        } else {
            
            [[viewRuler layer] setBorderWidth: 0.5000f];
            [[viewRuler layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
            
        }
        [viewRuler setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setRulerView:viewRuler];
        [viewRuler release];

        [self setBoundsOnDisappear:CGRectZero];
        [self setZoomScaleRestore:-1.0000f];
        [self setShownAndHidden:NO];
        
    }
    return self;
}

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action {
    
    [[self barButtonItemObjects] setEnabled:YES];
    if ([[action identifier] isEqualToString:MTSegueNewDocumentObjectStaticLabelSaveIdentifer]) {
        
        MTDocumentObjectNewStaticLabelViewController *staticLabelViewController = [action sourceViewController];
        NSString *labelText = [staticLabelViewController userInputedText];
        [self insertDocumentObjectNewLabel: labelText];
        
    } else if ([[action identifier] isEqualToString:MTSegueChooseWhitespaceSaveIdentifer]) {
        
        __block MTReportDesignerViewController *reportDesigner = self;
        block_insertObject insert = ^(UIStoryboardSegue *action) {
            [reportDesigner insertDocumentObjectWithDefination:
             @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeWhtiespace)}];
        };
        
        if ([UIDevice isPad]) {
            insert(action);
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                insert(action);
            }];
        }
    } else if ([[action identifier] isEqualToString:MTSegueNewDocumentObjectDynamicLabelSaveIdentifer]) {
        
        __block MTReportDesignerViewController *reportDesigner = self;
        block_insertObject insert = ^(UIStoryboardSegue *action) {
            MTQueryBuilderChooseFieldViewController *dynamicFieldController = [action sourceViewController];
            RptqQueryField *queryField = [dynamicFieldController queryField];
            
            [reportDesigner insertDocumentObjectWithDefination:
             @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
               MTDocumentObjectDefinationObject : [queryField objectID]}];
        };
        
        if ([UIDevice isPad]) {
            insert(action);
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                insert(action);
            }];
        }
        
    } else if ([[action identifier] isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController = [action sourceViewController];
        [self insertDocumentObjectNewAggregateFunctionWithType:[aggregateViewController aggregateFunctionType]
                                                     inputType:MTAggregateFunctionInputTypeField
                                                   inputObject:[aggregateViewController fieldObjectId]
                                                     groupType:[aggregateViewController aggregateGroupByType]
                                                   groupNumber:@([aggregateViewController groupTypeSectionNumber])];

    } else if ([[action identifier] isEqualToString:MTSegueChooseImageSaveIdentifer]) {
        
        __block MTReportDesignerViewController *reportDesigner = self;
        block_insertObject insert = ^(UIStoryboardSegue *action) {
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setDelegate: self];
                [reportDesigner presentViewController:imagePicker animated:YES completion:NULL];
                [imagePicker release];
            }
        };
        
        if ([UIDevice isPad]) {
            insert(action);
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                insert(action);
            }];
        }
        
    } else if ([[action identifier] isEqualToString:@"MTSegueNewDocumentObjectBarcodeSaveIdentifer"]) {

        MTViewControllerBarcode *barcodeViewController = [action sourceViewController];
        
        [[self barButtonItemObjects] setEnabled:YES];

        NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
        [defination setObject:@(MTDocumentObjectTypeBarcode)        forKey:MTDocumentObjectDefinationType];
        [defination setObject:[barcodeViewController barcode]       forKey:MTDocumentObjectDefinationObject];
        RptqQueryField *queryField1 = [[barcodeViewController queryField1] retain];
        RptqQueryField *queryField2 = [[barcodeViewController queryField2] retain];
        if (queryField1 != nil) {
            NSManagedObjectID *objectId = [queryField1 objectID];
            [defination setObject:objectId   forKey:MTDocumentObjectDefinationField1];
        }
        if (queryField2 != nil) {
            NSManagedObjectID *objectId = [queryField2 objectID];
            [defination setObject:objectId   forKey:MTDocumentObjectDefinationField2];
        }
        [queryField1 release];
        [queryField2 release];
        [self insertDocumentObjectWithDefination:defination];
        
        
    } else if ([[action identifier] isEqualToString:@"MTStoryboardSegueUnwindToDesigner"]) {

    }

}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if ([UIDevice isPad] == NO) {
        CGRect navigationToolbarFrame = self.navigationController.toolbar.frame;
        //CGFloat toolBarHeight;
        if (navigationToolbarFrame.size.height != [[self toolbarBottomHeightConstraint] constant]) {
            __block MTReportDesignerViewController *reportDesigner = self;
            [UIView animateWithDuration:0.1000f delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
                [[reportDesigner toolbarBottomHeightConstraint] setConstant:navigationToolbarFrame.size.height];
            } completion:NULL];
        }
    }

}

- (CGFloat)toolbarBottomHeight {
    CGFloat toolbarHeight;
    if ([self toolbarBottomZero]) {
        toolbarHeight = 0.0000f;
    } else {
        toolbarHeight = self.navigationController.toolbar.frame.size.height;
    }
    return toolbarHeight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    __block MTReportDesignerViewController *reportDesigner = self;
    [UIView animateWithDuration:duration delay:0.0000f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [[reportDesigner rulerView] setNeedsDisplay];
    } completion:NULL];
    
    CGFloat toolBarHeight = [self toolbarBottomHeight];
    [UIView animateWithDuration:duration delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
        [[reportDesigner toolbarBottomHeightConstraint] setConstant:toolBarHeight];
    } completion:NULL];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self navigationItem] titleView] sizeToFit];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setInsetsSetup:NO];
    [[self designerScrollView] setBouncesZoom:YES];
    [[self designerScrollView] setScrollsToTop:YES];
    [self setToolbarBottomZero:YES];

    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    NSAttributedString *attributedString = [AppDelegate attributedStringMadDesigner];
    [labelMadDesigner setAttributedText:attributedString];
    [[self navigationItem] setTitleView:labelMadDesigner];
    [[[self navigationItem] titleView] sizeToFit];
    [labelMadDesigner release];
    
    if ([UIDevice isLagacyOS]) {
        MTReportDesignerBorderPadding = 3.0000f;
        MTReportDesignerCornerRadius = 5.0000f;
    } else {
        MTReportDesignerBorderPadding = 0.0000f;
        MTReportDesignerCornerRadius = 0.0000f;
    }
    CGFloat toolBarHeight = [self toolbarBottomHeight];
    [[self toolbarBottomHeightConstraint] setConstant:toolBarHeight];
    
    if ([[[self designerContentView] constraints] count] > 0) {
        [[self designerContentView] removeConstraints:[[self designerContentView] constraints]];
    }
    if ([[[self designerScrollView] constraints] count] > 0) {
        [[self designerScrollView] removeConstraints:[[self designerScrollView] constraints]];
    }
    
    UITapGestureRecognizer *tapGestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapZoom:)];
    [tapGestureDoubleTap setNumberOfTapsRequired:2];
    [tapGestureDoubleTap setNumberOfTouchesRequired:1];
    [tapGestureDoubleTap setDelegate: self];
    [[self designerScrollView] addGestureRecognizer:tapGestureDoubleTap];
    [tapGestureDoubleTap release];
    
    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeLeft   multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeRight  multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc3 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self toolbarTop]    attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f];
    NSArray *constraints = @[lc1, lc2, lc3];
    [[self view] addConstraints:constraints];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    
    MTReportDesignerToolBoxViewController *viewControllerToolbox = [[storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"] retain];
    [viewControllerToolbox setDelegate:self];
    [self setViewControllerToolbox:viewControllerToolbox];
    [viewControllerToolbox release];

    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [[storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier] retain];
    [viewControllerSectionLayoutSettings setDelegate:self];
    [self setViewControllerSectionLayoutSettings: viewControllerSectionLayoutSettings];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self viewControllerSectionLayoutSettings]];

    [[navigationController navigationBar] setBarTintColor:[UIColor tintColor]];
    [[navigationController navigationBar] setTintColor:[UIColor tintColor2]];
    UIColor *whiteColor = [[UIColor whiteColor] retain];
    NSDictionary *textAttribues = @{
                                    NSForegroundColorAttributeName : whiteColor
                                    };
    [[navigationController navigationBar] setTitleTextAttributes:textAttribues];
    [whiteColor release];
    [self setNavigationControllerSectionLayoutSettings:navigationController];
    [navigationController release];
    
    if ([UIDevice isPad] == NO) {   //Don't need a done button in a popover.
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideToolbox:)];
        [[[self viewControllerSectionLayoutSettings] navigationItem] setRightBarButtonItem:doneButton animated:NO];
        [doneButton release];
    }

    [viewControllerSectionLayoutSettings release];

    
    if ([self layoutConstraintsToRemove] != nil) {
        [[self view] removeConstraints:[self layoutConstraintsToRemove]];
    }
    
    if ([UIDevice isPad] == NO) {
        
        NSLayoutConstraint *layoutConstraintToolboxHeight = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.5000f constant: 0.0000f];
        //NSLayoutConstraint *c1c = [NSLayoutConstraint constraintWithItem: [self view]               attribute: NSLayoutAttributeTop    relatedBy: NSLayoutRelationEqual toItem: [self designerScrollView] attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f];
        //NSLayoutConstraint *c2c = [NSLayoutConstraint constraintWithItem: [self designerScrollView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view]      attribute: NSLayoutAttributeHeight    multiplier: 1.0000f constant: 0.0000f];
        
        //NSLayoutConstraint *layoutConstraintToolbarBottomHeight = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        NSArray *layoutConstraintsToolboxVisiable = @[layoutConstraintToolboxHeight];
        [self setLayoutConstraintsToolboxVisiable:layoutConstraintsToolboxVisiable];
        
        
        NSLayoutConstraint *layoutConstraintToolbarBottomHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom] attribute: NSLayoutAttributeHeight multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *layoutConstraintToolboxHeightHidden = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.0000f constant: 0.0000f];
        [self setLayoutConstraintsToolboxHidden:@[layoutConstraintToolboxHeightHidden, layoutConstraintToolbarBottomHeightHidden]];
        
        NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem: [self view]               attribute: NSLayoutAttributeTop    relatedBy: NSLayoutRelationEqual toItem: [self designerScrollView] attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem: [self designerScrollView] attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolbarBottom]      attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem: [self toolbarBottom]      attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self toolboxView]        attribute: NSLayoutAttributeTop    multiplier: 1.0000f constant: 0.0000f];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem: [self toolboxView]        attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual toItem: [self view]               attribute: NSLayoutAttributeBottom multiplier: 1.0000f constant: 0.0000f];
        NSArray *constraints = @[layoutConstraintToolboxHeightHidden, c1, c2, c3, c4];
        [[self view] addConstraints:constraints];
    }

    
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
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [self setSelectedObjectIds:set];
    [set release];
    
    [self setToolbarTopItems:[[self toolbarTop] items]];
    [self setToolbarBottomItems:[[self toolbarBottom] items]];
    [self setToolboxIsVisible:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setZoomScaleRestore:[[self designerScrollView] zoomScale]];
    [[self designerScrollView] setZoomScale:1 animated:NO];

    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
                        object: activeDocument];
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
    
    //UICollectionView *lastCollectionView = nil;
    NSInteger sectionCounter = 0;
    UInt16 numberOfSections = [sectionEnumerator count];
    
    NSMutableDictionary *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setLayoutConstraintsReportSectionHeight:layoutConstraintsReportSectionHeight];
    [layoutConstraintsReportSectionHeight release];
    
    NSMutableDictionary *dictionarySectionBackgroundViews = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionBackgroundViews:dictionarySectionBackgroundViews];
    [dictionarySectionBackgroundViews release];
    
    NSMutableDictionary *dictionarySections = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionViews: dictionarySections];
    [dictionarySections release];
    
    NSMutableDictionary *dictionarySectionControls = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionControlViews:dictionarySectionControls];
    [dictionarySectionControls release];
    
    NSMutableDictionary *collectionViewReuseIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setCollectionViewReuseIdentifiers:collectionViewReuseIdentifiers];
    [collectionViewReuseIdentifiers release];
    
    [[self designerContentView] addSubview:[self rulerView]];
    
    
    NSMutableArray *viewDidAppearDesignerScrollViewConstraints = [[NSMutableArray alloc] init];
    NSMutableArray *viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] init];

    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem:[self rulerView] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil                        attribute:NSLayoutAttributeNotAnAttribute multiplier: 1.0000f constant: MTReportDesignerRulerHeight];
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem:[self rulerView] attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeTop            multiplier: 1.0000f constant: MTReportDesignerBorderPaddingVertical];
    NSLayoutConstraint *constraint3 = [NSLayoutConstraint constraintWithItem:[self rulerView] attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeLeft           multiplier: 1.0000f constant: MTReportDesignerBorderPadding];
    NSLayoutConstraint *constraint4 = [NSLayoutConstraint constraintWithItem:[self rulerView] attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeRight          multiplier: 1.0000f constant: -MTReportDesignerBorderPadding];
    
    NSArray *rulerConstraints = @[constraint1, constraint2, constraint3, constraint4];
    [self setRulerConstraints:rulerConstraints];

    [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:[self rulerConstraints]];
    [[self designerScrollView] addConstraints:[self rulerConstraints]];

    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    NSMutableArray *reportSectionKeyTracker = [[NSMutableArray alloc] init];
    
    NSMutableArray *sectionControlViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray *sectionViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        @autoreleasepool {
            
            
            sectionHeights += MTReportDesignerBorderPaddingVertical;
            
            //[lastCollectionView  release];  //Should be nil on first pass.
            
            // MARK: Create collection view for report document section.
            
            MTReportDesignerSectionViewLayoutLiquid *flowLayoutDesignerSection = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];
            [flowLayoutDesignerSection setDelegate:self];
            
            MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
            [backgroundView setNumberOfRowsInBackground:[[reportSection numberOfRows] integerValue]];
            //[backgroundView setBackgroundColor:[UIColor edaGreenLight]];
            [backgroundView setBackgroundColor:[UIColor clearColor]];
            
            NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
            
            MTDocumentSectionView *collectionView = [[MTDocumentSectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayoutDesignerSection];
            [collectionView setObjectIdTag:[reportSection objectID]];
            
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
            BOOL visibility = [[reportSection visibility] boolValue];
            UIColor *bgcolor = [MTReportDesignerViewController sectionBackgroundColor:visibility];
            [collectionView setBackgroundColor:bgcolor];
            [collectionView setClipsToBounds:YES];
            [collectionView setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
            [collectionView setAllowsSelection:YES];
            [collectionView setAllowsMultipleSelection:YES];
            [collectionView setBackgroundView:backgroundView];
            [collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            
            
            // MARK: Create label to identify document section.
            DesignerSectionLabel *sectionControlView = [[DesignerSectionLabel alloc] initWithDisplayText:[reportSection localizedDisplayName]];
            [sectionControlView setBackgroundColor:[UIColor clearColor]];
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
            
            if ([UIDevice isLagacyOS]) {
                CGColorRef shadowColor = [[UIColor darkGrayColor] CGColor];
                [[collectionView layer] setBorderColor: shadowColor];
                [[collectionView layer] setBorderWidth: 1.0000f];
            } else {
                [[collectionView layer] setBorderColor: [[UIColor lightGrayColor] CGColor]];
                [[collectionView layer] setBorderWidth: 1.0000f / [[UIScreen mainScreen] scale]];
            }
            
            [[self sectionBackgroundViews] setValue:backgroundView forKey:collectionViewKey];
            
            CGFloat reportSectionHeight = [[reportSection height] floatValue];
            sectionHeights += reportSectionHeight;
            
            NSString *lastKey = [reportSectionKeyTracker lastObject];
            id constraintItem =  sectionCounter == 0 ? [self rulerView] : /*lastCollectionView;*/ [[self sectionViews] objectForKey:lastKey];
            
            [[self designerContentView] addSubview:collectionView];
            
            
            /*
            if ([UIDevice isModernOS]) {
                UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
                UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
                
                NSNumber *maximumRelativeValue = @(10.0000f);
                NSNumber *minimumRelativeValue = @(-10.0000f);
                
                [xAxis setMaximumRelativeValue:maximumRelativeValue];
                [xAxis setMinimumRelativeValue:minimumRelativeValue];
                [yAxis setMaximumRelativeValue:maximumRelativeValue];
                [yAxis setMinimumRelativeValue:minimumRelativeValue];
                
                UIMotionEffectGroup *motionGroup = [[UIMotionEffectGroup alloc] init];
                NSArray *motionEffects = @[xAxis, yAxis];
                [motionGroup setMotionEffects:motionEffects];
                [sectionControlView addMotionEffect:motionGroup];
                
                [motionGroup release];
                [yAxis release];
                [xAxis release];
            } */
            
            [[self designerContentView] addSubview:sectionControlView];
            
            
            NSLayoutConstraint *lc1a = [NSLayoutConstraint constraintWithItem: constraintItem     attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeTop            multiplier:1.0000f constant: -MTReportDesignerBorderPaddingVertical];
            NSLayoutConstraint *lc1b = [NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationGreaterThanOrEqual toItem: nil             attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant: reportSectionHeight];
            NSLayoutConstraint *lc1c = [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeRight  relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeRight          multiplier:1.0000f constant: -MTReportDesignerBorderPaddingVertical];
            NSLayoutConstraint *lc1d = [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeBottom relatedBy: NSLayoutRelationEqual              toItem: collectionView  attribute: NSLayoutAttributeBottom         multiplier:1.0000f constant: -MTReportDesignerBorderPaddingVertical];
            NSLayoutConstraint *lc1e = [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual              toItem: nil             attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant: MTReportDesignerSectionLabelHeight];
            NSArray *designerContentViewConstraints = @[lc1a, lc1b, lc1c, lc1d, lc1e];
            [[self designerContentView] addConstraints:designerContentViewConstraints];
            [viewDidAppearDesignerContentViewConstraints addObjectsFromArray:designerContentViewConstraints];
            
            
            NSLayoutConstraint *lc2a = [NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeLeft  relatedBy: NSLayoutRelationEqual toItem: [self designerContentView] attribute: NSLayoutAttributeLeft  multiplier: 1.0000f constant: MTReportDesignerBorderPadding];
            NSLayoutConstraint *lc2b = [NSLayoutConstraint constraintWithItem: collectionView     attribute: NSLayoutAttributeRight relatedBy: NSLayoutRelationEqual toItem: [self designerContentView] attribute: NSLayoutAttributeRight multiplier: 1.0000f constant: -MTReportDesignerBorderPadding];
            NSLayoutConstraint *lc2c = [NSLayoutConstraint constraintWithItem: sectionControlView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationGreaterThanOrEqual toItem: [self designerContentView] attribute: NSLayoutAttributeWidth multiplier: 0.2000f constant: 0.0000f];
            NSArray *collectionViewConstraints = @[lc2a, lc2b, lc2c];
            [[self designerScrollView] addConstraints:collectionViewConstraints];
            [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:collectionViewConstraints];
            
            
            if ([[reportSection type] integerValue] == MNSDocumentSectionTypeReportFooter) {
                [self setReportFooterView:collectionView];
            }
            [sectionViewsArray addObject:collectionView];
            [sectionControlViewsArray addObject:sectionControlView];
            [[self sectionViews] setValue:collectionView forKey:collectionViewKey];
            [[self sectionControlViews] setValue:sectionControlView forKey:collectionViewKey];
            
            
            [reportSectionKeyTracker addObject:collectionViewKey];
            
            [collectionView release];
            [sectionControlView release];
            [backgroundView release];
            [flowLayoutDesignerSection release];
            
            
            sectionCounter++;
            
        }
        
    }
    [self setSectionViewsArray: sectionViewsArray];
    [self setSectionControlViewsArray:sectionControlViewsArray];
    [sectionControlViewsArray release];
    [sectionViewsArray release];
    
    [reportSectionKeyTracker release];
    
    sectionHeights += MTReportDesignerBorderPaddingVertical;
    
    //[lastCollectionView release];
    
    //[viewRuler release];
    
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
    NSLayoutConstraint *layoutConstraint23 = [NSLayoutConstraint constraintWithItem:[self designerScrollView] attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self designerContentView] attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f];
    NSArray *endScrollViewConstraints = @[layoutConstraintDesignerContentViewHeight, layoutConstraint23];
    
    [[self designerScrollView] addConstraints:endScrollViewConstraints];
    [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:endScrollViewConstraints];
    
    [self setViewDidAppearDesignerScrollViewConstraints:viewDidAppearDesignerScrollViewConstraints];
    [self setViewDidAppearDesignerContentViewConstraints:viewDidAppearDesignerContentViewConstraints];
    
    [viewDidAppearDesignerContentViewConstraints release];
    [viewDidAppearDesignerScrollViewConstraints release];
    
    if ([self layoutConstraintContainerToDesignerCenterY] != nil && [self layoutConstraintContainerToDesignerCenterX] != nil && [self layoutConstraintContainerToDesignerVertSpace] != nil) {
        
        NSArray *someCenterConstraints = @[[self layoutConstraintContainerToDesignerCenterY], [self layoutConstraintContainerToDesignerCenterX], [self layoutConstraintContainerToDesignerVertSpace]];
        
        [[self designerScrollView] removeConstraints: someCenterConstraints];
    }
    [[self designerScrollView] setScrollEnabled:YES];
    [[self designerScrollView] setMaximumZoomScale:4.0000f];
    [[self designerScrollView] setMinimumZoomScale:1.0000f];
    [[self designerScrollView] setDelegate:self];
    [[self designerScrollView] setUserInteractionEnabled:YES];
    [[self designerScrollView] setBackgroundColor:[UIColor lightGrayColor]];
    [[self designerScrollView] setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    [[self designerScrollView] flashScrollIndicators];
    
    [activeDocument release];
    [sectionEnumerator release];

}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self insetsSetup] == NO) {
        UIEdgeInsets edges = [self designerScrollView].contentInset;
        [self setEdgeInsetsWithToolbar:edges];
        
        UIEdgeInsets corrected = UIEdgeInsetsMake(edges.top, edges.left, 0.0000f, edges.right);
        [self setEdgeInsetsWithoutToolbar:corrected];
        
        [self setInsetsSetup:YES];
    }
    
    [self setScrollersEnabled:YES];
    if ([self shownAndHidden] && [self zoomScaleRestore] > 1.0001) {
        [[self designerScrollView] setZoomScale:[self zoomScaleRestore] animated:NO];
        [self scrollViewDidEndZooming:nil withView:nil atScale:[[self designerScrollView] zoomScale]];
        [[self designerScrollView] scrollRectToVisible:[self boundsOnDisappear] animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setBoundsOnDisappear:[[self designerScrollView] bounds]];
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    
    //[[self designerScrollView] setZoomScale:1.0000f animated:animated];
    
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
                           object: activeDocument];
    
    [activeDocument saveContext];
    [activeDocument release];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (animated) {
        
        CGFloat animationDuration = 0.2222f;
        CGFloat delay = 0.0000f;
        
        [UIView animateWithDuration:animationDuration delay:delay options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [[self rulerView] removeFromSuperview];
        } completion:NULL];
        
        for (UIView *view in [self sectionViewsArray]) {
            __block UIView *bview = view;
            [UIView animateWithDuration:animationDuration delay:delay options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [bview removeFromSuperview];
            } completion:NULL];
        }
        for (UIView *view in [self sectionControlViewsArray]) {
            __block UIView *bview = view;
            [UIView animateWithDuration:animationDuration delay:delay options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [bview removeFromSuperview];
            } completion:NULL];
        }
        
    } else {
        [[self rulerView] removeFromSuperview];
        for (UIView *view in [self sectionViewsArray]) {
            [view removeFromSuperview];
        }
        for (UIView *view in [self sectionControlViewsArray]) {
            [view removeFromSuperview];
        }
    }
    
    [[self designerScrollView] removeConstraints:[self viewDidAppearDesignerScrollViewConstraints]];
    [[self designerScrollView] removeConstraints:[self viewDidAppearDesignerContentViewConstraints]];
    [self setShownAndHidden:YES];
}

- (CGSize)designerContentViewSize {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
    CGSize designerContentViewSize = CGSizeMake([[self view] bounds].size.width, CGSizeZero.height);
    designerContentViewSize.height += MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
        designerContentViewSize.height += [[reportSection height] floatValue];
    }
    designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
    [sectionEnumerator release];
    [activeDocument release];
    return designerContentViewSize;
}

+ (UIColor *)sectionBackgroundColor:(BOOL)isVisible {
    return isVisible ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.70000f];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
    CGSize designerContentViewSize = CGSizeMake([[self view] bounds].size.width, CGSizeZero.height);
    designerContentViewSize.height += MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        CGFloat height = [[reportSection height] floatValue];
        NSString *key = [reportSection sectionKey];
        NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:key];
        [layoutConstraint setConstant:height];
        designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
        designerContentViewSize.height += [[reportSection height] floatValue];
    }
    designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
    [sectionEnumerator release];
    
    [[self layoutConstraintDesignerContentViewHeight] setConstant:designerContentViewSize.height];
    [activeDocument release];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showObjects"]) {
        
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            [[self barButtonItemObjects] setEnabled:NO];
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            UIPopoverController *popoverController = [popoverSegue popoverController];
            [popoverController setDelegate:self];
            //UINavigationController *nav = (UINavigationController *)[popoverController contentViewController];
            //[[nav toolbar] setBarTintColor:[UIColor greenColor]];
            CGSize popoverSize = CGSizeMake(320.0000f, 420.0000);
            [popoverController setPopoverContentSize:popoverSize animated:NO];
            [self setPopoverControllerObjectSelector:popoverController];
        }
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            UINavigationController *d = [segue destinationViewController];
            MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = (MTReportDesignerObjectSelectorViewController *)[d topViewController];
            [viewControllerObjectSelector setObjectSelectorDelegate:self];
            
        } else {
            MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = [segue destinationViewController];
            [viewControllerObjectSelector setObjectSelectorDelegate:self];
        }
    } else if ([[segue identifier] isEqualToString:@"MTSegueShowReportViewer"]) {

        //MTReportViewerController *viewControllerReportViewer;
        //if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            //UINavigationController *d = [segue destinationViewController];
            //viewControllerReportViewer = (MTReportViewerController *)[d topViewController];
        //} else {
            //viewControllerReportViewer = [segue destinationViewController];
        //}
        //[viewControllerReportViewer setViewControllerDelegate:self];
        //[viewControllerReportViewer setDocumentReport:activeDocument];
        
        
        // Page sheet and form sheet don't seem to unwind using segues.
        if ([UIDevice isPad]) {
            MTReportViewerController *viewControllerReportViewer;
            UINavigationController *d = [segue destinationViewController];
            viewControllerReportViewer = (MTReportViewerController *)[d topViewController];
            [viewControllerReportViewer setViewControllerDelegate:self];
        }
        [[self designerScrollView] scrollRectToVisible:CGRectZero animated:NO];

    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {
        [[self designerScrollView] scrollRectToVisible:CGRectZero animated:NO];
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    UIView *result = [self designerContentView];
    return result;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    
    scale *= [[[[self designerScrollView] window] screen] scale];

    [[self rulerView] setContentScaleFactor:scale];
    [[self rulerView] setNeedsDisplay];

    NSSet *elementViews = [[self elementViews] retain];
    for (MTElementView *elementView in elementViews) {
        if ([[[elementView displayLabel] text] length] > 0) {
            [[elementView displayLabel] setContentScaleFactor:scale];
        } else if ([elementView imageView] != nil) {
            [[elementView imageView] setContentScaleFactor:scale];
        }
    }
    [elementViews release];
    elementViews = nil;
    
    NSArray *controlViews = [[self sectionControlViewsArray] retain];
    for (DesignerSectionLabel *controlView in controlViews) {
        [[controlView labelSectionIdentifer] setContentScaleFactor:scale];
    }
    [controlViews release];
    controlViews = nil;
}

#pragma mark - Document State

- (void)documentStateChanged {
    MAReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
    UIDocumentState state = [activeDocument documentState];
    switch (state) {
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
}

- (void)enableUserInteraction:(id)sender {
    [[self view] setUserInteractionEnabled:YES];
}

- (void)disableUserInteraction:(id)sender {
    [[self view] setUserInteractionEnabled:NO];
}

#pragma mark - Layout Settings Delegate

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                forQuery: query];

    [RptqDocumentSection setHeight:height forSectionAtRow:[self lastSelectedSectionControlPanel] inDocument:document];
    UICollectionView *documentSectionView = [[self getSectionViewForDocumentSection: documentSection] retain];

    [documentSection setLayoutHeight:@([[documentSectionView collectionViewLayout] collectionViewContentSize].height)];
    [[reportDocument managedObjectContext] save:nil];
    //[reportDocument quickSave];
    
    MTReportDesignerSectionBackgroundView *backgroundView = [[[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]] retain];
    [backgroundView setNeedsDisplay];
    [backgroundView release];
    
    [[documentSectionView collectionViewLayout] invalidateLayout];
    [documentSection setLayoutHeight:@([[documentSectionView collectionViewLayout] collectionViewContentSize].height)];
    [documentSectionView release];

    [[self view] setNeedsUpdateConstraints];
    
}

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {

    NSUInteger selectedSectionNumber = [self lastSelectedSectionControlPanel];
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    RptqDocument *document = [activeDocument activeDocument];
    [RptqDocumentSection setVisibility: isVisible
                       forSectionAtRow: selectedSectionNumber
                            inDocument: document];
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: selectedSectionNumber
                                                                                forQuery: query];
    
    UICollectionView *documentSectionView = [[self getSectionViewForDocumentSection: documentSection] retain];
    UIColor *color = [MTReportDesignerViewController sectionBackgroundColor:isVisible];
    [documentSectionView setBackgroundColor:color];
    [activeDocument saveContext];
    [activeDocument release];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];

    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[documentSectionView objectIdTag] fromObjectContext:managedObjectContext];
    [documentSection setHeight:@([documentSectionView bounds].size.height)];
    

    [self relayoutSectionView:documentSectionView];
    
    [managedObjectContext save:nil];
    [activeDocument release];
}

- (void)relayoutSectionView:(MTDocumentSectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [[objectId URIRepresentation] retain];
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];

    NSManagedObjectContext *managedObjectContect = [activeDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:objectId fromObjectContext:managedObjectContect];

    NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:[objectIdUrl absoluteString]];
    [layoutConstraint setConstant:documentSection.height.floatValue];
    [objectIdUrl release];
    
    [activeDocument release];
    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - Toolbox Delegate

- (void)heightChanged:(CGFloat)newHeight {
    CGSize newSize = CGSizeMake(320.0000f, newHeight);
    [[self popoverControllerInformation] setPopoverContentSize:newSize animated:YES];
    [[[self popoverControllerInformation] contentViewController] setPreferredContentSize:newSize];

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
    
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[reportSection identifier] integerValue]];
        if ([(UIView *)sender isDescendantOfView: documentSectionView]) {
            [[documentSectionView collectionViewLayout] invalidateLayout];
        }
    }
    [(MTElementView *)sender updateDisplayLabel];
    [sender setNeedsDisplay];
    [sectionEnumerator release];
    [activeDocument release];
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    BOOL editedImageExist = [info objectForKey:UIImagePickerControllerEditedImage] != nil;
    UIImage *selectedImage = nil;
    if (editedImageExist) {
        selectedImage = [[info objectForKey:UIImagePickerControllerEditedImage] retain];
    } else {
        selectedImage = [[info objectForKey:UIImagePickerControllerOriginalImage] retain];
    }
    
    
    if (selectedImage != nil) {
        __block MTReportDesignerViewController *reportDesigner = self;
        [self dismissViewControllerAnimated:YES completion:^{
            [reportDesigner insertDocumentObjectWithDefination:
             @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeImage),
               MTDocumentObjectDefinationObject : selectedImage}];
        }];
    }
    
    [[self barButtonItemObjects] setEnabled:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[self barButtonItemObjects] setEnabled:YES];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item tag] != MTTabBarItemTagDesigner) {
        [self hideToolbox];
    }
}

#pragma mark - Actions

- (void)doubleTapZoom:(UITapGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateEnded) {
        CGFloat initalZoomScale = [[self designerScrollView] zoomScale];
        BOOL zoomIn = initalZoomScale < 1.500f;
        BOOL zoomIn2 = zoomIn == NO && initalZoomScale < 2.5000f;
        CGFloat zoomScale = zoomIn ? 2.0000f : zoomIn2 ? 3.0000f : 1.0000f;

        [[self designerScrollView] setContentOffset:CGPointZero animated:NO];
        [[self designerScrollView] setZoomScale:zoomScale animated:YES];
        [self scrollViewDidEndZooming:[self designerScrollView] withView:[self designerContentView] atScale:zoomScale];
        
        __block UIScrollView *blockScrollView = [self designerScrollView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [blockScrollView setContentOffset:CGPointZero animated:NO];
            });
        });
        // FIXME: Zoom to double tap point.
    }
}

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
                    [self hideToolbox];
                }
                
            } else {
                
                [self deselectAllElementsAnimated:YES];
                
                [self applyBorderToView:[sender view]];
                
                [self setLastSelectedSectionControlPanel:[[sender view] tag]];
                
                MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
                RptqDocument *document = [reportDocument activeDocument];
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
//
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
    if ([view isKindOfClass:[DesignerSectionLabel class]] && [UIDevice isModernOS]) {
        DesignerSectionLabel *sectionLabel = (DesignerSectionLabel *)view;
        [sectionLabel dimView];
    } else {
        [[view layer] setBorderColor:[[[self view] tintColor] CGColor]];
        [[view layer] setBorderWidth:1.0000f];
    }
}

- (BOOL)removeBorderFromView:(UIView *)view {
    BOOL result;
    if ([view isKindOfClass:[DesignerSectionLabel class]] && [UIDevice isModernOS]) {
        DesignerSectionLabel *sectionLabel = (DesignerSectionLabel *)view;
        if ([sectionLabel selected]) {
            [sectionLabel normalView];
            result = YES;
        } else {
            result = NO;
        }

    } else {

        if ([self isBorderAppliedToView:view]) {
            result = YES;
            [[view layer] setBorderColor:[[UIColor blackColor] CGColor]];
            [[view layer] setBorderWidth:0.0000f];
        } else {
            result = NO;
        }

    }
    return result;
}

- (BOOL)isBorderAppliedToView:(UIView *)view {
    BOOL result = ([[view layer] borderWidth] > 0.5000f);
    if (result == NO) {
        if ([view isKindOfClass:[DesignerSectionLabel class]] && [UIDevice isModernOS]) {
            result = [(DesignerSectionLabel *)view selected];
        }
    }
    return result;
}

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if ([UIDevice isPad]) {
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
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
    
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:
                                     [activeDocument managedObjectContext]];
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
    [activeDocument release];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];

    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
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
    [activeDocument release];
    return [results autorelease];

}

- (UICollectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return [[self sectionViews] objectForKey:[documentSection sectionKey]];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return [[self sectionControlViews] objectForKey:[documentSection sectionKey]];
}

- (IBAction)done:(id)sender {
    
    NSError *error = nil;
    MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    [[reportDocument managedObjectContext] save:&error];
    if (error != nil) {
        [[reportDocument managedObjectContext] save:&error];
    }

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
    [[self barButtonItemObjects] setEnabled:NO];
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
            [[self navigationControllerSectionLayoutSettings] setNavigationBarHidden:NO animated:NO];
            viewController = [[self navigationControllerSectionLayoutSettings] retain];
            break;
        }
        default:
            break;
    }

    if ([UIDevice isLagacyOS] || tooboxType == MTToolboxTypeElement) {
        [[viewController view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.toolboxView.frame.size.width, self.toolboxView.frame.size.height)];
    }
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
            
            __block MTReportDesignerViewController *reportDesigner = self;

            [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
                //[self setWantsFullScreenLayout:YES];
                
                [[reportDesigner view] removeConstraints:[self layoutConstraintsToolboxHidden]];
                [[reportDesigner view] addConstraints:[self layoutConstraintsToolboxVisiable]];
                [[reportDesigner toolbarBottomHeightConstraint] setConstant:0.0000f];
                UIEdgeInsets insets = [reportDesigner edgeInsetsWithoutToolbar];
                [[reportDesigner designerScrollView] setContentInset: insets];

                [[reportDesigner view] layoutIfNeeded];
            } completion:^(BOOL finished) {
                
                if (finished) {
                    
                    CGRect rectToShow = CGRectZero;
                    
                    if (tooboxType == MTToolboxTypeSection) {
                        MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
                        RptqDocument *document = [reportDocument activeDocument];
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
                        [[reportDesigner designerScrollView] setContentOffset:offsetPoint animated:YES];
                        
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

            CGFloat toolBarHeight = [self toolbarBottomHeight];
            __block MTReportDesignerViewController *reportDesigner = self;
            [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: ^{
                [[reportDesigner view] removeConstraints:[self layoutConstraintsToolboxVisiable]];
                [[reportDesigner view] addConstraints:[self layoutConstraintsToolboxHidden]];
                [[reportDesigner toolbarBottomHeightConstraint] setConstant:toolBarHeight];
                UIEdgeInsets insets = [reportDesigner edgeInsetsWithToolbar];
                [[reportDesigner designerScrollView] setContentInset: insets];
                [[reportDesigner view] layoutIfNeeded];
                
            } completion:^(BOOL finished) {
                if (finished) {
                    if ([[[reportDesigner navigationControllerSectionLayoutSettings] view] superview] != nil) {
                        [[[reportDesigner navigationControllerSectionLayoutSettings] view] removeFromSuperview];
                    }
                    if ([[[reportDesigner viewControllerToolbox] view] superview] != nil) {
                        [[[reportDesigner viewControllerToolbox] view] removeFromSuperview];
                    }
                    [[reportDesigner toolbarBottom] setItems:[self toolbarBottomItems] animated:YES];
                    [[reportDesigner toolbarTop] setItems:[self toolbarTopItems] animated:YES];
                    [[reportDesigner informationButton] setEnabled: YES];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
    [activeDocument release];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self deselectAllElementsAnimated:YES];
    [[self barButtonItemObjects] setEnabled:YES];
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
            MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
            NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            [RptqDocumentObject removeDocumentObject:documentObject];
            [activeDocument release];
        }
    }];
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    //NSManagedObjectID *objectId = [cell objectIdTag];
}

#pragma mark -
#pragma mark Collection View Layout Delegate

- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    [activeDocument release];
    return [[documentSection height] floatValue];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
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
    [activeDocument release];
    return result;
}

- (MTCollectionViewLayoutLiquidAttributes *)collectionView: (UICollectionView *)collectionView
                                                    layout: (UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {

    
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    MTCollectionViewLayoutLiquidAttributes *result = [[MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath] retain];
    
    if ([objects count] > [indexPath item]) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath item]];
        [result setDropPoint: CGPointMake([[documentObject dropPointX] floatValue], [[documentObject dropPointY] floatValue])];
        [result setFrame:CGRectMake(result.dropPoint.x, result.dropPoint.y, documentObject.viewSize.width, documentObject.viewSize.height)];

        [result setLastTouchPoint: result.dropPoint];
        [result setDropIndex: [[documentObject dropIndex] integerValue]];
        [result setDescription:[documentObject toStringHumanReadable]];
    } else {
        [result setDropPoint: CGPointZero];
        [result setLastTouchPoint:CGPointZero];
        [result setDropIndex:0];
        [result setFrame:CGRectZero];
    }
    [result setLastTouchPointValid: NO];
    [activeDocument release];
    return [result autorelease];
}

- (NSUInteger)collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
    [activeDocument release];
    return dropIndex;
}

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
          setDropPoint:(CGPoint)dropPoint
    forItemAtIndexPath:(NSIndexPath *)indexPath {

    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];

    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
        
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        NSNumber *dropPointX = @(dropPoint.x);
        NSNumber *dropPointY = @(dropPoint.y);
        [documentObject setDropPointX:dropPointX];
        [documentObject setDropPointY:dropPointY];
        [[documentObject managedObjectContext] save:nil];
    }
    [activeDocument release];
}


#pragma mark Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat contextScale = [[self designerScrollView] zoomScale] * [[[[self designerScrollView] window] screen] scale];

    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
                
                
                
                MTElementView *elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID]
                                                                     inObjectContext:managedObjectContext];
               
                [elementView setDelegate:self];
                [elementView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                
                if ([UIDevice isLagacyOS]) {
                    [[elementView layer] setCornerRadius: MTReportDesignerCornerRadius];
                    [[elementView layer] setBorderColor:[[UIColor blackColor] CGColor]];
                    [[elementView layer] setBorderWidth:1.0000f];
                }
                
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

                
                [elementView setFrame:cellFrame];
                
                
                //[elementView setContainer: cell];
                //[elementView setContainerGroup: collectionView];
                                
                [cell setTag:[[documentObject identifier] integerValue] + 3838];
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setUserInteractionEnabled:YES];
                
                //UIView *contentView = [cell contentView];
                

                        [[cell contentView] addSubview:elementView];
                
                __block UICollectionViewCell *blockCell = cell;
                __block MTElementView *blockElementView = elementView;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [blockCell setContentScaleFactor:contextScale];
                        [[blockCell contentView] setContentScaleFactor:contextScale];
                        [blockElementView setContentScaleFactor:contextScale];
                        [[blockElementView displayLabel] setContentScaleFactor:contextScale];
                        [[blockElementView imageView] setContentScaleFactor:contextScale];
                        [[blockElementView displayLabel] setNeedsDisplay];
                    });
                });
                
                [elementView release];

                break;
            }
        }
    }
    [activeDocument release];
    return [cell autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    [activeDocument release];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[activeDocument managedObjectContext]];
    [activeDocument release];
    return [[documentSection hasRows] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[activeDocument managedObjectContext]];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    [activeDocument release];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[activeDocument managedObjectContext]];
    for (RptqDocumentSection *documentSection in enumerator) {
        MTDocumentSectionView *documentSectionView = [[self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]] retain];
        
        NSArray *selectedObjects = [[self selectedObjectIdsInCollectionView:documentSectionView] allObjects];
        [results addObjectsFromArray: selectedObjects];
        [documentSectionView release];
    }
    [enumerator release];
    [activeDocument release];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [self performSelector:action withObject:documentObject];
    }
    [activeDocument release];
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
        __block MTReportDesignerViewController *reportDesigner = self;
        [self dismissViewControllerAnimated:YES completion:^{
            [[reportDesigner view] setNeedsUpdateConstraints];
            [[reportDesigner designerContentView] setNeedsLayout];
            [[reportDesigner designerContentView] setNeedsDisplay];
        }];
    } else if ([sender isKindOfClass:[MTReportViewerController class]]) {
        if ([UIDevice isPad]) {
            [self dismissViewControllerAnimated:YES completion:^{}];
        }
    } else {
        if ([UIDevice isPad]) {
            if ([[self popoverControllerObjectSelector] isPopoverVisible]) {
                [[self popoverControllerObjectSelector] dismissPopoverAnimated:YES];
            } else {
                [[self designerScrollView] setZoomScale:1.0000f animated:NO];
                //[[self designerScrollView] setContentOffset:CGPointZero animated:NO];
                __block MTReportDesignerViewController *reportDesigner = self;
                [self dismissViewControllerAnimated:YES completion:^{
                    [[reportDesigner view] setNeedsUpdateConstraints];
                    [[reportDesigner designerContentView] setNeedsLayout];
                    [[reportDesigner designerContentView] setNeedsDisplay];
                }];
            }
        } else {
            __block MTReportDesignerViewController *reportDesigner = self;
            [self dismissViewControllerAnimated:YES completion:^{
                //[[self designerScrollView] setZoomScale:1.0000f animated:NO];
                //[[self designerScrollView] setContentOffset:CGPointZero animated:NO];
                //[[self view] setNeedsUpdateConstraints];
                //[[self designerContentView] setNeedsLayout];
                [[reportDesigner designerContentView] setNeedsDisplay];
            }];
        }
    }
}

- (void)insertDocumentObjectDataField:(RptqQueryField *)field {
    [[self barButtonItemObjects] setEnabled:YES];
    [self insertDocumentObjectWithDefination:
     @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelDynamic),
       MTDocumentObjectDefinationObject : [field objectID]}];
}

- (void)insertDocumentObjectNewAggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                               inputType:(MTAggregateFunctionInputType)inputType
                                             inputObject:(NSManagedObjectID *)inputObject
                                               groupType:(MTAggregateGroupByType)groupType
                                             groupNumber:(NSNumber *)groupNumber {
    [[self barButtonItemObjects] setEnabled:YES];

    NSDictionary *documentObject = @{MTDocumentObjectDefinationAggregateType : @(functionType),
                                     MTDocumentObjectDefinationAggregatePivotNumber : groupNumber,
                                     MTDocumentObjectDefinationAggregatePivotType : @(groupType),
                                     MTDocumentObjectDefinationAggregateObjectId : inputObject,
                                     MTDocumentObjectDefinationAggregateFunctionInputType : @(inputType)};
    NSDictionary *documentObjectDefination = @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeAggregate),
                                               MTDocumentObjectDefinationObject :  documentObject};

    [self insertDocumentObjectWithDefination: documentObjectDefination];
}


- (void)insertDocumentObjectNewLabel:(NSString *)labelText {
    [[self barButtonItemObjects] setEnabled:YES];
    [self insertDocumentObjectWithDefination:
        @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelStatic),
           MTDocumentObjectDefinationObject : labelText}];

}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {
    [[self barButtonItemObjects] setEnabled:YES];

    MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    
    RptqDocumentSection *section = [document hasDetailSection];
    
    __block MTReportDesignerViewController *reportDesigner = self;
    __block UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];

    [detailSection performBatchUpdates:^{
        //MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
        //NSManagedObjectContext *managedObjectContextBlock = [activeDocument managedObjectContext];
        
        
        RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination
                                                                        toDocument:document];
        [documentObject obtainPermanentID];
        
        //NSError *error = nil;
        //[managedObjectContextBlock save:&error];
        [detailSection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        //[activeDocument release];
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            [detailSection reloadData];
            [UIView animateWithDuration:0.3 animations:^{
                MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
                RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [detailSection objectIdTag]
                                                                                        fromObjectContext: [activeDocument managedObjectContext]];
                [documentSection setHeight:@([detailSection intrinsicContentSize].height)];
                [[reportDesigner designerContentView] setNeedsUpdateConstraints];
                [activeDocument saveContext];
                [activeDocument quickSave];
                [activeDocument release];
            }];
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
    return YES;
}

- (void)removeCollectionViewCellForElementView:(NSManagedObjectID *)elementViewId
                                    completion:(void (^)(BOOL finished))completion {
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
            
            __block MTReportDesignerViewController *reportDesigner = self;

            [svSection performBatchUpdates:^{
                
                RptqDocumentObject *objectToDelete = [hasObjects objectAtIndex:deleteIndex];
                [objectToDelete setInSectionRow:nil];
                [hasObjects removeObjectAtIndex:deleteIndex];
                RptqDocumentSectionRows *row = [[documentSection hasRows] objectAtIndex: deleteSection];
                [row setHasObjects:hasObjects];
                NSError *error = nil;
                [[objectToDelete managedObjectContext] save:&error];
                NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: deleteSection];
                
                [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                
            } completion:^(BOOL finished) {
                if (finished) {
                    [reportDesigner resizeCollectionView:svSection];
                    if (completion != nil) {
                        completion(YES);
                    }
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
    [activeDocument release];
}

/*
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
            NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
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
}*/

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

    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {   // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
            
            [self setScrollersEnabled: NO];
            
            [[gestureRecognizer view] setAlpha:0.8888f];
            [[self designerContentView] bringSubviewToFront: [gestureRecognizer view]];
            
            UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
            CGPoint gestureLocation = [gestureRecognizer locationInView:window];
            [[gestureRecognizer view] setCenter: gestureLocation];
            [self removeCollectionViewCellForElementView:[[gestureRecognizer view] objectIdTag] completion:nil];
            CGPoint newCenter = [[self designerScrollView] convertPoint:gestureLocation fromView:window];
            [[gestureRecognizer view] setCenter: newCenter];
            [[self designerScrollView] addSubview: [gestureRecognizer view]];
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
            CGPoint newCenter = [gestureRecognizer locationInView:window];
            newCenter = [[self designerScrollView] convertPoint:newCenter fromView:window];
            [[gestureRecognizer view] setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStatePossible:      // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
            break;
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
            
            [[gestureRecognizer view] setAlpha:1.0000f];
            
            CGPoint gestureLocation;
            UICollectionView *newSection = nil;
            
            // Try to find the section to place the element view into.
            CGPoint viewLocation = [gestureRecognizer locationInView:[self designerContentView]];

            //Find the section to add the element.
            for (UIView *sectionView in [[self designerContentView] subviews]) {
                if ([sectionView isKindOfClass:[MTDocumentSectionView class]]) {
                    if (CGRectContainsPoint([sectionView frame], viewLocation) && ![sectionView isEqual:self]) {
                        newSection = [[(MTDocumentSectionView *)sectionView retain] autorelease];
                        gestureLocation = [gestureRecognizer locationInView:newSection];
                        gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                        [[gestureRecognizer view] setCenter: gestureLocation];
                        break;
                    }
                }
            }
            
            //Section not found, so add to the first one.
            if (newSection == nil) {
                for (UICollectionView *view in [[self designerContentView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        newSection = [[view retain] autorelease];
                        gestureLocation = CGPointMake([gestureRecognizer view].frame.size.width / 2.0000f, [gestureRecognizer view].frame.size.height / 2.0000f);
                        gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                        [[gestureRecognizer view] setCenter: gestureLocation];
                        break;
                    }
                }
            }
            
            if (newSection != nil) {
                __block MTReportDesignerViewController *reportDesigner = self;
                [newSection performBatchUpdates:^{
                    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
                    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
                    
                    NSManagedObjectID *objectId = [[gestureRecognizer view] objectIdTag];
                    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID: objectId
                                                                                 fromObjectContext: managedObjectContext];
                    
                    CGRect viewFrame = [[gestureRecognizer view] frame];
                    [documentObject setOriginx: @(viewFrame.origin.x)];
                    [documentObject setOriginy: @(viewFrame.origin.y)];
                    
                    [[gestureRecognizer view] removeFromSuperview];
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [newSection objectIdTag]
                                                                                            fromObjectContext: managedObjectContext];
                    
                    NSUInteger sectionZero = 0;
                    RptqDocumentSectionRows *sectionRow = [[documentSection hasRows] objectAtIndex: sectionZero];
                    
                    //CGPoint gestureLocation = [gestureRecognizer locationInView:[self designerContentView]];
                    
                    [documentObject setDropPointX:@(viewFrame.origin.x)];
                    [documentObject setDropPointY:@(viewFrame.origin.y)];
                                        
                    NSUInteger dropIndex = [documentSection nextDropIndexForSection];
                    [documentObject setDropIndex:@(dropIndex)];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[[sectionRow hasObjects] count]
                                                                 inSection:sectionZero];
                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[sectionRow hasObjects]];
                    
                    
                    [hasObjects insertObject:documentObject atIndex:[indexPath item]];
                    
                    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
                    
                    [sectionRow setHasObjects:hasObjects];
                    
                    [managedObjectContext save:nil];
                    
                    [newSection insertItemsAtIndexPaths:indexPaths];
                    
                    [hasObjects release];
                    [activeDocument release];
                    
                } completion:^(BOOL finished) {
                    if (finished) {
                        [reportDesigner resizeCollectionView:newSection];
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
    MAReportDocument *activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: [activeDocument managedObjectContext]];
    [documentSection setHeight:@([collectionView intrinsicContentSize].height)];
    __block MTReportDesignerViewController *reportDesigner = self;
    [UIView animateWithDuration:0.6666f animations:^{
        [collectionView invalidateIntrinsicContentSize];
        [[reportDesigner designerContentView] setNeedsUpdateConstraints];
    }];
    [activeDocument release];
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
