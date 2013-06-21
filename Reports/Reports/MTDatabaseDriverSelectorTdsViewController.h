//
//  MTDatabaseDriverSelectorTdsViewController.h
//  Reports
//
//  Created by Michael Thomason on 6/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorTdsViewController_h
#define Reports_MTDatabaseDriverSelectorTdsViewController_h

#import "MTTableViewController.h"

@interface MTDatabaseDriverSelectorTdsViewController : MTTableViewController
    <UITableViewDelegate,
        UITextFieldDelegate, UIAlertViewDelegate>

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellUsername;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellPassword;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellHost;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellPort;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellDatabase;

@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorTestConnection;
@property (retain, nonatomic) IBOutlet UITextField *textFieldUsername;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldHost;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPort;
@property (retain, nonatomic) IBOutlet UITextField *textFieldDatabase;
@property (retain, nonatomic) IBOutlet UITextField *textFieldReportName;

- (IBAction)save:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)usernameDidEndOnExit:(id)sender;
- (IBAction)passwordDidEndOnExit:(id)sender;
- (IBAction)hostDidEndOnExit:(id)sender;
- (IBAction)portDidEndOnExit:(id)sender;

@end

#endif
