//
//  UITableViewControllerSettings.h
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTSettingsViewController_h
#define Reports_MTSettingsViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTSettingsViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, assign) IBOutlet id <MTViewControllerProtocol> delegate;

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

#endif
