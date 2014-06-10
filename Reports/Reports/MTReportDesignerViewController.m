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
#import "RptqDatabase.h"
#import "RptqQuery.h"
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

typedef void (^block_insertObject)(UIStoryboardSegue *);

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
};

typedef NS_ENUM(NSUInteger, MTDirection) {
    MTDirectionNorth,       //60˚-120˚
    MTDirectionNorthWest,   //120˚-150˚
    MTDirectionNorthEast,
    MTDirectionSouth,       //240˚-300˚
    MTDirectionSouthWest,   //210˚-240˚
    MTDirectionSouthEast,
    MTDirectionEast,        //330˚-360˚,0-30˚
    MTDirectionWest,        //210˚-150˚
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

@property (nonatomic, strong) NSArray *sectionViewsArray;
@property (nonatomic, strong) NSArray *sectionControlViewsArray;

@property (nonatomic, strong) NSArray *viewDidAppearDesignerScrollViewConstraints;  //These are removed on disapear
@property (nonatomic, strong) NSArray *viewDidAppearDesignerContentViewConstraints; //These are removed on disapear

@property (nonatomic, strong) MTReportDesignerToolBoxViewController *viewControllerToolbox;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *toolbarBottomHeightConstraint;
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
@property (nonatomic, strong) MTRulerView *rulerView;

@property (nonatomic, weak) IBOutletCollection(NSLayoutConstraint) NSArray *layoutConstraintsToRemove;

@property (nonatomic, strong) NSMutableDictionary *sectionViews;
@property (nonatomic, strong) NSMutableDictionary *sectionControlViews;
@property (nonatomic, strong) NSMutableDictionary *sectionBackgroundViews;

@property (nonatomic, strong) NSMutableDictionary *borderAppliedToView;

@property (nonatomic, weak) IBOutlet UIScrollView *designerScrollView;
@property (nonatomic, weak) IBOutlet UIView *designerContentView;

@property (nonatomic, strong) UIToolbar *toolboxToolbar;
@property (nonatomic, strong) UIView *toolboxBackgroundView;
@property (nonatomic, strong) UIScrollView *toolboxScrollView;

@property (nonatomic, strong) NSArray *layoutConstraintsToolboxVisiable;
@property (nonatomic, strong) NSArray *layoutConstraintsToolboxHidden;
@property (nonatomic, strong) NSArray *toolbarTopItems;
@property (nonatomic, strong) NSArray *toolbarBottomItems;

@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;
@property (nonatomic, strong) NSMutableDictionary *collectionViewReuseIdentifiers;

@property (nonatomic, weak) IBOutlet UIView *toolboxView;

@property (nonatomic, weak) IBOutlet UIButton *informationButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemObjects;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbarTop;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbarBottom;

@property (nonatomic, strong) NSMutableSet *selectedObjectIds;

@property (nonatomic, strong) NSMutableDictionary *layoutConstraintsReportSectionHeight;

@property (nonatomic, strong) MTDocumentSectionView *reportFooterView;

@property (nonatomic, assign) CGPoint pinchInitalPointA;
@property (nonatomic, assign) CGPoint pinchInitalPointB;
@property (nonatomic, assign) CGAffineTransform pinchBeginTransform;

@property (nonatomic, assign) CGPoint currentNewPointA;
@property (nonatomic, assign) CGPoint currentNewPointB;

@property (nonatomic, assign) CGSize currentScaleSize;

@property (nonatomic, assign) BOOL toolbarBottomZero;

@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithToolbar;
@property (nonatomic, assign) UIEdgeInsets edgeInsetsWithoutToolbar;

@property (nonatomic, assign) BOOL insetsSetup;

@property (nonatomic, strong) UIAlertView *alertViewEdit;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditStaticLabel;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditDynamicLabel;

@property (nonatomic, strong) NSManagedObjectID *objectIdEditAggregateFunction;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditBarcode;
@property (nonatomic, strong) NSManagedObjectID *objectIdEditImage;

@property (nonatomic, strong) RptqDocumentObjectBarcode *barcodeToEdit;
@property (nonatomic, strong) RptqDocumentObjectAggregate *aggregateToEdit;
@property (nonatomic, strong) RptqDocumentObjectLabelDataField *dataFieldToEdit;

@end

@implementation MTReportDesignerViewController

#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        MTRulerView *viewRuler = [[MTRulerView alloc] initWithFrame:CGRectZero];

        [[viewRuler layer] setBorderWidth: 0.5000f];
        [[viewRuler layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
        
        [viewRuler setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setRulerView:viewRuler];

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
        
        __weak MTReportDesignerViewController *reportDesigner = self;
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

        MTApplicationInstance *applicationInstance = [AppDelegate app];
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
        
        __weak MTReportDesignerViewController *reportDesigner = self;
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
        
        __weak MTReportDesignerViewController *reportDesigner = self;
        block_insertObject insert = ^(UIStoryboardSegue *action) {
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setDelegate: reportDesigner];
                [[imagePicker navigationBar] setBarTintColor:[UIColor tintColorAnalogous4]];
                [reportDesigner presentViewController:imagePicker animated:YES completion:NULL];
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

            MTApplicationInstance *applicationInstance = [AppDelegate app];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
            NSManagedObjectID *objectId = [self objectIdEditBarcode];
            RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
            RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
            [barcodeObject updateWithBarcode:barcode fieldOne:[barcodeViewController queryField1] fieldTwo:[barcodeViewController queryField2]];
            [self setObjectIdEditBarcode:nil];

        } else {
            
            NSMutableDictionary *defination = [[NSMutableDictionary alloc] initWithCapacity:4];
            defination[MTDocumentObjectDefinationType] = @(MTDocumentObjectTypeBarcode);
            defination[MTDocumentObjectDefinationObject] = [barcodeViewController barcode];

            RptqQueryField *queryField1 = [barcodeViewController queryField1];
            if (queryField1 != nil) {
                NSManagedObjectID *objectId = [queryField1 objectID];
                [defination setObject:objectId forKey:MTDocumentObjectDefinationField1];
            }

            RptqQueryField *queryField2 = [barcodeViewController queryField2];
            if (queryField2 != nil) {
                NSManagedObjectID *objectId = [queryField2 objectID];
                [defination setObject:objectId forKey:MTDocumentObjectDefinationField2];
            }
            [self insertDocumentObjectWithDefination:defination];

        }
        
        [[self barButtonItemObjects] setEnabled:YES];

        
    } else if ([[action identifier] isEqualToString:@"MTStoryboardSegueUnwindToDesigner"]) {

    }

}

- (void)setDisplayActive {
    [self disableTabBarItems];
}

- (void)setDisplayInactive {
    [self enableTabBarItems];
}

