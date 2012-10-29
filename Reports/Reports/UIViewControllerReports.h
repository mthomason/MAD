//
//  MainViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewControllerDatabases.h"
#import "ReportDesignerViewController.h"
#import "UIViewControllerTemplateSelector.h"
#import "UITableViewCellDocument.h"

@interface UIViewControllerReports : UIViewController
    <ReportDesignerViewControllerDelegate,
        UIViewControllerDatabasesDelegate,
        UIViewControllerTemplateSelectorDelegate,
        UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate>

@property (nonatomic, retain) NSMutableArray *availableFilesCache;

@property (retain, nonatomic) UIPopoverController *flipsidePopoverController;
@property (retain, nonatomic) UIPopoverController *reportDesignerPopoverController;
@property (retain, nonatomic) UIPopoverController *templateSelectorPopoverController;

@property (retain, nonatomic) IBOutlet UITableView *tableViewDocuments;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

@end