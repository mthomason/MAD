//
//  MainViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "FlipsideViewController.h"
#import "ReportDesignerViewController.h"
#import "UIViewControllerTemplateSelector.h"
#import "UITableViewCellDocument.h"

@interface MainViewController : UIViewController
    <ReportDesignerViewControllerDelegate,
        FlipsideViewControllerDelegate,
        UIViewControllerTemplateSelectorDelegate,
        UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (strong, nonatomic) UIPopoverController *reportDesignerPopoverController;


@property (retain, nonatomic) IBOutlet UITableView *tableViewDocuments;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

@end