- (void)disableTabBarItems {
    NSArray *tabBarItems = [[[self tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
        [item setEnabled:YES];
    }
}

- (void)enableTabBarItems {
    NSArray *tabBarItems = [[[self tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
        [item setEnabled:NO];
    }
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:@"UIBarButtonItemMadDesigner"];
}

- (NSString *)title {
    return NSLocalizedString(@"MAD Designer", "MAD Designer");
}

#pragma mark - View lifecycle

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if ([UIDevice isPad] == NO) {
        CGRect navigationToolbarFrame = self.navigationController.toolbar.frame;
        if (navigationToolbarFrame.size.height != [[self toolbarBottomHeightConstraint] constant]) {
            __weak MTReportDesignerViewController *reportDesigner = self;
            [UIView animateWithDuration:0.1000f delay:0.0000f options:UIViewAnimationOptionTransitionNone animations:^{
                [[reportDesigner toolbarBottomHeightConstraint] setConstant:navigationToolbarFrame.size.height];
            } completion:NULL];
        }
    }

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    __weak MTReportDesignerViewController *reportDesigner = self;
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

    NSArray *viewDidAppearDesignerScrollViewConstraints = [[NSArray alloc] init];
    NSArray *viewDidAppearDesignerContentViewConstraints = [[NSArray alloc] init];
    [self setViewDidAppearDesignerScrollViewConstraints:viewDidAppearDesignerScrollViewConstraints];
    [self setViewDidAppearDesignerContentViewConstraints:viewDidAppearDesignerContentViewConstraints];

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

    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeLeft   relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeLeft   multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeRight  relatedBy:NSLayoutRelationEqual toItem:[self view]          attribute:NSLayoutAttributeRight  multiplier:1.0000f constant:0.0000f];
    NSLayoutConstraint *lc3 = [NSLayoutConstraint constraintWithItem:[self designerContentView] attribute:NSLayoutAttributeTop    relatedBy:NSLayoutRelationEqual toItem:[self toolbarTop]    attribute:NSLayoutAttributeBottom multiplier:1.0000f constant:0.0000f];
    NSArray *constraints = @[lc1, lc2, lc3];
    [[self view] addConstraints:constraints];
    
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    
    MTReportDesignerToolBoxViewController *viewControllerToolbox = [storyboard instantiateViewControllerWithIdentifier:@"MTReportDesignerToolBoxViewControllerIdentifier"];
    [viewControllerToolbox setDelegate:self];
    [self setViewControllerToolbox:viewControllerToolbox];

    MTReportDesignerSectionLayoutSettingsViewController *viewControllerSectionLayoutSettings = [storyboard instantiateViewControllerWithIdentifier:MTReportDesignerSectionLayoutSettingsViewControllerIdentifier];
    [viewControllerSectionLayoutSettings setDelegate:self];
    [self setViewControllerSectionLayoutSettings: viewControllerSectionLayoutSettings];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self viewControllerSectionLayoutSettings]];

    [[navigationController navigationBar] setBarTintColor:[UIColor tintColorBlue]];
    [[navigationController navigationBar] setTintColor:[UIColor tintColorWhite]];
    UIColor *whiteColor = [UIColor whiteColor];
    NSDictionary *textAttribues = @{ NSForegroundColorAttributeName : whiteColor };
    [[navigationController navigationBar] setTitleTextAttributes:textAttribues];
    [self setNavigationControllerSectionLayoutSettings:navigationController];
    
    if ([UIDevice isPad] == NO) {   //Don't need a done button in a popover.
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideToolbox)];
        [[[self viewControllerSectionLayoutSettings] navigationItem] setRightBarButtonItem:doneButton animated:NO];
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
        [popoverControllerInformation setPopoverContentSize:CGSizeMake(320.0000f, 480.0000f) animated:NO];
        [self setPopoverControllerInformation:popoverControllerInformation];

        UIPopoverController *popoverControllerSectionSettings = [[UIPopoverController alloc] initWithContentViewController:[self navigationControllerSectionLayoutSettings]];
        [popoverControllerSectionSettings setDelegate:self];
        [popoverControllerSectionSettings setPopoverContentSize:CGSizeMake(320.0000f, 480.0000f) animated:NO];
        [self setPopoverControllerSectionSettings:popoverControllerSectionSettings];
    }
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [self setSelectedObjectIds:set];
    [self setToolbarTopItems:[[self toolbarTop] items]];
    [self setToolbarBottomItems:[[self toolbarBottom] items]];
    
    [[[AppDelegate app] reportDesigner] setToolboxIsVisible:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MTApplicationInstance *app = [AppDelegate app];
    [[app reportDesigner] setZoomScaleRestore:[[self designerScrollView] zoomScale]];
    [[self designerScrollView] setZoomScale:1.0000f animated:NO];

    MAReportDocument *reportDocument = [app activeDocument];

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
                        object: reportDocument];
    
    RptqDocument *document = [reportDocument activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    
    NSInteger sectionCounter = 0;
    UInt16 numberOfSections = [sectionEnumerator count];
    
    NSMutableDictionary *layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setLayoutConstraintsReportSectionHeight:layoutConstraintsReportSectionHeight];
    
    NSMutableDictionary *dictionarySectionBackgroundViews = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionBackgroundViews:dictionarySectionBackgroundViews];
    
    NSMutableDictionary *dictionarySections = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionViews: dictionarySections];
    
    NSMutableDictionary *dictionarySectionControls = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setSectionControlViews:dictionarySectionControls];
    
    NSMutableDictionary *collectionViewReuseIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    [self setCollectionViewReuseIdentifiers:collectionViewReuseIdentifiers];
    
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
            
            [collectionView     setContentHuggingPriority:UILayoutPriorityDefaultLow                forAxis:UILayoutConstraintAxisVertical];
            [collectionView     setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
            [sectionControlView setContentHuggingPriority:UILayoutPriorityDefaultLow                forAxis:UILayoutConstraintAxisHorizontal];
            [sectionControlView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            // MARK: Setup vert auto layout
            NSString *collectionViewKey = [reportSection sectionKey];
            
            [[collectionView layer] setBorderColor: [[UIColor lightGrayColor] CGColor]];
            [[collectionView layer] setBorderWidth: 1.0000f / [[UIScreen mainScreen] scale]];
            
            [[self sectionBackgroundViews] setValue:backgroundView forKey:collectionViewKey];
            
            CGFloat reportSectionHeight = [[reportSection height] floatValue];
            sectionHeights += reportSectionHeight;
            
            NSString *lastKey = [reportSectionKeyTracker lastObject];
            id constraintItem =  sectionCounter == 0 ? [self rulerView] : /*lastCollectionView;*/ [[self sectionViews] objectForKey:lastKey];
            
            [collectionView setShowsVerticalScrollIndicator:YES];
            
            /*
            for (UIGestureRecognizer *parentGesture in [[self designerScrollView] gestureRecognizers]) {
                if ([parentGesture isKindOfClass:[UIPanGestureRecognizer class]]) {
                    [parentGesture setDelaysTouchesBegan:YES];
                    for (UIGestureRecognizer *childGesture in [collectionView gestureRecognizers]) {
                        if ([childGesture isKindOfClass:[UIPanGestureRecognizer class]]) {
                            [childGesture setDelaysTouchesBegan:NO];
                            //[parentGesture requireGestureRecognizerToFail:childGesture];
                            NSLog(@"Parent %@", parentGesture);
                            NSLog(@"Child  %@", childGesture);
                        }
                    }
                }
            }*/
          
            [[self designerScrollView] setDelaysContentTouches:YES];
            [self designerScrollView].canCancelContentTouches = YES;

            [collectionView setDelaysContentTouches:NO];
            collectionView.canCancelContentTouches = NO;
            
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
            
            sectionCounter++;
            
        }
        
    }
    [self setSectionViewsArray: sectionViewsArray];
    [self setSectionControlViewsArray:sectionControlViewsArray];
    
    sectionHeights += MTReportDesignerBorderPaddingVertical;
    
    for (NSLayoutConstraint *layoutConstraint in [[self designerContentView] constraints]) {
        if ([layoutConstraint firstAttribute] ==  NSLayoutAttributeHeight &&
            [layoutConstraint secondItem] == nil &&
            [[layoutConstraint firstItem] isKindOfClass:[MTDocumentSectionView class]]) {
            NSManagedObjectID *objectId = [[layoutConstraint firstItem] objectIdTag];
            NSString *key =[[NSString alloc] initWithString: [[objectId URIRepresentation] absoluteString]];
            [[self layoutConstraintsReportSectionHeight] setObject:layoutConstraint forKey:key];
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
    
    [[self designerScrollView] setScrollEnabled:YES];
    [[self designerScrollView] setMaximumZoomScale:4.0000f];
    [[self designerScrollView] setMinimumZoomScale:1.0000f];
    [[self designerScrollView] setDelegate:self];
    [[self designerScrollView] setUserInteractionEnabled:YES];
    [[self designerScrollView] setBackgroundColor:[UIColor lightGrayColor]];
    [[self designerScrollView] setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
    [[self designerScrollView] flashScrollIndicators];
    
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
                             name: UIMenuControllerWillHideMenuNotification
                           object: nil];
    [defaultCenter removeObserver: self
                             name: UIMenuControllerWillShowMenuNotification
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
        
        __weak MTReportDesignerViewController *weakSelf = self;
        [UIView animateWithDuration:animationDuration delay:delay options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [[weakSelf rulerView] removeFromSuperview];
        } completion:NULL];
        
        for (UIView *view in [self sectionViewsArray]) {
            __weak UIView *bview = view;
            [UIView animateWithDuration:animationDuration delay:delay options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [bview removeFromSuperview];
            } completion:NULL];
        }
        for (UIView *view in [self sectionControlViewsArray]) {
            __weak UIView *bview = view;
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
    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
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
    
    [[self layoutConstraintDesignerContentViewHeight] setConstant:designerContentViewSize.height];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[viewController view] setFrame:[[navigationController view] frame]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showObjects"]) {
        
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            [self setDisplayInactive];
            
            [[self barButtonItemObjects] setEnabled:NO];
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            UIPopoverController *popoverController = [popoverSegue popoverController];
            [popoverController setDelegate:self];
            CGSize popoverSize = CGSizeMake(320.0000f, 480.0000 + 44.0000f);
            [popoverController setPopoverContentSize:popoverSize animated:YES];
            
            [self setPopoverControllerObjectSelector:popoverController];
        }
        
        MTReportDesignerObjectSelectorViewController *viewControllerObjectSelector = nil;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            UINavigationController *d = [segue destinationViewController];
            [d setDelegate:self];
            viewControllerObjectSelector = (MTReportDesignerObjectSelectorViewController *)[d topViewController];
            [viewControllerObjectSelector setObjectSelectorDelegate:self];

            
        } else {
            viewControllerObjectSelector = [segue destinationViewController];
            [viewControllerObjectSelector setObjectSelectorDelegate:self];
        }
        
        

    } else if ([[segue identifier] isEqualToString:@"MTSegueShowReportViewer"]) {

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
        
        
        MTViewControllerBarcode *barcodeViewController = [segue destinationViewController];

        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditBarcode];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
        [barcodeViewController setBarcodeToEdit: barcodeObject];

    } else if ([[segue identifier] isEqualToString:@"MTIdentifierSegueDocumentObjectEditAggregate"]) {
        
        MTDocumentObjectNewAggregateViewController *aggregateViewController = [segue destinationViewController];
        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditAggregateFunction];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
        RptqDocumentObjectAggregate *aggregateObject = [documentObject isAggregate];
        [aggregateViewController setAggregateObjectToEdit:aggregateObject];
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

    for (MTElementView *elementView in [self elementViews]) {
        [elementView setContentScaleFactor:scale];
    }
    
    for (DesignerSectionLabel *controlView in [self sectionControlViewsArray]) {
        [[controlView labelSectionIdentifer] setContentScaleFactor:scale];
    }
    
    for (UICollectionView *collectionView in [[self sectionViews] objectEnumerator]) {
        [collectionView setContentScaleFactor:scale];
    }
}

