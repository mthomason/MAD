//
//  UITableViewControllerSettings.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUITableViewController.h"
#import "AppDelegate.h"
@interface UITableViewControllerSettings : MUITableViewController
    <UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellPrint;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellExport;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellFind;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellReportSetup;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellRuler;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellSettings;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellHelp;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableCellStore;

- (IBAction)done:(id)sender;

@end