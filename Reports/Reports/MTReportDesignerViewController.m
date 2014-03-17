//
//  ReportDesignerTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerViewController.h"
#include <math.h>
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
#import "UIDevice+Hack.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "NSManagedObject+Extras.h"
#import "DesignerSectionLabel.h"
#import "MTViewControllerBarcode.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTCollectionViewLayoutLiquidAttributes.h"
#import "MTLog.h"
#import "UIView+NSObjectIdTag.h"
#import "CGGeometry+Extras.h"

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

@property (nonatomic, assign) BOOL editAggregate;
@property (nonatomic, assign) BOOL editDynamicField;

@property (nonatomic, retain) NSArray *sectionViewsArray;
@property (nonatomic, retain) NSArray *sectionControlViewsArray;

@property (nonatomic, retain) NSArray *viewDidAppearDesignerScrollViewConstraints;  //These are removed on disapear
@property (nonatomic, retain) NSArray *viewDidAppearDesignerContentViewConstraints; //These are removed on disapear

@property (nonatomic, retain) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *toolbarBottomHeightConstraint;
@property (nonatomic, retain) UINavigationController *navigationControllerSectionLayoutSettings;
@property (nonatomic, retain) MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings;

@property (nonatomic, assign) NSUInteger lastSelectedSectionControlPanel;

@property (nonatomic, retain) UIPopoverController *popoverControllerInformation;
@property (nonatomic, retain) UIPopoverController *popoverControllerObjectSelector;
@property (nonatomic, retain) UIPopoverController *popoverControllerSectionSettings;
@property (nonatomic, retain) UIPopoverController *popoverControllerEditBarcode;
@property (nonatomic, retain) UIPopoverController *popoverControllerEditDataLabel;
@property (nonatomic, retain) UIPopoverController *popoverControllerEditAggregate;

@property (nonatomic, retain) MTElementView *lastElementViewToShowMenu;
@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *layoutConstraintsToRemove;
@property (nonatomic, retain) MTRulerView *rulerView;

@property (nonatomic, retain) NSMutableDictionary *sectionViews;
@property (nonatomic, retain) NSMutableDictionary *sectionControlViews;
@property (nonatomic, retain) NSMutableDictionary *sectionBackgroundViews;

@property (nonatomic, retain) NSMutableDictionary *borderAppliedToView;

@property (nonatomic, retain) IBOutlet UIScrollView *designerScrollView;
@property (nonatomic, retain) IBOutlet UIView *designerContentView;

@property (nonatomic, retain) UIToolbar *toolboxToolbar;
@property (nonatomic, retain) UIView *toolboxBackgroundView; 
@property (nonatomic, retain) UIScrollView *toolboxScrollView;

@property (nonatomic, retain) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, retain) NSArray *layoutConstraintsToolboxHidden;
@property (nonatomic, retain) NSArray *toolbarTopItems;
@property (nonatomic, retain) NSArray *toolbarBottomItems;

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

@property (nonatomic, retain) UIAlertView *alertViewEdit;
@property (nonatomic, retain) NSManagedObjectID *objectIdEditStaticLabel;
@property (nonatomic, retain) NSManagedObjectID *objectIdEditDynamicLabel;

@property (nonatomic, retain) NSManagedObjectID *objectIdEditAggregateFunction;
@property (nonatomic, retain) NSManagedObjectID *objectIdEditBarcode;
@property (nonatomic, retain) NSManagedObjectID *objectIdEditImage;

@property (nonatomic, retain) RptqDocumentObjectBarcode *barcodeToEdit;
@property (nonatomic, retain) RptqDocumentObjectAggregate *aggregateToEdit;
@property (nonatomic, retain) RptqDocumentObjectLabelDataField *dataFieldToEdit;

@end

@implementation MTReportDesignerViewController

#pragma mark - NSObject