#pragma mark - Document State

- (void)documentStateChanged {
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    switch ([reportDocument documentState]) {
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

- (void)sectionLayoutDidUpdateVisibility:(BOOL)isVisible {
    
    NSUInteger selectedSectionNumber = [self lastSelectedSectionControlPanel];
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    [RptqDocumentSection setVisibility: isVisible
                       forSectionAtRow: selectedSectionNumber
                            inDocument: document];
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: selectedSectionNumber
                                                                                forQuery: query];
    
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    UIColor *color = [MTReportDesignerViewController sectionBackgroundColor:isVisible];
    [documentSectionView setBackgroundColor:color];
    [reportDocument saveContext];
}

- (void)sectionLayoutDidUpdateHeight:(CGFloat)height {
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                forQuery: query];
    UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];
    CGFloat h = [[documentSectionView collectionViewLayout] collectionViewContentSize].height;
    [documentSection setInterfaceHeight: h];    // WTF: Why is this called twice
    MTReportDesignerSectionBackgroundView *backgroundView = [[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]];
    [backgroundView setNeedsDisplay];
    [[documentSectionView collectionViewLayout] invalidateLayout];
    [documentSection setInterfaceHeight: h];

    [[self view] setNeedsUpdateConstraints];
    
}

// FIXME: Used for multiple rows in the document section... currently unused

- (void)sectionLayoutDidUpdateNumberOfRows:(NSUInteger)numberOfRows {
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                        forQuery: query];
    
    BOOL insertNewSection = numberOfRows > documentSection.numberOfRows.integerValue;
    BOOL deleteLastSection = numberOfRows < documentSection.numberOfRows.integerValue;
    
    __weak UICollectionView *documentSectionView = [self getSectionViewForDocumentSection: documentSection];

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
        
    } else if (numberOfRows < [[documentSection numberOfRows] integerValue]) {
        
        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[documentSection hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[documentSection hasRows] array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [documentSection setHasRows:hasRows];
        [rowToDelete setInSection:nil];
        
    }
    [documentSection setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
    
    MTReportDesignerSectionBackgroundView *backgroundView = [[self sectionBackgroundViews] objectForKey:[documentSection sectionKey]];
    [backgroundView setNumberOfRowsInBackground:numberOfRows];

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
}

#pragma mark - Section View Delegate

- (void)didUpdateLayout:(id)sender {
    MTDocumentSectionView *documentSectionView = (MTDocumentSectionView *)sender;
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[documentSectionView objectIdTag] fromObjectContext:managedObjectContext];
    [documentSection setHeight:@([documentSectionView bounds].size.height)];
    

    [self relayoutSectionView:documentSectionView];
    
    [managedObjectContext save:nil];
}

- (void)relayoutSectionView:(MTDocumentSectionView *)documentSectionView {
    NSManagedObjectID *objectId = [documentSectionView objectIdTag];
    NSURL *objectIdUrl = [objectId URIRepresentation];
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContect = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:objectId fromObjectContext:managedObjectContect];

    NSLayoutConstraint *layoutConstraint = [[self layoutConstraintsReportSectionHeight] objectForKey:[objectIdUrl absoluteString]];
    [layoutConstraint setConstant:documentSection.height.floatValue];
    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - Toolbox Delegate

- (void)toolboxHeightChanged:(CGFloat)newHeight {
    CGSize newSize = CGSizeMake(320.0000f, newHeight);
    [[self popoverControllerInformation] setPopoverContentSize:newSize animated:YES];
    [[[self popoverControllerInformation] contentViewController] setPreferredContentSize:newSize];

}

#pragma mark - Core Data Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];

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
    return [[self designerContentView] viewWithTag: hash];
}
- (MTElementView *)elementViewForManagedObjectID:(NSManagedObjectID *)managedObjectID inObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSManagedObject *managedObject = [managedObjectContext objectWithID:managedObjectID];
    return [self elementViewForManagedObject:managedObject];
}

- (MTElementView *)elementViewForManagedObject:(NSManagedObject *)managedObject {
    MTElementView *elementView = nil;
    elementView = (MTElementView *)[self viewForObjectID:[managedObject objectID]];
    if (!elementView) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObject:managedObject];
        if (documentObject) {
            NSUInteger hash = [[documentObject objectID] hash];
            elementView = (MTElementView *)[[self designerContentView] viewWithTag:hash];
            if (!elementView) {
                elementView = [[MTElementView alloc] initWithObjectId:[documentObject objectID] inObjectContext:[documentObject managedObjectContext]];
                [elementView setTag: hash];
                [elementView setDelegate:self];
                [elementView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                [self updateElementView:elementView forManagedObjectContext:[documentObject managedObjectContext]];
            }
        }
    }
    return elementView;
}

- (RptqDocumentObject *)documentObjectForElementView:(MTElementView *)elementView inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectID *objectID = [elementView objectIdTag];
    return (RptqDocumentObject *)[managedObjectContext objectWithID:objectID];
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
            
            NSString *string = [documentObject designerRepresentationText];
            
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
            NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:string
                                                                                    attributes:attributes];
            [elementView setDisplayStringAttributed:attributtedString];
            
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

- (void)willHideMenuNotification:(NSNotification *)notification { }
- (void)didHideMenuNotification:(NSNotification *)notification { }
- (void)didShowMenuNotification:(NSNotification *)notification { }
- (void)willShowMenuNotification:(NSNotification *)notification { }

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
    MTApplicationInstance *applicationInstance = [AppDelegate app];
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

- (void)didTouchElementView:(MTElementView *)elementView {
    [self removeBorderFromSectionViews];
    if ([self elementViewIsSelected:elementView]) {
        [self deselectElementView:elementView animated:YES];
    } else {
        [self selectElementView:elementView];
    }
}

- (void)sizeChanged:(id)sender {
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocument *document = [reportDocument activeDocument];

    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[reportSection identifier] integerValue]];
        if ([(UIView *)sender isDescendantOfView: documentSectionView]) {
            [[documentSectionView collectionViewLayout] invalidateLayout];
        }
    }

    [self updateElementView:sender forManagedObjectContext:[document managedObjectContext]];
}

- (BOOL)oneOrMoreElementsSelected {
    return [[self selectedObjectIds] count] > 0;
}

- (BOOL)elementViewIsSelected:(MTElementView *)elementView {
    return [[self selectedObjectIds] containsObject:[elementView objectIdTag]];
}

- (NSInteger)removeBorderFromAllSectionViews {
    NSUInteger deselectedSectionViewCounter = 0;
    for (UIView *view in [[self sectionControlViews] objectEnumerator]) {
        deselectedSectionViewCounter += [self  removeBorderFromView:view] ? 1 : 0;
    }
    return deselectedSectionViewCounter;
}

