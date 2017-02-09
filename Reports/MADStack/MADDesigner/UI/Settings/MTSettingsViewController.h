//
//  UITableViewControllerSettings.h
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTSettingsViewController_h
#define Reports_MTSettingsViewController_h

#import <UIKit/UITableViewController.h>
#import "MADViewControllerStandardProtocol.h"

@interface MTSettingsViewController : UITableViewController
    <UITableViewDelegate>

    @property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol> delegate;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellPrint;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellExport;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellFind;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellReportSetup;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellRuler;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellSettings;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellHelp;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableCellStore;

    - (IBAction)done:(id)sender;

@end

#endif