- (void)dealloc {
    [_borderAppliedToView release];
    [_dataFieldToEdit release];
    [_aggregateToEdit release];
    [_barcodeToEdit release];
    [_objectIdEditImage release];
    [_objectIdEditBarcode release];
    [_objectIdEditAggregateFunction release];
    [_objectIdEditDynamicLabel release];
    [_objectIdEditStaticLabel release];
    [_alertViewEdit release];
    [_sectionViewsArray release];
    [_sectionControlViewsArray release];
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
    [_toolbarBottomHeightConstraint release];
    [_collectionViewReuseIdentifiers release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];

        [[viewRuler layer] setBorderWidth: 0.5000f];
        [[viewRuler layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
        
        [viewRuler setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setRulerView:viewRuler];
        [viewRuler release];
        MTApplicationInstance *app = [AppDelegate app];
        [[app reportDesigner] setBoundsOnDisappear:CGRectZero];
        [[app reportDesigner] setZoomScaleRestore:-1.0000f];
        [[app reportDesigner] setShownAndHidden:NO];
        
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
    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueEditFieldExit"]) {
        
        MTQueryBuilderChooseFieldViewController *dynamicFieldController = [action sourceViewController];
        RptqQueryField *queryField = [dynamicFieldController queryField];

        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditDynamicLabel];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        [[documentObject isLabelDataField] setReferencesQueryField:queryField];
        [managedObjectContext save:nil];
        
    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueEditFieldCancel"]) {

    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueDocumentObjectEditBarcodeCancel"]) {
        
    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueDocumentObjectEditBarcode"]) {
        
        
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
        
        if ([self aggregateToEdit] && [self editAggregate]) {
            MTDocumentObjectNewAggregateViewController *aggregateViewController = [action sourceViewController];
            [[self aggregateToEdit] updateAggregateFunctionWithFunctionType:[aggregateViewController aggregateFunctionType]
                                                                  inputType:MTAggregateFunctionInputTypeField
                                                                  groupType:[aggregateViewController aggregateGroupByType]
                                                            aggregateObject:[aggregateViewController fieldObject]
                                                                groupNumber:[aggregateViewController groupTypeSectionNumber]];
            
        } else {
            MTDocumentObjectNewAggregateViewController *aggregateViewController = [action sourceViewController];
            [self insertDocumentObjectNewAggregateFunctionWithType:[aggregateViewController aggregateFunctionType]
                                                         inputType:MTAggregateFunctionInputTypeField
                                                       inputObject:[aggregateViewController fieldObjectId]
                                                         groupType:[aggregateViewController aggregateGroupByType]
                                                       groupNumber:@([aggregateViewController groupTypeSectionNumber])];
        }
        

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

        if ([self objectIdEditBarcode]  != nil) {
            
            MTBarcode *barcode = [barcodeViewController barcode];

            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
            NSManagedObjectID *objectId = [self objectIdEditBarcode];
            RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
            RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
            [barcodeObject updateWithBarcode:barcode fieldOne:[barcodeViewController queryField1] fieldTwo:[barcodeViewController queryField2]];
            NSError *error = nil;
            [managedObjectContext save:&error];

            [self setObjectIdEditBarcode:nil];
//            [activeDocument saveContext];
        } else {
            
            NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
            [defination setObject:@(MTDocumentObjectTypeBarcode)        forKey:MTDocumentObjectDefinationType];
            [defination setObject:[barcodeViewController barcode]       forKey:MTDocumentObjectDefinationObject];
            RptqQueryField *queryField1 = [[barcodeViewController queryField1] retain];
            RptqQueryField *queryField2 = [[barcodeViewController queryField2] retain];
            if (queryField1 != nil) {
                NSManagedObjectID *objectId = [queryField1 objectID];
                [defination setObject:objectId forKey:MTDocumentObjectDefinationField1];
            }
            if (queryField2 != nil) {
                NSManagedObjectID *objectId = [queryField2 objectID];
                [defination setObject:objectId forKey:MTDocumentObjectDefinationField2];
            }
            [queryField1 release];
            [queryField2 release];
            [self insertDocumentObjectWithDefination:defination];

        }
        
        [[self barButtonItemObjects] setEnabled:YES];

        
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
        if (navigationToolbarFrame.size.height != [[self toolbarBottomHeightConstraint] constant]) {
            __block MTReportDesignerViewController *reportDesigner = self;
            [UIView animateWithDuration:0.1000f delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
                [[reportDesigner toolbarBottomHeightConstraint] setConstant:navigationToolbarFrame.size.height];
            } completion:NULL];
        }
    }

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
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [self setBorderAppliedToView:d];
    [d release];
    
    [self setEditAggregate:NO];
    
    [[self tabBarController] setDelegate:self];
    
    [self setInsetsSetup:NO];
    [[self designerScrollView] setBouncesZoom:YES];
    [[self designerScrollView] setScrollsToTop:YES];
    [self setToolbarBottomZero:YES];

    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    NSAttributedString *attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadDesigner];
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

    UITapGestureRecognizer *tapGestureSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapToDeselectElementViews:)];
    [tapGestureSingleTap setNumberOfTapsRequired:1];
    [tapGestureSingleTap setNumberOfTouchesRequired:1];
    [tapGestureSingleTap setDelegate: self];
    [tapGestureSingleTap requireGestureRecognizerToFail:tapGestureDoubleTap];
    
    [[self designerScrollView] addGestureRecognizer:tapGestureDoubleTap];
    [[self designerScrollView] addGestureRecognizer:tapGestureSingleTap];

    [tapGestureDoubleTap release];
    [tapGestureSingleTap release];

    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeLeft   multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeRight  multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc3 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self toolbarTop]    attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f];
    NSArray *constraints = @[lc1, lc2, lc3];
    [[self view] addConstraints:constraints];
    
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    
    MTReportDesignerToolBoxViewController *viewControllerToolbox = [[storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"] retain];
    [viewControllerToolbox setDelegate:self];
    [self setViewControllerToolbox:viewControllerToolbox];
    [viewControllerToolbox release];

    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier];
    [viewControllerSectionLayoutSettings setDelegate:self];
    [self setViewControllerSectionLayoutSettings: viewControllerSectionLayoutSettings];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self viewControllerSectionLayoutSettings]];

    [[navigationController navigationBar] setBarTintColor:[UIColor tintColor]];
    [[navigationController navigationBar] setTintColor:[UIColor tintColor2]];
    UIColor *whiteColor = [UIColor whiteColor];
    NSDictionary *textAttribues = @{ NSForegroundColorAttributeName : whiteColor };
    [[navigationController navigationBar] setTitleTextAttributes:textAttribues];
    [self setNavigationControllerSectionLayoutSettings:navigationController];
    [navigationController release];
    
    if ([UIDevice isPad] == NO) {   //Don't need a done button in a popover.
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideToolbox:)];
        [[[self viewControllerSectionLayoutSettings] navigationItem] setRightBarButtonItem:doneButton animated:NO];
        [doneButton release];
    }

    if ([self layoutConstraintsToRemove] != nil) {
        [[self view] removeConstraints:[self layoutConstraintsToRemove]];
    }
    
    if ([UIDevice isPad] == NO) {
        
        NSLayoutConstraint *layoutConstraintToolboxHeight = [NSLayoutConstraint constraintWithItem: [self toolboxView] attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: [self view] attribute: NSLayoutAttributeHeight multiplier: 0.5000f constant: 0.0000f];
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
    [[[AppDelegate app] reportDesigner] setToolboxIsVisible:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MTApplicationInstance *app = [AppDelegate app];
    [[app reportDesigner] setZoomScaleRestore:[[self designerScrollView] zoomScale]];
    [[self designerScrollView] setZoomScale:1.0000f animated:NO];

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [[applicationInstance activeDocument] retain];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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
                        object: reportDocument];
    
    RptqDocument *document = [reportDocument activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    
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
    [viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:rulerConstraints];
    [[self designerScrollView] addConstraints:rulerConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    NSMutableArray *reportSectionKeyTracker = [[NSMutableArray alloc] init];
    
    NSMutableArray *sectionControlViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    NSMutableArray *sectionViewsArray = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        @autoreleasepool {
            
            
            sectionHeights += MTReportDesignerBorderPaddingVertical;
            
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
            
            NSInteger reportSectionId = [[reportSection identifier] integerValue];
            NSString *documentElementReuseIdentifier = [[MTCollectionViewCellElement reuseIdentifier] stringByAppendingFormat:@"%ld", (long)reportSectionId];
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
            NSString *collectionViewKey = [[reportSection sectionKey] retain];
            
            [[collectionView layer] setBorderColor: [[UIColor lightGrayColor] CGColor]];
            [[collectionView layer] setBorderWidth: 1.0000f / [[UIScreen mainScreen] scale]];
            
            [[self sectionBackgroundViews] setValue:backgroundView forKey:collectionViewKey];
            
            CGFloat reportSectionHeight = [[reportSection height] floatValue];
            sectionHeights += reportSectionHeight;
            
            NSString *lastKey = [reportSectionKeyTracker lastObject];
            id constraintItem =  sectionCounter == 0 ? [self rulerView] : /*lastCollectionView;*/ [[self sectionViews] objectForKey:lastKey];
            
            [[self designerContentView] addSubview:collectionView];
            
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
            [collectionViewKey autorelease];
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
    
    [[self designerScrollView] setScrollEnabled:YES];
    [[self designerScrollView] setMaximumZoomScale:4.0000f];
    [[self designerScrollView] setMinimumZoomScale:1.0000f];
    [[self designerScrollView] setDelegate:self];
    [[self designerScrollView] setUserInteractionEnabled:YES];
    [[self designerScrollView] setBackgroundColor:[UIColor lightGrayColor]];
    [[self designerScrollView] setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
    [[self designerScrollView] flashScrollIndicators];
    
    [reportDocument release];
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
    
    MTApplicationInstance *app = [AppDelegate app];
    if ([[app reportDesigner] shownAndHidden] && [[app reportDesigner] zoomScaleRestore] > 1.0001) {
        [[self designerScrollView] setZoomScale:[[app reportDesigner] zoomScaleRestore] animated:NO];
        [self scrollViewDidEndZooming:nil withView:nil atScale:[[self designerScrollView] zoomScale]];
        [[self designerScrollView] scrollRectToVisible:[[app reportDesigner] boundsOnDisappear] animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    MTApplicationInstance *app = [AppDelegate app];
    [[app reportDesigner] setBoundsOnDisappear:[[self designerScrollView] bounds]];
    MAReportDocument *reportDocument = [app activeDocument];
    
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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
                           object: reportDocument];
    
    [reportDocument saveContext];
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
    MTApplicationInstance *app = [AppDelegate app];
    [[app reportDesigner] setShownAndHidden:YES];
}

+ (UIColor *)sectionBackgroundColor:(BOOL)isVisible {
    return isVisible ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.70000f];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    MAReportDocument *reportDocument = [[AppDelegate applicationInstance] activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
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

    } else if ([[segue identifier] isEqualToString:@"MTIdentifierSegueDocumentObjectEditBarcode"]) {
        
        
        MTViewControllerBarcode *barcodeViewController = [[segue destinationViewController] retain];

        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditBarcode];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        RptqDocumentObjectBarcode *barcodeObject = [[documentObject isBarcode] retain];
        [barcodeViewController setBarcodeToEdit: barcodeObject];
        [barcodeObject release];
        [barcodeViewController release];

    } else if ([[segue identifier] isEqualToString:@"MTIdentifierSegueDocumentObjectEditAggregate"]) {
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController = [[segue destinationViewController] retain];
        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditAggregateFunction];
        RptqDocumentObject *documentObject = [(RptqDocumentObject *)[managedObjectContext objectWithID:objectId] retain];
        RptqDocumentObjectAggregate *aggregateObject =  [[documentObject isAggregate] retain];
        [aggregateViewController setAggregateObjectToEdit:aggregateObject];
        [aggregateObject release];
        [documentObject release];
        [aggregateViewController release];
        
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    UIView *result = [self designerContentView];
    return result;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    scale *= [[[[self designerScrollView] window] screen] scale];

    [[self rulerView] setContentScaleFactor:scale];
    [[self rulerView] setNeedsDisplay];

    NSSet *elementViews = [[self elementViews] retain];
    for (MTElementView *elementView in elementViews) {
        [elementView setContentScaleFactor:scale];
    //    if ([[[elementView displayLabel] text] length] > 0) {
    //        [[elementView displayLabel] setContentScaleFactor:scale];
    //    } else if ([elementView imageView] != nil) {
    //        [[elementView imageView] setContentScaleFactor:scale];
    //    }
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
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    UIDocumentState state = [reportDocument documentState];
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
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
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
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
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
    [documentSectionView release];
    [reportDocument saveContext];
}

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
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
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[documentSectionView objectIdTag] fromObjectContext:managedObjectContext];
    [documentSection setHeight:@([documentSectionView bounds].size.height)];
    

    [self relayoutSectionView:documentSectionView];
    
    [managedObjectContext save:nil];
}

- (void)relayoutSectionView:(MTDocumentSectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [[objectId URIRepresentation] retain];
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContect = [reportDocument managedObjectContext];
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

- (void)managedObjectContextDidSave:(NSNotification *)notification {

    NSArray *managedObjectsUpdated = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];
    
    for (NSManagedObject *managedObject in managedObjectsUpdated) {
        
        MTElementView *elementView = [self elementViewForManagedObject:managedObject];
        [self updateElementView:elementView forManagedObjectContext:[managedObject managedObjectContext]];
        
    }
}


- (UIView *)viewForObjectID:(NSManagedObjectID *)objectID {
    NSUInteger hash = [objectID hash];
    UIView *viewToEdit = [[self designerContentView] viewWithTag: hash];
    return [[viewToEdit retain] autorelease];
}
- (MTElementView *)elementViewForManagedObjectID:(NSManagedObjectID *)managedObjectID inObjectContext:(NSManagedObjectContext *)managedObjectContext{
    MTElementView *elementView = nil;
    NSManagedObject *managedObject = [managedObjectContext objectWithID:managedObjectID];
    elementView = [self elementViewForManagedObject:managedObject];
    return [[elementView retain] autorelease];
}

- (MTElementView *)elementViewForManagedObject:(NSManagedObject *)managedObject {
    MTElementView *elementView = nil;
    elementView = (MTElementView *)[self viewForObjectID:[managedObject objectID]];
    if (!elementView) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObject:managedObject];
        if (documentObject) {
            NSUInteger hash = [documentObject hash];
            elementView = (MTElementView *)[[self designerContentView] viewWithTag:hash];
            if (!elementView) {
                elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID] inObjectContext:[documentObject managedObjectContext]];
                [elementView setTag: hash];
                [elementView setDelegate:self];
                [elementView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                [self updateElementView:elementView forManagedObjectContext:[documentObject managedObjectContext]];
            } else {
                [elementView retain];
            }
            [elementView autorelease];
        }
    } else {
        [[elementView retain] autorelease];
    }
    return elementView;
}

