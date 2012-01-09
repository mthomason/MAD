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

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIScrollViewDashboard *designScrollView;
@property (retain, nonatomic) IBOutlet UIButton *informationButton;

- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;

@end