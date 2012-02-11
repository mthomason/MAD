//
//  ReportDesignerTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollViewDashboard.h"
#import "UIViewControllerToolbox.h"
#import "UIManagedDocumentTrvFileData.h"
#import "UITableViewControllerSettings.h"

@class ReportDesignerViewController;
@class UIManagedDocumentQuery;

@protocol ReportDesignerViewControllerDelegate
- (void)reportDesignerViewControllerDidFinish:(ReportDesignerViewController *)controller;
@end

@interface ReportDesignerViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate,
        UIPopoverControllerDelegate,
        UITableViewControllerSettingsDelegate,
        LabelInformationViewControllerDelegate>

@property (assign, nonatomic) IBOutlet id <ReportDesignerViewControllerDelegate> delegate;

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIScrollViewDashboard *designScrollView;
@property (retain, nonatomic) IBOutlet UIButton *informationButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemInfo;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemSettings;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemObjects;
@property (retain, nonatomic) IBOutlet UINavigationItem *navBar;

- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;
- (IBAction)showSettings:(id)sender;

@end