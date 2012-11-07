//
//  ReportDesignerTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewController.h"
#import "UIScrollViewSection.h"
#import "UIManagedDocumentTrvFileData.h"
#import "UITableViewControllerSettings.h"
#import "UIViewControllerToolbox.h"
#import "MUIViewControllerObjectSelector.h"
#import "MUIViewControllerReportViewer.h"
#import "ElementView.h"
#import "NSFileManager+Common.h"
#import "UIViewRuler.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "CGGeometry+Extras.h"
#import "SectionEnumerator.h"

@interface MUIViewControllerReportDesigner : MUIViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        UIPopoverControllerDelegate,
        UIViewControllerObjectSelectorDelegate,
        MUIViewControllerDelegate,
        LabelInformationViewControllerDelegate,
        ElementViewDelegate>

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;

@property (assign) CGRect designScrollViewNormal;
@property (assign) CGRect designScrollViewWithToolbox;
@property (assign) CGRect toolboxOffScreen;
@property (assign) CGRect toolboxOnScreen;

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) UIViewControllerToolbox *toolbox;
@property (retain, nonatomic) IBOutlet UIScrollViewSection *designScrollView;
@property (retain, nonatomic) IBOutlet UIButton *informationButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemObjects;
@property (retain, nonatomic) IBOutlet UINavigationItem *navBar;

@property (retain) NSMutableDictionary *svSections;

- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;
- (IBAction)showSettings:(id)sender;

@end