- (RptqDocumentObject *)documentObjectForElementView:(MTElementView *)elementView inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectID *objectID = [elementView objectIdTag];
    RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectID];
    return [[documentObject retain] autorelease];
}

- (void)updateElementView:(MTElementView *)elementView forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (elementView) {

        // TODO: Only update specific properties when they change.
        
        RptqDocumentObject *documentObject = [self documentObjectForElementView:elementView inManagedObjectContext:managedObjectContext];
        
        if (documentObject != nil) {
            
            CGRect marginViewFrame = [documentObject boundsContentView];
            
            [elementView setFrame: marginViewFrame];
            
            NSString *fontName = [documentObject fontname];
            CGFloat pointSize = [[documentObject fontsize] floatValue];
            
            UIFont *displayFont = nil;
            if ([fontName length] == 0) {
                displayFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            } else {
                MTFont *stylizedDisplayFont = [[MTFont alloc] initWithFamilyName:fontName andPointSize:pointSize];
                if ([[documentObject bold] boolValue] && [[documentObject italic] boolValue]) {
                    displayFont = [stylizedDisplayFont boldItalicFont];
                } else if ([[documentObject bold] boolValue]) {
                    displayFont = [stylizedDisplayFont boldFont];
                } else if ([[documentObject italic] boolValue]) {
                    displayFont = [stylizedDisplayFont italicFont];
                } else {
                    displayFont = [stylizedDisplayFont font];
                }
                [stylizedDisplayFont release];
            }
            
            if (displayFont == nil) {
                displayFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            }
            [elementView setDisplayFont:displayFont];
            
            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            
            MTHorizontalAlignment horizontalAlignment = [[documentObject horizontalAlignment] integerValue];
            NSTextAlignment textAlignment;
            switch (horizontalAlignment) {
                case MTHorizontalAlignmentCenter:
                    textAlignment = NSTextAlignmentCenter;
                    break;
                case MTHorizontalAlignmentLeft:
                    textAlignment = NSTextAlignmentLeft;
                    break;
                case MTHorizontalAlignmentRight:
                    textAlignment = NSTextAlignmentRight;
                    break;
                case MTHorizontalAlignmentJustified:
                    textAlignment = NSTextAlignmentJustified;
                    break;
                default:
                    textAlignment = NSTextAlignmentLeft;
                    break;
            }
            [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
            [paragraphStyle setAlignment:textAlignment];
            [elementView setParagraphStyle:paragraphStyle];
            [paragraphStyle release];
            
            NSString *string = [[documentObject designerRepresentationText] retain];
            [elementView setDisplayText:string];
            [string release];
            
            [elementView setDisplayImage:nil];
            [elementView setDisplayBarcode:nil];
            [elementView setDisplayImage:nil];
            
            if ([documentObject getType] == MTDocumentObjectTypeImage) {
                
                [elementView setDisplayImage:[[documentObject isImage] image]];
                
            } else if ([documentObject getType] == MTDocumentObjectTypeBarcode) {
                
                MTBarcode *displayBarcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:[documentObject isBarcode]];
                [elementView setDisplayBarcode:displayBarcode];
                
            }
            
            NSNumber *underlineStyle = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
            [elementView setUnderlineStyle:underlineStyle];
            
            NSNumber *strikeThroughStyle = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
            [elementView setStrikeThroughStyle:strikeThroughStyle];
            
            NSDictionary *attributes = @{
                                         NSParagraphStyleAttributeName : [elementView paragraphStyle],
                                         NSFontAttributeName : [elementView displayFont],
                                         NSStrikethroughStyleAttributeName : [elementView strikeThroughStyle],
                                         NSUnderlineStyleAttributeName : [elementView underlineStyle]
                                         };
            NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:[elementView displayText]
                                                                                    attributes:attributes];
            [elementView setDisplayStringAttributed:attributtedString];
            [attributtedString release];
            
            CGSize sizeContentView = [documentObject sizeContentView];
            CGRect boundsContentView = [documentObject boundsContentView]; //x1
            NSStringDrawingOptions drawingOptions = (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading);
            [elementView setDrawingOptions:drawingOptions];
            CGRect boundingRect = [[elementView displayStringAttributed] boundingRectWithSize:sizeContentView options:drawingOptions context:nil]; //x35
            CGRect drawingBounds = CGRectIntersection(boundingRect, boundsContentView);
            
            
            MTVerticalAlignment verticalAlignment = [[documentObject verticalAlignment] integerValue];
            
            switch (verticalAlignment) {
                case MTVerticalAlignmentCenter: {
                    CGFloat offsetY = (sizeContentView.height - drawingBounds.size.height) / 2.0000f;
                    CGAffineTransform transform = CGAffineTransformMakeTranslation(CGSizeZero.width, offsetY);
                    drawingBounds = CGRectApplyAffineTransform(drawingBounds, transform);
                    break;
                }
                case MTVerticalAlignmentBottom: {
                    CGFloat offsetY = sizeContentView.height - drawingBounds.size.height;
                    CGAffineTransform transform = CGAffineTransformMakeTranslation(CGSizeZero.width, offsetY);
                    drawingBounds = CGRectApplyAffineTransform(drawingBounds, transform);
                    break;
                }
                case MTVerticalAlignmentTop:
                default:
                    break;
            }
            
            CGFloat contentViewX = documentObject.marginLeft.floatValue + documentObject.borderWidthLeft.floatValue + documentObject.paddingLeft.floatValue;
            CGFloat contentViewY = documentObject.marginTop.floatValue + documentObject.borderHeightTop.floatValue + documentObject.paddingTop.floatValue;
            CGAffineTransform transformPaddingBorderMargin = CGAffineTransformMakeTranslation(contentViewX, contentViewY);
            drawingBounds = CGRectApplyAffineTransform(drawingBounds, transformPaddingBorderMargin);
            [elementView setDrawingRect:drawingBounds];
            
            [elementView setNeedsLayout];
            [elementView setNeedsDisplay];
        }
    }
}

