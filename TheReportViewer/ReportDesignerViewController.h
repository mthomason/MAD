//
//  ReportDesignerTableViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollViewDashboard.h"
#import "LabelInformationViewController.h"
#import "ImageInformationViewController.h"
#import "FormulaInformationViewController.h"

@class ReportDesignerViewController;

@protocol ReportDesignerViewControllerDelegate
- (void)reportDesignerViewControllerDidFinish:(ReportDesignerViewController *)controller;
@end

@interface ReportDesignerViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate,
        LabelInformationViewControllerDelegate,
        ImageInformationViewControllerDelegate,
        FormulaInformationViewControllerDelegate>

@property (assign, nonatomic) IBOutlet id <ReportDesignerViewControllerDelegate> delegate;

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIScrollViewDashboard *designScrollView;
@property (retain, nonatomic) IBOutlet UIButton *informationButton;

- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;

@end