- (void)selectElementView:(MTElementView *)elementView {
    
    NSInteger numberOfViewsDeselected = [self removeBorderFromAllSectionViews];
    
    if (numberOfViewsDeselected == 0) {
        
        [[self selectedObjectIds] addObject:[elementView objectIdTag]];
        [self applyBorderToView:elementView];
        
        [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
        
        if ([UIDevice isPad] == NO) {
            if ([self dismissAllPopovers] == NO) {
                [self showToolbox:MTToolboxTypeElement];
            }
        } else {
            
            NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
            [passThroughViews addObject:elementView];
            
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            [[self popoverControllerInformation] setPopoverContentSize: CGSizeMake(320.0000f, 300.0000f) animated:NO];

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

        NSMutableSet *passThroughViews = [[NSMutableSet alloc] initWithArray:[[self popoverControllerInformation] passthroughViews]];
        [passThroughViews removeObject:elementView];

        if ([[self popoverControllerInformation] isPopoverVisible]) {
            if ([self oneOrMoreElementsSelected]) {
                [self repositionPopoverControllerInformationAnimated:animated];
                [self setDisplayInactive];
            } else {
                [[self popoverControllerInformation] dismissPopoverAnimated:animated];
            }
        }
    }
    
    if ([self oneOrMoreElementsSelected] == NO) {
        [self hideToolbox];
    }
}

- (UIViewController *)viewControllerForToolboxType:(MTToolboxType)tooboxType {
    UIViewController *viewController;
    switch (tooboxType) {
            
        case MTToolboxTypeElement:
            [[self popoverControllerInformation] setPassthroughViews:[[self elementViews] allObjects]];
            [[self viewControllerToolbox] showToolboxWithObjectIds:[self selectedObjectIds]];
            viewController = [self viewControllerToolbox];
            break;
            
        case MTToolboxTypeSection: {
            [[self navigationControllerSectionLayoutSettings] setNavigationBarHidden:NO animated:NO];
            viewController = [self navigationControllerSectionLayoutSettings];
            break;
        }
        default:
            NSAssert(false, @"%s: ToolboxType unkonwn.", __PRETTY_FUNCTION__);
            break;
    }
    return viewController;
}

- (void)setupToolboxWithViewController:(UIViewController *)viewController {
    [[viewController view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.toolboxView.frame.size.width, self.toolboxView.frame.size.height)];
    [[viewController view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    if ([[viewController view] superview] == nil) {
        [[self toolboxView] addSubview:[viewController view]];
    }
}

- (void)presentToolboxPopoverControllers {
    [[self popoverControllerInformation] presentPopoverFromBarButtonItem:[self barButtonItemInfo]
                                                permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                animated:YES];
    [self setDisplayInactive];
}

- (void)dismissToolboxPopoverControllers {
    if ([[self popoverControllerInformation] isPopoverVisible]) {
        [[self popoverControllerInformation] dismissPopoverAnimated:YES];
    }
    if ([[self popoverControllerSectionSettings] isPopoverVisible]) {
        [[self popoverControllerSectionSettings] dismissPopoverAnimated:YES];
    }
}

- (void)presentToolboxViewOfType:(MTToolboxType)toolboxType {
    MTReportDesigner *reportDesignerModal = [[AppDelegate app] reportDesigner];
    if ([reportDesignerModal toolboxIsVisible] == NO) {
        [reportDesignerModal setToolboxIsVisible:YES];
        [[self informationButton] setEnabled: NO];
        
        [self removeItemsFromToolbars];
        [[self view] layoutIfNeeded];
        [reportDesignerModal setContentOffsetOnShowToolbox:self.designerScrollView.contentOffset];
        
        __weak MTReportDesignerViewController *weakSelf = self;
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                         animations: ^{
                             [MTReportDesignerViewController setConstraintsForToolboxVisibleOnDesigner:weakSelf];
                             
                             UIEdgeInsets insets = [weakSelf edgeInsetsWithoutToolbar];
                             [[weakSelf designerScrollView] setContentInset: insets];
                             [[weakSelf designerScrollView] setScrollIndicatorInsets: insets];
                             [[weakSelf view] layoutIfNeeded];
                         } completion: ^(BOOL finished) {
                             if (finished) {
                                 [MTReportDesignerViewController adjustContextOffsetForToolboxInDesigner:weakSelf withToolboxType:toolboxType];
                             }
                         }];
    }

}

- (void)dismissToolboxView {
    MTReportDesigner *reportDesigner = [[AppDelegate app] reportDesigner];
    if ([reportDesigner toolboxIsVisible]) {
        [reportDesigner setToolboxIsVisible:NO];
        
        [[self view] layoutIfNeeded];
        [[self navigationControllerSectionLayoutSettings] setNavigationBarHidden:YES animated:YES];
        
        __weak MTReportDesignerViewController *weakSelf = self;
        
        MTBlockCompletionNoReturn animations = ^{
            [MTReportDesignerViewController setConstraintsForToolboxHiddenOnDesigner:weakSelf];
            UIEdgeInsets insets = [weakSelf edgeInsetsWithToolbar];
            [[weakSelf designerScrollView] setContentInset: insets];
            [[weakSelf view] layoutIfNeeded];
        };
        
        MTBlockCompletionSimple completion = ^(BOOL finished) {
            if (finished) {
                if ([[[weakSelf navigationControllerSectionLayoutSettings] view] superview] != nil) {
                    [[[weakSelf navigationControllerSectionLayoutSettings] view] removeFromSuperview];
                }
                if ([[[weakSelf viewControllerToolbox] view] superview] != nil) {
                    [[[weakSelf viewControllerToolbox] view] removeFromSuperview];
                }
                [[weakSelf toolbarBottom] setItems:[weakSelf toolbarBottomItems] animated:YES];
                [[weakSelf toolbarTop] setItems:[weakSelf toolbarTopItems] animated:YES];
                [[weakSelf informationButton] setEnabled: YES];
                
                CGPoint contentOffset = [[[AppDelegate app] reportDesigner] contentOffsetOnShowToolbox];
                [[weakSelf designerScrollView] setContentOffset:contentOffset animated:YES];
                
            }
        };
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf animations: animations
                         completion:completion];
    }
}

- (void)hideToolbox {
    [UIDevice isPad] ? [self dismissToolboxPopoverControllers] : [self dismissToolboxView];
    [self deselectAllElementsAnimated:YES];
    [[[[AppDelegate app] activeDocument] managedObjectContext] save:nil];
}

- (IBAction)showToolbox:(MTToolboxType)tooboxType {
    UIViewController *viewController = [self viewControllerForToolboxType:tooboxType];
    [self setupToolboxWithViewController:viewController];
    [UIDevice isPad] ? [self presentToolboxPopoverControllers] : [self presentToolboxViewOfType:tooboxType];
}

+ (void)adjustContextOffsetForToolboxInDesigner:(MTReportDesignerViewController *)reportDesigner  withToolboxType:(MTToolboxType)toolboxType {
    if (toolboxType == MTToolboxTypeSection) {
        [reportDesigner adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:reportDesigner];
    } else if (toolboxType == MTToolboxTypeElement) {
        [reportDesigner adjustContentOffsetForSelectedElementsInDesigner:reportDesigner];
    }
}

- (void)adjustContentOffsetForSelectedElementsInDesigner:(MTReportDesignerViewController *)reportDesigner {
    CGRect rectToShow = [reportDesigner rectForSelectedElements];
    [MTReportDesignerViewController positionDesigner:reportDesigner forRectOfInterest:rectToShow];
}

- (void)adjustContentOffsetForLastSelectedSectionControlPanelInDesigner:(MTReportDesignerViewController *)reportDesigner {
    RptqQuery *query = [AppDelegate activeRptqQuery];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForRow: [reportDesigner lastSelectedSectionControlPanel]
                                                                                forQuery: query];
    UIView *selectedSectionView = [reportDesigner getSectionViewForDocumentSection:documentSection];
    [MTReportDesignerViewController positionDesigner:reportDesigner forRectOfInterest:selectedSectionView.frame];
}

+ (void)positionDesigner:(MTReportDesignerViewController *)reportDesigner forRectOfInterest:(CGRect)rectOfInterest {
    
    CGRect visableRect = [MTReportDesignerViewController visableRect:reportDesigner.designerScrollView];
    CGRect bounds = [reportDesigner.designerScrollView convertRect: reportDesigner.designerScrollView.bounds
                                                       toView: reportDesigner.view];
    CGFloat adjustment = [reportDesigner heightScrollViewAdjustment];
    if (CGRectIntersectsRect(visableRect, rectOfInterest) == NO) {
        
        CGPoint contentOffset;
        if (NO) {   //Moves content to top of screen. To jaring of a move.
            bounds.size.height -= adjustment;
            rectOfInterest.origin.y -= adjustment;
            visableRect.origin.y -= adjustment;
            contentOffset = [MTReportDesignerViewController contentOffsetTopOfRect:rectOfInterest];
        } else {
            contentOffset = [MTReportDesignerViewController contectOffsetBottomOfRect:rectOfInterest inRect:visableRect];
        }
        [[reportDesigner designerScrollView] setContentOffset:contentOffset animated:YES];
    }
}

+ (CGPoint)contentOffsetTopOfRect:(CGRect)rect {
    CGFloat yOffset = rect.origin.y;
    return CGPointMake(CGPointZero.x, yOffset);
}

+ (CGPoint)contectOffsetBottomOfRect:(CGRect)rect inRect:(CGRect)containerRect {
    CGFloat yOffset = rect.origin.y - containerRect.size.height + rect.size.height;
    return CGPointMake(CGPointZero.x, yOffset);
}

+ (void)setConstraintsForToolboxVisibleOnDesigner:(MTReportDesignerViewController *)reportDesigner {
    [[reportDesigner view] removeConstraints:[reportDesigner layoutConstraintsToolboxHidden]];
    [[reportDesigner view] addConstraints:[reportDesigner layoutConstraintsToolboxVisiable]];
    [[reportDesigner toolbarBottomHeightConstraint] setConstant:CGSizeZero.height];
}

+ (void)setConstraintsForToolboxHiddenOnDesigner:(MTReportDesignerViewController *)reportDesigner {
    [[reportDesigner view] removeConstraints:[reportDesigner layoutConstraintsToolboxVisiable]];
    [[reportDesigner view] addConstraints:[reportDesigner layoutConstraintsToolboxHidden]];
    [[reportDesigner toolbarBottomHeightConstraint] setConstant:CGSizeZero.height];
}

- (void)removeItemsFromToolbars {
    [[self toolbarBottom] setItems:nil animated:YES];
    [[self toolbarTop] setItems:nil animated:YES];
}

- (void)repositionPopoverControllerInformationAnimated:(BOOL)animated {
    CGRect popoverRect = [self rectForSelectedElements];
    [[self popoverControllerInformation] presentPopoverFromRect:popoverRect
                                                         inView:[self designerContentView]
                                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                                       animated:animated];
}

- (void)didHighlightElementView:(id)sender { }
- (void)didUnhighlightElementView:(id)sender { }

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // FIXME: Add ability to edit image fields.  84848422
    
    BOOL editedImageExist = [info objectForKey:UIImagePickerControllerEditedImage] != nil;
    UIImage *selectedImage = nil;
    if (editedImageExist) {
        selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    
    if (selectedImage != nil) {
        __weak MTReportDesignerViewController *reportDesigner = self;
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
        
        __weak UIScrollView *blockScrollView = [self designerScrollView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [blockScrollView setContentOffset:CGPointZero animated:NO];
            });
        });
        // FIXME: Zoom to double tap point.
    }
}