#pragma mark - Menu Notifications

- (void)didHideMenuNotification:(NSNotification *)notification {
    [[self elementViews] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self didDeselectElementView:obj animated:YES];
    }];
}

- (void)didShowMenuNotification:(NSNotification *)notification { }

#pragma mark - Methods

- (CGFloat)toolbarBottomHeight {
    return self.toolbarBottomZero ? CGSizeZero.height :
    self.navigationController.toolbar.frame.size.height;
}

- (CGRect)rectForSelectedElements {
    return [MTReportDesignerViewController popoverRectForSelectedElements:[self selectedElementViews]
                                                                   inView:[self designerContentView]];
}

- (CGSize)designerContentViewSize {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    CGSize designerContentViewSize = CGSizeMake([[self view] bounds].size.width, CGSizeZero.height);
    designerContentViewSize.height += MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
        designerContentViewSize.height += [[reportSection height] floatValue];
    }
    designerContentViewSize.height += MTReportDesignerBorderPaddingVertical;
    [sectionEnumerator release];
    return designerContentViewSize;
}

+ (CGRect)popoverRectForSelectedElements:(NSSet *)selectedElementViews inView:(UIView *)contentView {
    CGRect result;
    if ([selectedElementViews count] == 0) {
        result = CGRectZero;
    } else if ([selectedElementViews count] == 1) {
        UIView *elementView = [selectedElementViews anyObject];
        result = [elementView convertRect:[elementView frame] toView:contentView];
    } else {
        CGFloat minx = CGPointZero.x, miny = CGPointZero.y, maxx = CGPointZero.x, maxy = CGPointZero.y;
        NSUInteger counter = 0;
        for (UIView *elementView in selectedElementViews) {
            CGRect frame = [elementView convertRect:[elementView frame] toView:contentView];
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
        result = CGRectMake(minx, miny, maxx - minx, maxy - miny);
    }
    return result;
}

#pragma mark - MTElementViewDelegate

- (void)sizeChanged:(id)sender {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];

    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[reportSection identifier] integerValue]];
        if ([(UIView *)sender isDescendantOfView: documentSectionView]) {
            [[documentSectionView collectionViewLayout] invalidateLayout];
        }
    }
    [sectionEnumerator release];

    [self updateElementView:sender forManagedObjectContext:[document managedObjectContext]];
}

