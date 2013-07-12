//
//  UITableViewControllerSettings.h
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTTableViewController.h"
#import "AppDelegate.h"

@interface MTSettingsViewController : MTTableViewController
    <UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellPrint;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellExport;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellFind;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellReportSetup;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellRuler;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellSettings;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellHelp;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableCellStore;

- (IBAction)done:(id)sender;

@end