- (void)deselectAllElementsAnimated:(BOOL)animated {

    //Remove border from element views
    for (MTElementView *elementView in [self selectedElementViews]) {
        [self deselectElementView:elementView animated:animated];
    }
    
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
    UIColor *tintColor = [UIColor tintColorAnalogous4];
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
        [self deselectAllElementsAnimated:YES];
    }
    return result;
}

- (NSSet *)elementViews {
    
    RptqDocument *document = [[[AppDelegate app] activeDocument] activeDocument];
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithDocument:document];
    NSMutableSet *results = [[NSMutableSet alloc] init];

    for (RptqDocumentSection *documentSection in sectionEnumerator) {
        MTDocumentSectionView *documentSectionView = [self documentSectionViewWithIdentifier:[[documentSection identifier] integerValue]];
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
    for (id subview in [[self designerContentView] subviews]) {
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
        
        NSAssert(quickHashWorks, @"Maybe not such a good idea.");
        if (quickHashWorks == NO) {     // FIXME: This case should be unneeded now.
            
            MTApplicationInstance *applicationInstance = [AppDelegate app];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            RptqDocument *document = [reportDocument activeDocument];
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
    return [[self sectionViews] objectForKey:[documentSection sectionKey]];
}

- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)documentSection {
    return [[self sectionControlViews] objectForKey:[documentSection sectionKey]];
}

- (IBAction)done:(id)sender {
    
    NSError *error = nil;
    MTApplicationInstance *applicationInstance = [AppDelegate app];
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

- (IBAction)showObjects:(id)sender {
    [[self barButtonItemObjects] setEnabled:NO];
    if (![self dismissAllPopovers]) {
        [self performSegueWithIdentifier:@"showObjects" sender:sender];
    } else {
        [self deselectAllElementsAnimated:YES];
    }
}

- (CGFloat)heightTopBars {
    CGFloat height = self.navigationController.navigationBar.bounds.size.height;
    return UIDeviceOrientationIsLandscape([self interfaceOrientation]) ? (height += [UIApplication sharedApplication].statusBarFrame.size.width) : (height += [UIApplication sharedApplication].statusBarFrame.size.height);
}

- (CGFloat)heightScrollViewAdjustment {
    return [self heightTopBars] + (MTReportDesignerBorderPadding / 2.0000f);
}

+ (CGRect)visableRect:(UIScrollView *)scrollView {
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    //if (visibleRect.origin.y < CGPointZero.y) {
    //    visibleRect.size.height += fabsf(visibleRect.origin.y);
    //}
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

- (void)resizeCollectionView:(UICollectionView *)collectionView forSectionWithId:(NSManagedObjectID *)sectionObjectId {
    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForObjectID:sectionObjectId fromObjectContext:managedObjectContext];
    CGSize contentSize = [(MTReportDesignerSectionViewLayoutLiquid *)[collectionView collectionViewLayout] collectionViewContentSize];

    [section setInterfaceHeight:contentSize.height];
    
    [[self designerContentView] setNeedsLayout];
    [[self view] setNeedsUpdateConstraints];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self deselectAllElementsAnimated:YES];
    [[self barButtonItemObjects] setEnabled:YES];
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
    BOOL result = NO;
    return result;
}

#pragma mark -
#pragma mark MTCollectionViewCellElement Delegate

- (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell {
    NSManagedObjectID *objectId = [cell objectIdTag];
    MTApplicationInstance *applicationInstance = [AppDelegate app];
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
            MTApplicationInstance *applicationInstance = [AppDelegate app];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            [RptqDocumentObject removeDocumentObject:documentObject];
        }
    }];
}

- (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {
    [self deselectAllElementsAnimated:YES];
    [self selectElementView:(MTElementView *)[self viewForObjectID:[cell objectIdTag]]];
}

- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell {

    NSManagedObjectID *elementViewId = [cell objectIdTag];
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:elementViewId fromObjectContext:managedObjectContext];
    
    RptqDocumentSection *section = [[documentObject inSectionRow] inSection];
    UICollectionView *svSection = [self getSectionViewForDocumentSection:section];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
    
    BOOL found = NO;
    
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
                        
                        NSManagedObjectID *objectId = [objectToEdit objectID];
                        UIView *viewToEdit = [self viewForObjectID:objectId];

                        if (viewToEdit != nil) {
                            
                            CGSize popoverSize = CGSizeMake(320.0000f, 480.0000f);
                            UIStoryboard *storyboard = [MTApplicationInstance storyboard];
                            
                            UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:MTDocumentObjectNewAggregateNavigationControllerIdentifier];
                            MTDocumentObjectNewAggregateViewController *aggregateViewController = [[navigationController viewControllers] firstObject];
                            [aggregateViewController setDelegate:self];
                            
                            MTApplicationInstance *applicationInstance = [AppDelegate app];
                            MAReportDocument *reportDocument = [applicationInstance activeDocument];

                            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                            RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
                            RptqDocumentObjectAggregate *aggregateObject =  [documentObject isAggregate];
                            [aggregateViewController setAggregateObjectToEdit:aggregateObject];
                            
                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            [self setDisplayInactive];
                            [self setPopoverControllerEditBarcode: popoverController];
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
                            MTViewControllerBarcode *barcodeViewController = [storyboard instantiateViewControllerWithIdentifier: MTDocumentObjectNewBarcodeViewControllerIdentifier];
                            [barcodeViewController setDelegate:self];
                            
                            MTApplicationInstance *applicationInstance = [AppDelegate app];
                            MAReportDocument *reportDocument = [applicationInstance activeDocument];
                            NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                            RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];
                            RptqDocumentObjectBarcode *barcodeObject = [documentObject isBarcode];
                            [self setBarcodeToEdit: barcodeObject];
                            [barcodeViewController setBarcodeToEdit: barcodeObject];
                            
                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:barcodeViewController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            [self setDisplayInactive];

                            [self setPopoverControllerEditBarcode: popoverController];

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
                            MTQueryBuilderChooseFieldViewController *chooseFieldViewController = [storyboard instantiateViewControllerWithIdentifier: @"UITableViewControllerChooseFieldDataObject"];
                            
                            [chooseFieldViewController setDelegate:self];
                            
                            CGRect popoverRect = [viewToEdit convertRect:[viewToEdit bounds] toView:[self designerContentView]];
                            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:chooseFieldViewController];
                            [popoverController setDelegate:self];
                            [popoverController setPopoverContentSize:popoverSize animated:NO];
                            [popoverController presentPopoverFromRect:popoverRect
                                                               inView:[self designerContentView]
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
                            [self setDisplayInactive];
                            [self setPopoverControllerEditDataLabel: popoverController];
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
                    UITextField *textField = [alertView textFieldAtIndex:0];
                    [textField setClearButtonMode:UITextFieldViewModeAlways];
                    [textField setDelegate:self];
                    NSString *textFieldText = [[objectToEdit isLabel] text];
                    [textField setText:textFieldText];
                    [alertView setTag:MTDocumentObjectTypeLabelStatic];
                    [self setAlertViewEdit:alertView];
                    [[self alertViewEdit] show];
                    break;
                }
                case MTDocumentObjectTypeWhtiespace:
                    
                    
                    break;
                default:
                    break;
            }
        }
    }
}