- (void)didSelectElementView:(id)sender {
    [self removeBorderFromSectionViews];
    
    NSUInteger deselectedSectionViewCounter = 0;
    //Remove border from the section views
    for (UIView *view in [[self sectionControlViews] objectEnumerator]) {
        deselectedSectionViewCounter += [self  removeBorderFromView:view] ? 1 : 0;
    }
    
    if (deselectedSectionViewCounter == 0) {

        if ([UIDevice isPad] == NO) {
            if (![self dismissAllPopovers]) {
                if (sender != nil) {
                    if ([sender isEqual:[self lastElementViewToShowMenu]]) {
                        
                    } else {
                        [self showToolbox:MTToolboxTypeElement];
                    }
                } else {
                    [self showToolbox:MTToolboxTypeElement];
                }
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
                
                CGRect popoverRect = [MTReportDesignerViewController popoverRectForSelectedElements:[self selectedElementViews]
                                                                                          inView:[self designerContentView]];
                    
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
    
    
    // FIXME: Add ability to edit image fields.  84848422
    
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

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController isEqual:[self navigationController]] == NO) {
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

- (void)singleTapToDeselectElementViews:(UITapGestureRecognizer *)sender {
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self deselectAllElementsAnimated:YES];
    [self hideToolbox];
}



- (void)toggleSectionControlPanel:(UITapGestureRecognizer *)sender {
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        
        if ([[self selectedElementViews] count] >= 1) {
            [self deselectAllElementsAnimated:YES];
            [self hideToolbox];
        } else {
            
            if ([(DesignerSectionLabel *)[sender view] selected]) {
                
                
                DesignerSectionLabel *sectionLabel = (DesignerSectionLabel *)[sender view];
                if ([sectionLabel selected]) {
                    [sectionLabel normalView];
                }
                
                [self hideToolbox];
                
            } else {
                
                [self deselectAllElementsAnimated:YES];
                
                [self setLastSelectedSectionControlPanel:[[sender view] tag]];
                
                MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                MAReportDocument *reportDocument = [applicationInstance activeDocument];
                RptqDocument *document = [reportDocument activeDocument];
                RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                RptqQuery *query = [[database hasQueries] anyObject];
                RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                    forQuery: query];
                
                
                if ([[sender view] isKindOfClass:[DesignerSectionLabel class]]) {
                    DesignerSectionLabel *sectionLabel = (DesignerSectionLabel *)[sender view];
                    [sectionLabel dimView];
                    UIColor *borderColor = [UIColor tintColor];
                    UIView *superView = [self getSectionViewForDocumentSection: section];
                    [[superView layer] setBorderColor: [borderColor CGColor]];
                    [[superView layer] setBorderWidth:1.0000f];
                }

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
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];

    //Remove border from element views
    [[self selectedElementViews] enumerateObjectsUsingBlock:^(MTElementView *elementView, BOOL *stop) {
        [self didDeselectElementView:elementView animated:animated];
    }];
    
    [self removeBorderFromSectionViews];
}

- (void)removeBorderFromSectionViews {
    //Remove border from the section views
    [[self sectionControlViews] enumerateKeysAndObjectsUsingBlock:^(id key, DesignerSectionLabel *view, BOOL *stop) {
        [view normalView];
    }];

    //Remove border from the section views
    [[self sectionViews] enumerateKeysAndObjectsUsingBlock:^(id key, UICollectionView *view, BOOL *stop) {
        [[view layer] setBorderWidth:0.0000f];
    }];
}

- (void)applyBorderToView:(UIView *)view {
    NSNumber *key = @([view tag]);
    [[self borderAppliedToView] setObject:@YES forKey:key];
    UIColor *tintColor = [UIColor tintColor];
    [[view layer] setBorderColor:[tintColor CGColor]];
    [[view layer] setBorderWidth:1.0000f / [[UIScreen mainScreen] scale]];
}

- (BOOL)removeBorderFromView:(UIView *)view {
    BOOL result;
    if ([self isBorderAppliedToView:view]) {
        NSNumber *key = @([view tag]);
        [[self borderAppliedToView] setObject:@NO forKey:key];
        result = YES;
    
        [[view layer] setBorderColor:[[UIColor blackColor] CGColor]];
        [[view layer] setBorderWidth:0.0000f];
    } else {
        result = NO;
    }
    return result;
}

- (BOOL)isBorderAppliedToView:(UIView *)view {
    NSNumber *key = @([view tag]);
    BOOL borderApplied = [[[self borderAppliedToView] objectForKey:key] boolValue];
    return borderApplied;
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
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    NSMutableSet *results = [[NSMutableSet alloc] init];
    for (RptqDocumentSection *documentSection in sectionEnumerator) {
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
    [sectionEnumerator release];
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
        
        if (quickHashWorks == NO) {     // FIXME: This case should be unneeded now.
            
            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            RptqDocument *document = [reportDocument activeDocument];
            SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
            
            for (RptqDocumentSection *documentSection in sectionEnumerator) {
                MTDocumentSectionView *documentSectionView = [[self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]] retain];
                
                for (NSUInteger section = 0; section < [documentSectionView numberOfSections]; section++) {
                    for (NSUInteger item = 0; item < [documentSectionView numberOfItemsInSection:section]; item++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                        MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:documentSectionView];
                        if ([[self selectedObjectIds] containsObject: [elementView objectIdTag]]) {
                            [results addObject:elementView];
                        }
                    }
                }
                [documentSectionView release];
            }
            [sectionEnumerator release];
        }
    }
    
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
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
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
        
        MTReportDesigner *reportDesigner = [[AppDelegate app] reportDesigner];
        if ([reportDesigner toolboxIsVisible] == NO) {
            [reportDesigner setToolboxIsVisible:YES];
            [[self informationButton] setEnabled: NO];
            
            [[self toolbarBottom] setItems:nil animated:YES];
            [[self toolbarTop] setItems:nil animated:YES];
                        
            [[self view] layoutIfNeeded];
            
            __block MTReportDesignerViewController *reportDesigner = self;

            [[[AppDelegate app] reportDesigner] setContentOffsetOnShowToolbox:reportDesigner.designerScrollView.contentOffset];
            
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
                    if (tooboxType == MTToolboxTypeSection) {
                        [self adjustContentOffsetForLastSelectedSectionControlPanel];
                    } else if (tooboxType == MTToolboxTypeElement) {
                        [self adjustContentOffsetForSelectedElements];
                    }
                }
            }];
        }
    }
    [viewController release];
}

