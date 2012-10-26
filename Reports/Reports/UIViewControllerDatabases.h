//
//  FlipsideViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerDataSourceTypes.h"
#import "UITableViewCellDocument.h"
#import "MUIViewControllerQueryBuilder.h"
#import "UIViewControllerTemplateSelector.h"

@class UIViewControllerDatabases;

@protocol UIViewControllerDatabasesDelegate
- (void)flipsideViewControllerDidFinish:(UIViewControllerDatabases *)controller;
@end

@interface UIViewControllerDatabases : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate,
        UIViewControllerTemplateSelectorDelegate,
        UITableViewControllerDataSourceTypesDelegate,
        MUIViewControllerQueryBuilderDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerDatabasesDelegate> delegate;
@property (strong, nonatomic) UIPopoverController *tableViewControllerDataSourceTypes;
@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end