#pragma mark -
#pragma mark - MTViewControllerBarcodeDelegate

- (void)didUpdateBarcode:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo {

    if ([self barcodeToEdit] != nil) {
        RptqDocumentObjectBarcode *barcodeObject = [self barcodeToEdit];
        [barcodeObject updateWithBarcode:barcode fieldOne:fieldOne fieldTwo:fieldTwo];
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
        
        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
        NSManagedObjectID *objectId = [self objectIdEditStaticLabel];
        RptqDocumentObject *documentObject = (RptqDocumentObject *)[managedObjectContext objectWithID:objectId];

        UITextField *textField = [alertView textFieldAtIndex:0];
        [[documentObject isLabel] setText:[textField text]];
        [managedObjectContext save:nil];
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
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    return [[documentSection height] floatValue];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    MTApplicationInstance *applicationInstance = [AppDelegate app];
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

    
    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];
    RptqDocumentSectionRows *rows =[[documentSection hasRows] firstObject];
    NSOrderedSet *objects = [rows hasObjects];
//    RptqDocumentObject *documentObject = [objects objectAtIndex:indexPath.item];
    MTCollectionViewLayoutLiquidAttributes *result = [MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
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
    return result;
}

- (NSUInteger)collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath {

    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
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

    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: managedObjectContext];

    
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
        
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        if (CGPointEqualToPoint(dropPoint, [documentObject dropPoint]) == NO) {
            [documentObject setDropPoint:dropPoint];
            [managedObjectContext save:nil];
        }
    }
}


#pragma mark Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat contextScale = [[self designerScrollView] zoomScale] * [[[[self designerScrollView] window] screen] scale];

    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    NSString *resuseId = [[self collectionViewReuseIdentifiers] objectForKey:[documentSection identifier]];
    
    MTCollectionViewCellElement *cell = [collectionView dequeueReusableCellWithReuseIdentifier:resuseId
                                                                                  forIndexPath:indexPath];
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
                //if ([[documentObject objectID] isTemporaryID]) {
// FIXME: What's happening here.
                //}

                [cell setBackgroundColor:[UIColor clearColor]];
                [[cell contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                
                
                
                MTElementView *elementView = [self elementViewForManagedObject:documentObject];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                
                UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchPiece:)];
                [pinchGesture setDelegate:self];
                
                [[[self designerScrollView] panGestureRecognizer] requireGestureRecognizerToFail:panGesture];
                [[[self designerScrollView] pinchGestureRecognizer] requireGestureRecognizerToFail:pinchGesture];
                
                [elementView addGestureRecognizer:panGesture];
                [elementView addGestureRecognizer:pinchGesture];
                
                [elementView setFrame:cellFrame];
                [cell setObjectIdTag:[documentObject objectID]];
                [cell setUserInteractionEnabled:YES];
                [[cell contentView] addSubview:elementView];
                
                __weak UICollectionViewCell *blockCell = cell;
                __weak MTElementView *blockElementView = elementView;
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
                break;
            }
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
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
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        [label setText:@"Footer"];
        [result addSubview:label];
    } else {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
    }
    return result;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[reportDocument managedObjectContext]];
    return [[documentSection hasRows] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView {
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[reportDocument managedObjectContext]];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:section] hasObjects];
    return [objects count];
}

#pragma mark - Collection View Delegate