- (CGFloat)heightTopBars {
    CGFloat height = self.navigationController.navigationBar.bounds.size.height;
    return UIDeviceOrientationIsLandscape([self interfaceOrientation]) ? (height += [UIApplication sharedApplication].statusBarFrame.size.width) : (height += [UIApplication sharedApplication].statusBarFrame.size.height);
}

- (CGFloat)heightScrollViewAdjustment {
    return [self heightTopBars] + (MTReportDesignerBorderPadding / 2.0000f);
}

- (void)adjustContentOffsetForSelectedElements {
    CGRect rectToShow = [self rectForSelectedElements];
    CGRect visableRect = [MTReportDesignerViewController visableRect:self.designerScrollView];
    
    //Scroll to top
    CGRect db = self.designerScrollView.bounds;
    CGRect b = [self.designerScrollView convertRect:db toView:self.view];
    CGFloat adjustment = [self heightScrollViewAdjustment];
    b.size.height -= adjustment;
    rectToShow.origin.y -= adjustment;
    visableRect.origin.y -= adjustment;
    if (CGRectIntersectsRect(visableRect, rectToShow) == NO) {
        CGFloat yOffset = ((rectToShow.origin.y + adjustment) * self.designerScrollView.zoomScale) - adjustment;
        CGPoint contentOffset = CGPointMake(CGPointZero.x, yOffset);
        [[self designerScrollView] setContentOffset:contentOffset animated:YES];
    }
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanel {
    RptqQuery *query = [AppDelegate activeRptqQuery];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                forQuery: query];
    UIView *selectedSectionView = [self getSectionViewForDocumentSection:documentSection];
    UIView *superv = [selectedSectionView superview];
    CGRect rectToShow = superv.frame;
    rectToShow = [selectedSectionView convertRect:superv.frame toView:self.designerScrollView];
    CGRect visableRect = [MTReportDesignerViewController visableRect:self.designerScrollView];
    
    //Scroll to top
    CGRect db = self.designerScrollView.bounds;
    CGRect b = [self.designerScrollView convertRect:db toView:self.view];
    CGFloat adjustment = [self heightScrollViewAdjustment];
    b.size.height -= adjustment;
    rectToShow.origin.y -= adjustment;
    visableRect.origin.y -= adjustment;
    if (CGRectIntersectsRect(visableRect, rectToShow) == NO) {
    
        CGFloat yOffset = rectToShow.origin.y;
        CGPoint contentOffset = CGPointMake(CGPointZero.x, yOffset);
        [[self designerScrollView] setContentOffset:contentOffset animated:YES];
    }

}

+ (CGRect)visableRect:(UIScrollView *)scrollView {
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    return [MTReportDesignerViewController adjustRect:visibleRect forZoomScale:scrollView.zoomScale];
}

+ (CGRect)adjustRect:(CGRect)rect forZoomScale:(CGFloat)zoomScale {
    CGFloat scale = 1.0000f / zoomScale;
    if ( isless(scale, 1.0000f) ) {
        rect.origin.x *= scale;
        rect.origin.y *= scale;
        rect.size.width *= scale;
        rect.size.height *= scale;
    }
    return rect;
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
        MTReportDesigner *reportDesigner = [[AppDelegate app] reportDesigner];
        if ([reportDesigner toolboxIsVisible]) {
            [reportDesigner setToolboxIsVisible:NO];
            
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
                    
                    CGPoint contentOffset = [[[AppDelegate app] reportDesigner] contentOffsetOnShowToolbox];
                    [[reportDesigner designerScrollView] setContentOffset:contentOffset animated:YES];

                }
            }];
            [self deselectAllElementsAnimated:YES];
        }
    }
}

- (void)resizeCollectionView:(UICollectionView *)collectionView forSectionWithId:(NSManagedObjectID *)sectionObjectId {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForObjectID:sectionObjectId fromObjectContext:managedObjectContext];
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

