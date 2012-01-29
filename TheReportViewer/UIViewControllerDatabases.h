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
#import "UIViewControllerSchemaTables.h"
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
        UIViewControllerSchemaTablesDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerDatabasesDelegate> delegate;
@property (strong, nonatomic) UIPopoverController *tableViewControllerDataSourceTypes;
@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

- (IBAction)done:(id)sender;

@end