- (MTElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath
                         inCollectionView:(UICollectionView *)collectionView {

    return [self elementViewForCollectionViewCell:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (MTElementView *)elementViewForCollectionViewCell:(UICollectionViewCell *)cell {
    MTElementView *result = nil;
    
    for (id elementView in [[cell contentView] subviews]) {
        if ([elementView isKindOfClass:[MTElementView class]]) {
            result = elementView;
            break;
        }
    }
    return result;
}

- (void)edit:(id)sender { }

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:)) {
        result = YES;
    }
    return result;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSInteger row = [indexPath row];
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [[[documentSection hasRows] objectAtIndex:[indexPath section]] hasObjects];
    
    //NSLog(@"Perform Selector: %@", NSStringFromSelector(action));
    
    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        
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

#pragma mark - Delegates
#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[MTSettingsViewController class]]) {
        [[self designerScrollView] setZoomScale:1.0000f animated:NO];
        __weak MTReportDesignerViewController *reportDesigner = self;
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
                __weak MTReportDesignerViewController *reportDesigner = self;
                [self dismissViewControllerAnimated:YES completion:^{
                    [[reportDesigner view] setNeedsUpdateConstraints];
                    [[reportDesigner designerContentView] setNeedsLayout];
                    [[reportDesigner designerContentView] setNeedsDisplay];
                }];
            }
        } else {
            __weak MTReportDesignerViewController *reportDesigner = self;
            [self dismissViewControllerAnimated:YES completion:^{
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
    [[self barButtonItemObjects] setEnabled:YES];
    [self insertDocumentObjectWithDefination:
        @{MTDocumentObjectDefinationType: @(MTDocumentObjectTypeLabelStatic),
           MTDocumentObjectDefinationObject : labelText}];

}

- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination {
    [[self barButtonItemObjects] setEnabled:YES];

    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];

    RptqDocument *document = [reportDocument activeDocument];
    
    RptqDocumentSection *section = [document hasDetailSection];
    
    __weak MTReportDesignerViewController *reportDesigner = self;
    __weak UICollectionView *detailSection = [self getSectionViewForDocumentSection:section];

    [detailSection performBatchUpdates:^{

        RptqDocumentObject *documentObject = [RptqDocumentObject addDocumentObject:documentObjectDefination
                                                                        toDocument:document];
        [documentObject obtainPermanentID];
        
        [detailSection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            [detailSection reloadData];

            MTApplicationInstance *applicationInstance = [AppDelegate app];
            MAReportDocument *activeDocument = [applicationInstance activeDocument];
            
            RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [detailSection objectIdTag]
                                                                                    fromObjectContext: [activeDocument managedObjectContext]];
            
            [documentSection setHeight:@([detailSection intrinsicContentSize].height)];

            [UIView animateWithDuration:0.30000f animations:^{
                [[reportDesigner designerContentView] setNeedsUpdateConstraints];
            }];
            [activeDocument saveContext];
            [activeDocument quickSave];
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
    
    
    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:elementViewId fromObjectContext:managedObjectContext];
    
    RptqDocumentSectionRows *sectionRow = [documentObject inSectionRow];
    RptqDocumentSection *section = [sectionRow inSection];
    NSInteger deleteIndex = [[sectionRow hasObjects] indexOfObject:documentObject];
    UICollectionView *sectionCollectionView = [self getSectionViewForDocumentSection:section];
    
    __weak MTReportDesignerViewController *reportDesigner = self;
    
    __weak UICollectionView *weakSectionCollectionView = sectionCollectionView;
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [sectionRow hasObjects]];
    [hasObjects removeObjectAtIndex:deleteIndex];
    
    [sectionCollectionView performBatchUpdates:^{
        
        [sectionRow setHasObjects:hasObjects];

        [documentObject setInSectionRow:nil];
        NSError *error = nil;
        [managedObjectContext save:&error];
        
        NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
        [weakSectionCollectionView deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
        
    } completion:^(BOOL finished) {
        if (finished) {
            
            [section setHeight:@([weakSectionCollectionView intrinsicContentSize].height)];
            [UIView animateWithDuration:0.6666f animations:^{
                [weakSectionCollectionView invalidateIntrinsicContentSize];
            }];
            [managedObjectContext save:nil];
            
            [MTReportDesignerViewController redrawAllElementViewsInCollectionView:weakSectionCollectionView inDesigner:reportDesigner];
            if (completion != nil) {
                completion(YES);
            }
        }
    }];
}

- (void)addPointA:(CGPoint)pointA andPointB:(CGPoint)pointB {
    _currentNewPointA.x *= previousScaleWeight;
    _currentNewPointA.x += (1 - previousScaleWeight) * pointA.x;
    _currentNewPointA.y *= previousScaleWeight;
    _currentNewPointA.y += (1 - previousScaleWeight) * pointA.y;
    _currentNewPointB.x *= previousScaleWeight;
    _currentNewPointB.x += (1 - previousScaleWeight) * pointB.x;
    _currentNewPointB.y *= previousScaleWeight;
    _currentNewPointB.y += (1 - previousScaleWeight) * pointB.y;
}

- (CGPoint)locationOfPointInWindows:(CGPoint)point {
    UIWindow *window = [AppDelegate window];
    return [[self designerScrollView] convertPoint:point fromView:window];
}

- (CGFloat)directionInDegreesFromVelocity:(CGPoint)velocity {
    CGFloat direction = 0.0000f;
    if (velocity.y == 0) {
        if (velocity.x < 0) {
            direction = -90.0000f;
        } else {
            direction = 90.0000f;
        }
    } else {
        if (velocity.y > 0) {
            direction = atan(velocity.x / velocity.y);
        } else {
            direction = 180 + atan(velocity.x / velocity.y);
        }
    }
    return direction;
}

- (MTDirection)generalDirectionOfDegrees:(CGFloat)degrees {
    MTDirection direction = MTDirectionNorth;
    if (degrees > 60.0000f && degrees < 120.0000f) {
        direction = MTDirectionNorth;
    } else if (degrees > 30.0000f && degrees < 60.0000f) {
        direction = MTDirectionNorthEast;
    } else if ( degrees > 120.0000f && degrees < 150.0000f ) {
        direction = MTDirectionNorthWest;
    } else if ( degrees > 240.0000f && degrees < 300.0000f ) {
        direction = MTDirectionSouth;
    } else if ( degrees > 300.0000f && degrees < 330.0000f ) {
        direction = MTDirectionSouthEast;
    } else if ( degrees > 210.0000f && degrees < 240.0000f ) {
        direction = MTDirectionSouthWest;
    } else if ((degrees > 330.0000f && degrees < 360.0000f) || (degrees > 0.0000f && degrees < 30.0000f)) {
        direction = MTDirectionEast;
    } else if ( degrees > 150.0000f && degrees < 210.0000f) {
        direction = MTDirectionWest;
    }
    return direction;
}

- (void)pinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer {

    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan: {
            
            if ([gestureRecognizer numberOfTouches] >= 2) {
                [self setPinchBeginTransform:[[gestureRecognizer view] transform]];
                UIView *pinchView = [gestureRecognizer view];
                CGPoint locationA = [gestureRecognizer locationOfTouch:0 inView:pinchView];
                CGPoint locationB = [gestureRecognizer locationOfTouch:1 inView:pinchView];
                locationA = [self locationOfPointInWindows:locationA];
                locationB = [self locationOfPointInWindows:locationB];
                
                [self addPointA:locationA andPointB:locationB];
                [self setPinchInitalPointA:locationA];
                [self setPinchInitalPointB:locationB];
            }
            break;
            
        }
        case UIGestureRecognizerStateChanged: {
            
            if ([gestureRecognizer numberOfTouches] >= 2) {
                //UICollectionView *parentView = [self sectionViewFor:gestureRecognizer];
                //CGPoint centroidInParentView = [gestureRecognizer locationInView:parentView];
                //MTElementView *elementView = (MTElementView *)[gestureRecognizer view];
                //CGPoint centroidInElementView = [gestureRecognizer locationInView:elementView];
                //CGPoint touchPointOne = [gestureRecognizer locationOfTouch:0 inView:elementView];
                //CGPoint touchPointTwo = [gestureRecognizer locationOfTouch:1 inView:elementView];
                
                //CGLineSegment lineSegment = CGLineSegmentMake(touchPointOne, touchPointTwo);
                //CGFloat slope = CGLineSegmentSlope(lineSegment);
                //CGFloat directionInDegrees = atan(slope);
                
//                {
                    //CGPoint newTouchA = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                    //CGPoint newTouchB = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                    //[self addPointA:newTouchA
                    //      andPointB:newTouchB];
                    
                    //CGFloat differenceX = fabsf([self pinchInitalPointA].x - [self pinchInitalPointB].x);
                    //CGFloat differenceY = fabsf([self pinchInitalPointA].y - [self pinchInitalPointB].y);
                    
                    //CGFloat newDifferenceX = fabsf(_currentNewPointA.x - _currentNewPointB.x);
                    //CGFloat newDifferenceY = fabsf(_currentNewPointA.y - _currentNewPointB.y);
 //               }
                
                CGFloat scale = gestureRecognizer.scale;
                CGFloat scaleWidth = scale;
                CGFloat scaleHeight = scale;
 //               CGFloat velocity = gestureRecognizer.velocity;
                //CGFloat directionInDegrees = [self directionInDegreesFromVelocity:CGPointMake(velocity, velocity)];
                /*
                MTDirection direction = [self generalDirectionOfDegrees: directionInDegrees];
                NSString *directionDesc;
                switch (direction) {
                    case MTDirectionSouth:
                    case MTDirectionNorth:
                        directionDesc = @"North-South";
                        scaleHeight = scale;
                        scaleWidth = 1.0000f;
                        break;
                    case MTDirectionEast:
                    case MTDirectionWest:
                        directionDesc = @"East-West";
                        scaleHeight = 1.0000f;
                        scaleWidth = scale;
                        break;
                    case MTDirectionNorthEast:
                    case MTDirectionSouthWest:
                    case MTDirectionSouthEast:
                    case MTDirectionNorthWest:
                        directionDesc = @"Diag";
                        scaleHeight = scale;
                        scaleWidth = scale;
                        break;
                    default:
                        scaleHeight = scale;
                        scaleWidth = scale;
                        break;
                }
                */
                //NSLog(@"Pinch (%f, %f, %f˚) at %@ - %@", slope, directionInDegrees, gestureRecognizer.scale, NSStringFromCGPoint(centroidInParentView), directionDesc);


                gestureRecognizer.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleWidth, scaleHeight);
                [gestureRecognizer.view  setNeedsDisplay];
                //[gestureRecognizer.view setCenter:centroidInElementView];
                //CGPoint v = CGPointMake(gestureRecognizer.velocity, gestureRecognizer.velocity);
                //CGFloat directionInDegrees = [self directionInDegreesFromVelocity:v];
                _currentScaleSize = CGSizeMake(scaleWidth, scaleHeight);
                
                
                //Save off the size to use at the end.
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {

            UICollectionView *collectionView = [self sectionViewFor:gestureRecognizer];

            
            MTBlockCompletionNoReturn update = ^(void) {
                MTApplicationInstance *app = [AppDelegate app];
                MAReportDocument *reportDocument = [app activeDocument];
                NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[(MTElementView *)[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
                CGFloat sizeWidth = nearbyintf(_currentScaleSize.width * [[documentObject sizewidth] floatValue]);
                CGFloat sizeHeight = nearbyintf(_currentScaleSize.height * [[documentObject sizeheight] floatValue]);
                MTElementView *elementView = (MTElementView *)[gestureRecognizer view];
                [elementView setTransform: CGAffineTransformScale(CGAffineTransformIdentity, _currentScaleSize.width, _currentScaleSize.height)];
                [documentObject setSizewidth:@(sizeWidth)]; [documentObject setSizeheight:@(sizeHeight)];
                [documentObject setDropPoint:elementView.frame.origin];
                [managedObjectContext save:nil];

                [elementView setNeedsLayout];
                [elementView setNeedsDisplay];

            };
            
            __weak UICollectionView *weakCollectionView = collectionView;
            MTBlockCompletionSimple finishedUpdate = ^(BOOL finished) {
                if (finished) {
                    __weak UICollectionView *weakCollectionView2 = weakCollectionView;
                    [UIView animateWithDuration:0.6666f animations:^{
                        [weakCollectionView2 invalidateIntrinsicContentSize];
                    }];
                }
                
            };

             [collectionView performBatchUpdates:update completion:finishedUpdate];
            [[collectionView collectionViewLayout] invalidateLayout];

            gestureRecognizer.scale = 1.0000f;

            break;
        }
    }
}

- (CGPoint)locationInWindow:(UIGestureRecognizer *)gestureRecognizer {
    UIWindow *window = [AppDelegate window];
    CGPoint gestureLocation = [gestureRecognizer locationInView:window];
    gestureLocation = [[self designerScrollView] convertPoint:gestureLocation fromView:window];
    return gestureLocation;
}

- (void)gestureBegan {
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self setScrollersEnabled: NO];
}

- (void)gestureEnded {
    [self setScrollersEnabled:YES];
}

- (void)singleTapToDeselectElementViews:(UITapGestureRecognizer *)sender {
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self hideToolbox];
}

- (void)toggleSectionControlPanel:(UITapGestureRecognizer *)sender {
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        
        if ([[self selectedElementViews] count] >= 1) {
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
                
                MTApplicationInstance *applicationInstance = [AppDelegate app];
                MAReportDocument *reportDocument = [applicationInstance activeDocument];
                RptqDocument *document = [reportDocument activeDocument];
                RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
                RptqQuery *query = [[database hasQueries] anyObject];
                RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: [self lastSelectedSectionControlPanel]
                                                                                    forQuery: query];
                
                
                if ([[sender view] isKindOfClass:[DesignerSectionLabel class]]) {
                    DesignerSectionLabel *sectionLabel = (DesignerSectionLabel *)[sender view];
                    [sectionLabel dimView];
                    UIColor *borderColor = [UIColor tintColorAnalogous4];
                    UIView *superView = [self getSectionViewForDocumentSection: section];
                    [[superView layer] setBorderColor:  [borderColor CGColor]];
                    [[superView layer] setBorderWidth:  1.0000f];
                }
                
                [[self viewControllerSectionLayoutSettings] setInitalStepperValue:([[section height] floatValue])];
                [[self viewControllerSectionLayoutSettings] setInitalSwitchValue:[[section visibility] boolValue]];
                [[self viewControllerSectionLayoutSettings] setInitalNumberOfRows:[[section numberOfRows] integerValue]];
                [[self viewControllerSectionLayoutSettings] updateDisplay];
                
                if ([UIDevice isPad]) {
                    [[self popoverControllerSectionSettings] setPopoverContentSize:CGSizeMake(320.0000f, 260.00000f) animated:NO];
                    [[self popoverControllerSectionSettings] setPassthroughViews:@[[sender view]]];
                    [[self popoverControllerSectionSettings] presentPopoverFromRect:[[sender view] bounds]
                                                                             inView:[sender view]
                                                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                           animated:YES];
                    [self setDisplayInactive];

                } else {
                    [self showToolbox:MTToolboxTypeSection];
                }
            }
        }
    }
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {

    switch ([gestureRecognizer state]) {
            
        case UIGestureRecognizerStateBegan: {

            [self gestureBegan];
            
            [[gestureRecognizer view] setAlpha:0.8888f];
            [[self designerContentView] bringSubviewToFront: [gestureRecognizer view]];
            CGFloat scale = self.designerScrollView.zoomScale;
            [[gestureRecognizer view] setTransform: CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)];
            CGPoint newCenter = [self locationInWindow:gestureRecognizer];
            [[self designerScrollView] addSubview: [gestureRecognizer view]];
            [self removeCollectionViewCellForElementView:[[gestureRecognizer view] objectIdTag]
                                              completion:nil];
            [[gestureRecognizer view] setCenter: newCenter];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            CGPoint newCenter = [self locationInWindow:gestureRecognizer];
            [[gestureRecognizer view] setCenter: newCenter];

            break;
        }
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            
            [[gestureRecognizer view] setAlpha:1.0000f];
            [[gestureRecognizer view] setTransform: CGAffineTransformScale(CGAffineTransformIdentity, 1.0000, 1.0000)];
            UICollectionView *sectionView = [self sectionViewFor:gestureRecognizer];
            
            if (sectionView != nil) {
                
                MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
                __weak NSManagedObjectContext *managedObjectContext = [reportDocument managedObjectContext];
                
                NSManagedObjectID *objectId = [[gestureRecognizer view] objectIdTag];
                NSManagedObjectID *sectionId = [sectionView objectIdTag];
                
                CGRect frame = [[gestureRecognizer view] frame];
                __weak UIView *weakGestureRecognizerView = [gestureRecognizer view];
                
                __weak RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: sectionId
                                                                                        fromObjectContext: managedObjectContext];
                __weak UICollectionView *weakSectionView = sectionView;
                __weak MTReportDesignerViewController *weakself = self;
                [sectionView performBatchUpdates:^(void) {
                    
                    [weakGestureRecognizerView removeFromSuperview];
                    
                    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID: objectId fromObjectContext: managedObjectContext];

                    
                    NSIndexPath *indexPathInsert = [documentSection addDocumentObject:documentObject withDropPoint:frame.origin];
                    NSArray *indexPathsInserted = @[indexPathInsert];
                    [weakSectionView insertItemsAtIndexPaths:indexPathsInserted];
                    [[documentSection managedObjectContext] save:nil];

                } completion:^(BOOL finished) {
                    if (finished) {
                        [documentSection setHeight:@([weakSectionView intrinsicContentSize].height)];
                        [UIView animateWithDuration:0.6666f animations:^{
                            [weakSectionView invalidateIntrinsicContentSize];
                        }];
                        [managedObjectContext save:nil];
                        
                        [MTReportDesignerViewController redrawAllElementViewsInCollectionView:weakSectionView inDesigner:weakself];
                    }
                }];
                
            }

            [[gestureRecognizer view] setNeedsDisplay];
            [self gestureEnded];
            break;
        }
        default:
            break;
    }
}