- (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = [cell objectIdTag];
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [[reportDocument activeDocument] managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
    [[documentObject type] integerValue];
    
    MTDocumentObjectType objectType = [[documentObject type] integerValue];
    return objectType;
}

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = [cell objectIdTag];
    [self removeCollectionViewCellForElementView:objectId completion:^(BOOL finished) {
        if (finished) {
            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            [RptqDocumentObject removeDocumentObject:documentObject];
        }
    }];
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *elementViewId = [cell objectIdTag];
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:elementViewId fromObjectContext:managedObjectContext];
    
    RptqDocumentSection *section = [[documentObject inSectionRow] inSection];
    UICollectionView *svSection = [self getSectionViewForDocumentSection:section];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
    
    BOOL found = NO;
    //NSUInteger deleteSection = 0;
    
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

            
            RptqDocumentObject *objectToEdit = [hasObjects objectAtIndex:deleteIndex];
            
            switch ([[objectToEdit type] integerValue]) {

                case MTDocumentObjectTypeAggregate: {

                    [self setAggregateToEdit: [objectToEdit isAggregate]];
                    [self setEditAggregate: YES];
                    
                    if ([UIDevice isPad]) {
                        
                        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
                        NSManagedObjectID *objectId = [objectToEdit objectID];
                        UIView *viewToEdit = [self viewForObjectID:objectId];

                        if (viewToEdit != nil) {
                            
                            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
                            
                            UINavigationController *navigationController = [[storyboard instantiateViewControllerWithIdentifier:MTDocumentObjectNewAggregateNavigationControllerIdentifier] retain];
                            MTDocumentObjectNewAggregateViewController *aggregateViewController = [[[navigationController viewControllers] firstObject] retain];
                            [aggregateViewController setDelegate:self];
                            
                            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                            MAReportDocument *reportDocument = [applicationInstance activeDocument];

                            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                            RptqDocumentObject *documentObject = [(RptqDocumentObject *)[managedObjectContext objectWithID:objectId] retain];
                            RptqDocumentObjectAggregate *aggregateObject =  [[documentObject isAggregate] retain];
                            [aggregateViewController setAggregateObjectToEdit:aggregateObject];
                            [aggregateObject release];
                            [documentObject release];
                            
                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            
                            [self setPopoverControllerEditBarcode: popoverController];
                            
                            [popoverController release];
                            
                            [aggregateViewController release];
                            [navigationController release];
                            
                            
                        } else {

                            [self setObjectIdEditAggregateFunction:[objectToEdit objectID]];
                            [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditAggregate sender:self];

                        }
                        
                    } else {

                        [self setObjectIdEditAggregateFunction:[objectToEdit objectID]];
                        [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditAggregate sender:self];
                        
                    }
                    
                    
                    break;
                    
                }
                    
                case MTDocumentObjectTypeBarcode: {
                  
                    if ([UIDevice isPad]) {
                        
                        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
                        NSManagedObjectID *objectId = [objectToEdit objectID];
                        UIView *viewToEdit = [self viewForObjectID:objectId];

                        if (viewToEdit != nil) {
                            
                            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
                            MTViewControllerBarcode *barcodeViewController = [[storyboard instantiateViewControllerWithIdentifier: MTDocumentObjectNewBarcodeViewControllerIdentifier] retain];
                            [barcodeViewController setDelegate:self];
                            
                            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                            MAReportDocument *reportDocument = [applicationInstance activeDocument];
                            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                            RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
                            RptqDocumentObjectBarcode *barcodeObject = [[documentObject isBarcode] retain];
                            [self setBarcodeToEdit: barcodeObject];
                            [barcodeViewController setBarcodeToEdit: barcodeObject];
                            
                            [barcodeObject release];

                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:barcodeViewController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            
                            [self setPopoverControllerEditBarcode: popoverController];
                            
                            [popoverController release];
                            [barcodeViewController release];

                        } else {
                            [self setObjectIdEditBarcode:[objectToEdit objectID]];
                            [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditBarcode sender:self];
                        }
                        
                        
                        
                    } else {
                        [self setObjectIdEditBarcode:[objectToEdit objectID]];
                        [self performSegueWithIdentifier:MTIdentifierSegueDocumentObjectEditBarcode sender:self];
                    }
                    
                    break;
                }
                case MTDocumentObjectTypeImage:
                    
                    [self setObjectIdEditImage:[objectToEdit objectID]];

                    break;
                case MTDocumentObjectTypeLabelDynamic: {

                    [self setDataFieldToEdit:[objectToEdit isLabelDataField]];
                    [self setEditDynamicField:YES];
                    
                    if ([UIDevice isPad]) {
                        
                        CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
                        NSManagedObjectID *objectId = [objectToEdit objectID];
                        UIView *viewToEdit = [self viewForObjectID:objectId];
                        
                        if (viewToEdit != nil) {
                            
                            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
                            MTQueryBuilderChooseFieldViewController *chooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier: @"UITableViewControllerChooseFieldDataObject"] retain];
                            
                            [chooseFieldViewController setDelegate:self];
                            
                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:chooseFieldViewController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            
                            [self setPopoverControllerEditDataLabel: popoverController];
                            
                            [popoverController release];

                            [chooseFieldViewController release];

                            
                        } else {
                            [self setObjectIdEditDynamicLabel:[objectToEdit objectID]];
                            [self performSegueWithIdentifier:@"MTIdentifierSegueEditField" sender:self];
                        }
                    } else {
                        [self setObjectIdEditDynamicLabel:[objectToEdit objectID]];
                        [self performSegueWithIdentifier:@"MTIdentifierSegueEditField" sender:self];

                    }
                    
                    break;
                }
                case MTDocumentObjectTypeLabelStatic: {
                    
                    [self setObjectIdEditStaticLabel:[objectToEdit objectID]];
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Edit Label", @"Edit Label")
                                                                        message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
                                                                       delegate: self
                                                              cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel")
                                                              otherButtonTitles: NSLocalizedString(@"Change", @"Change"), nil
                                              ];
                    [alertView setAlertViewStyle: UIAlertViewStylePlainTextInput];
                    [alertView setDelegate:self];
                    UITextField *textField = [[alertView textFieldAtIndex:0] retain];
                    [textField setClearButtonMode:UITextFieldViewModeAlways];
                    [textField setDelegate:self];
                    NSString *textFieldText = [[[objectToEdit isLabel] text] retain];
                    [textField setText:textFieldText];
                    [alertView setTag:MTDocumentObjectTypeLabelStatic];
                    [self setAlertViewEdit:alertView];
                    [[self alertViewEdit] show];
                    [alertView release];
                    [textField release];
                    [textFieldText release];
                    
                    break;
                }
                case MTDocumentObjectTypeWhtiespace:
                    
                    
                    break;
                default:
                    break;
            }
            
        }
        
        [hasObjects release];
    }
    
    
}

#pragma mark -
#pragma mark - MTViewControllerBarcodeDelegate

- (void)didUpdateBarcode:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo {

    if ([self barcodeToEdit] != nil) {
        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        RptqDocumentObjectBarcode *barcodeObject = [self barcodeToEdit];
        [barcodeObject updateWithBarcode:barcode fieldOne:fieldOne fieldTwo:fieldTwo];
        NSError *error = nil;
        [managedObjectContext save:&error];
        if (error != nil) {
            MTLog(@"Error: %@", error);
        }
    }
    
}

#pragma mark -
#pragma mark - MTViewControllerAggregateDelegate

- (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                inputType:(MTAggregateFunctionInputType)inputType
                              inputObject:(NSManagedObject *)inputObject
                                groupType:(MTAggregateGroupByType)groupType
                              groupNumber:(NSNumber *)groupNumber {

    RptqDocumentObjectAggregate *aggregateToEdit = [[self aggregateToEdit] retain];
    [aggregateToEdit updateAggregateFunctionWithFunctionType:functionType
                                                          inputType:MTAggregateFunctionInputTypeField
                                                          groupType:groupType
                                                    aggregateObject:(RptqQueryField *)inputObject
                                                        groupNumber:labs((long)[groupNumber integerValue])];
    [aggregateToEdit release];
}

#pragma mark -
#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {
    
    NSManagedObjectContext *managedObjectContext = [field managedObjectContext];
    [[self dataFieldToEdit] setReferencesQueryField:field];
/*
    if ([self dataFieldToEdit] && [self editDynamicField]) {
        [[self dataFieldToEdit] setReferencesQueryField:field];
    } else {

        NSManagedObjectID *objectId = [self objectIdEditDynamicLabel];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        [[documentObject isLabelDataField] setReferencesQueryField:field];

    }
    */
    [managedObjectContext save:nil];
}

#pragma mark -
#pragma mark - UIAlertView delegate protocol

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
        
        MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditStaticLabel];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];

        UITextField *textField = [[alertView textFieldAtIndex:0] retain];
        [[documentObject isLabel] setText:[textField text]];
        [managedObjectContext save:nil];
        [textField release];
    }
}

