//
//  ReportDesignerTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewController.h"
#import "UIManagedDocumentPreferencesUser.h"
#import "UITableViewControllerSettings.h"
#import "UIViewControllerToolbox.h"
#import "MUIViewControllerObjectSelector.h"
#import "MUIViewControllerReportViewer.h"
#import "NSFileManager+Common.h"
#import "UIViewRuler.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "CGGeometry+Extras.h"
#import "NSError+UserInterface.h"
#import "MTCollectionViewFlowLayoutDesignerSection.h"

@interface MUIViewControllerReportDesigner : MUIViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        UIViewControllerObjectSelectorDelegate,
        MUIViewControllerDelegate,
        ToolboxViewControllerDelegate,
        FontSettingsTableViewControllerDelegate,
        UITableViewControllerFontSelectorDelegate,
        UIScrollViewDelegate>

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;

@property (assign) CGRect designScrollViewNormal;
@property (assign) CGRect designScrollViewWithToolbox;
@property (assign) CGRect toolboxOffScreen;
@property (assign) CGRect toolboxOnScreen;

@property (retain, nonatomic) IBOutlet UIView *toolboxView;

@property (retain, nonatomic) UIViewControllerToolbox *toolbox;
@property (retain, nonatomic) IBOutlet UIScrollView *designScrollView;
@property (retain, nonatomic) IBOutlet UIButton *informationButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemObjects;
@property (retain, nonatomic) IBOutlet UINavigationItem *navBar;

@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (retain) NSMutableDictionary *sections;

- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;
- (IBAction)showSettings:(id)sender;

- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)select:(id)sender;
- (void)selectAll:(id)sender;
- (void)paste:(id)sender;
- (void)delete:(id)sender;

@end