+ (void)redrawAllElementViewsInCollectionView:(UICollectionView *)collectionView inDesigner:(MTReportDesignerViewController *)reportDesigner {
    int numberOfItemsInSection = [collectionView numberOfItemsInSection:0];
    for (int i = 0; i < numberOfItemsInSection; i++) {
        NSIndexPath *insertedPath = [NSIndexPath indexPathForItem:i inSection:0];
        MTElementView *elementView = [reportDesigner elementViewAtIndexPath:insertedPath inCollectionView:collectionView];
        [elementView setNeedsDisplay];
    }
}

- (MTDocumentSectionView *)sectionViewFor:(UIGestureRecognizer *)gesture {
    MTDocumentSectionView *result = nil;
    CGPoint gestureLocation;
    // Try to find the section to place the element view into.
    CGPoint viewLocation = [gesture locationInView:[self designerContentView]];
    
    //Find the section to add the element.
    for (UIView *sectionView in [[self designerContentView] subviews]) {
        if ([sectionView isKindOfClass:[MTDocumentSectionView class]]) {
            if (CGRectContainsPoint([sectionView frame], viewLocation) && ![sectionView isEqual:self]) {
                result = (MTDocumentSectionView *)sectionView;
                gestureLocation = [gesture locationInView:result];
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [[gesture view] setCenter: gestureLocation];
                break;
            }
        }
    }
    
    //Section not found, so add to the first one.
    if (result == nil) {
        for (UICollectionView *view in [[self designerContentView] subviews]) {
            if ([view isKindOfClass: [MTDocumentSectionView class]]) {
                result = (MTDocumentSectionView *)view;
                gestureLocation = [gesture locationInView:result];
                gestureLocation = CGPointRoundPointToGrid(gestureLocation);
                [[gesture view] setCenter: gestureLocation];
                break;
            }
        }
    }
    return result;
}

- (void)resizeCollectionView:(UICollectionView *)collectionView height:(CGFloat)height {
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID: [collectionView objectIdTag]
                                                                            fromObjectContext: [reportDocument managedObjectContext]];
    [documentSection setHeight:@([collectionView intrinsicContentSize].height)];
//    __weak MTReportDesignerViewController *reportDesigner = self;
    [UIView animateWithDuration:0.6666f animations:^{
        [collectionView invalidateIntrinsicContentSize];
    }];
    [[reportDocument managedObjectContext] save:nil];
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