#pragma mark -
#pragma mark Text Field Delegate Protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self alertView:[self alertViewEdit] clickedButtonAtIndex:1];
    [[self alertViewEdit] dismissWithClickedButtonIndex:1 animated:YES];
    return YES;
}


#pragma mark -
#pragma mark Collection View Layout Delegate

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView { }

- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    return [[documentSection height] floatValue];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = [documentObject size];
    } else {
        result = CGSizeZero;
    }
    return result;
}

- (MTCollectionViewLayoutLiquidAttributes *)collectionView: (UICollectionView *)collectionView
                                                    layout: (UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath {

    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    MTCollectionViewLayoutLiquidAttributes *result = [[MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath] retain];
    
    if ([objects count] > [indexPath item]) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath item]];
        [result setDropPoint: CGPointMake([[documentObject dropPointX] floatValue], [[documentObject dropPointY] floatValue])];
        CGSize documentObjectSize = documentObject.size;
        [result setFrame:CGRectMake(result.dropPoint.x, result.dropPoint.y, documentObjectSize.width, documentObjectSize.height)];

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
    return [result autorelease];
}

- (NSUInteger)collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath {

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
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
}


#pragma mark Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat contextScale = [[self designerScrollView] zoomScale] * [[[[self designerScrollView] window] screen] scale];

    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    NSString *resuseId = [[self collectionViewReuseIdentifiers] objectForKey:[documentSection identifier]];
    
    MTCollectionViewCellElement *cell = [[collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath] retain];
    [cell setDelegate:self];
    if ([objects count] > [indexPath row]) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:[indexPath row]];
    
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
                if ([[documentObject objectID] isTemporaryID]) {
// FIXME: What's happening here.
                }
                
                
                [cell setBackgroundColor:[UIColor clearColor]];
                [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                
                
                
                MTElementView *elementView = [[self elementViewForManagedObject:documentObject] retain];
                
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
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];
                
                __block UICollectionViewCell *blockCell = cell;
                __block MTElementView *blockElementView = elementView;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [blockCell setContentScaleFactor:contextScale];
                        [[blockCell contentView] setContentScaleFactor:contextScale];
                        [blockElementView setContentScaleFactor:contextScale];
                        //[[blockElementView displayLabel] setContentScaleFactor:contextScale];
                        //[[blockElementView imageView] setContentScaleFactor:contextScale];
                        //[[blockElementView displayLabel] setNeedsDisplay];
                    });
                });
                
                [elementView release];

                break;
            }
        }
    }
    return [cell autorelease];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[reportDocument managedObjectContext]];
    return [[documentSection hasRows] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[reportDocument managedObjectContext]];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    return [objects count];
}

#pragma mark - Collection View Delegate

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

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:)) {
        result = YES;
    }
    return result;
}

- (void)edit:(id)sender {
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSInteger row = [indexPath row];
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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

    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    
    RptqDocumentSection *section = [document hasDetailSection];
    
    __block MTReportDesignerViewController *reportDesigner = self;
    __block UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];

    [detailSection performBatchUpdates:^{

        RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination
                                                                        toDocument:document];
        [documentObject obtainPermanentID];
        
        [detailSection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            [detailSection reloadData];

            MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
            MAReportDocument *activeDocument = [[applicationInstance activeDocument] retain];
            
            RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [detailSection objectIdTag]
                                                                                    fromObjectContext: [activeDocument managedObjectContext]];
            
            [documentSection setHeight:@([detailSection intrinsicContentSize].height)];

            [UIView animateWithDuration:0.30000f animations:^{
                [[reportDesigner designerContentView] setNeedsUpdateConstraints];
            }];
            [activeDocument saveContext];
            [activeDocument quickSave];
            [activeDocument release];
            
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
    
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
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
            
            [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];

            [self setScrollersEnabled: NO];
            
            [[gestureRecognizer view] setAlpha:0.8888f];
            [[self designerContentView] bringSubviewToFront: [gestureRecognizer view]];
            
            UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
            CGPoint gestureLocation = [gestureRecognizer locationInView:window];
            
            CGPoint newCenter = [[self designerScrollView] convertPoint:gestureLocation fromView:window];
            
            [[self designerScrollView] addSubview: [gestureRecognizer view]];
            [self removeCollectionViewCellForElementView:[[gestureRecognizer view] objectIdTag] completion:nil];
            [[gestureRecognizer view] setCenter: newCenter];

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

            UICollectionView *newSection = [[self sectionViewFor:gestureRecognizer] retain];
            
            if (newSection != nil) {
                __block MTReportDesignerViewController *reportDesigner = self;
                [newSection performBatchUpdates:^{
                    
                    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
                    MAReportDocument *reportDocument = [applicationInstance activeDocument];

                    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                    
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
                    
                } completion:^(BOOL finished) {
                    if (finished) {
                        [reportDesigner resizeCollectionView:newSection];
                    }
                }];
                
            }
            [newSection release];
            [self setScrollersEnabled:YES];
            [[gestureRecognizer view] setNeedsDisplay];
            
            break;
        }
        default:
            break;
    }
}

- (MTDocumentSectionView *)sectionViewFor:(UIPanGestureRecognizer *)panGesture {
    MTDocumentSectionView *result = nil;
    CGPoint gestureLocation;
    // Try to find the section to place the element view into.
    CGPoint viewLocation = [panGesture locationInView:[self designerContentView]];
    
    //Find the section to add the element.
    for (UIView *sectionView in [[self designerContentView] subviews]) {
        if ([sectionView isKindOfClass:[MTDocumentSectionView class]]) {
            if (CGRectContainsPoint([sectionView frame], viewLocation) && ![sectionView isEqual:self]) {
                result = [[(MTDocumentSectionView *)sectionView retain] autorelease];
                gestureLocation = [panGesture locationInView:result];
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [[panGesture view] setCenter: gestureLocation];
                break;
            }
        }
    }
    
    //Section not found, so add to the first one.
    if (result == nil) {
        for (UICollectionView *view in [[self designerContentView] subviews]) {
            if ([view isKindOfClass: [MTDocumentSectionView class]]) {
                result = [[(MTDocumentSectionView *)view retain] autorelease];
                gestureLocation = [panGesture locationInView:result];//[panGesture view].center;
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [[panGesture view] setCenter: gestureLocation];
                break;
            }
        }
    }
    return result;
}

- (void)resizeCollectionView:(UICollectionView *)collectionView {
    
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: [reportDocument managedObjectContext]];
    [documentSection setHeight:@([collectionView intrinsicContentSize].height)];
    __block MTReportDesignerViewController *reportDesigner = self;
    [UIView animateWithDuration:0.6666f animations:^{
        [collectionView invalidateIntrinsicContentSize];
        [[reportDesigner designerContentView] setNeedsUpdateConstraints];
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
