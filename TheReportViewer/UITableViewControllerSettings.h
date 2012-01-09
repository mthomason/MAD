//
//  UITableViewControllerSettings.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerSettings;

@protocol UITableViewControllerSettingsDelegate
- (void)uIViewControllerSettingsDidFinish:(UITableViewControllerSettings *)controller;
@end

@interface UITableViewControllerSettings : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSettingsDelegate> delegate;
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