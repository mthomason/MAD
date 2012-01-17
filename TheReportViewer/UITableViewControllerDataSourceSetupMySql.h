//
//  UITableViewControllerDataSourceSetupMySql.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerDataSourceSetupMySql;

@protocol UITableViewControllerDataSourceSetupMySqlDelegate
- (void)uITableViewControllerDataSourceSetupMySqlDidFinish:(UITableViewControllerDataSourceSetupMySql *)controller;
@end

@interface UITableViewControllerDataSourceSetupMySql : UITableViewController
    <UITableViewDelegate,
        UITextFieldDelegate>
@property (assign, nonatomic) IBOutlet id <UITableViewControllerDataSourceSetupMySqlDelegate> delegate;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellUsername;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellPassword;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellHost;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellPort;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTestConnection;

@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorTestConnection;
@property (retain, nonatomic) IBOutlet UITextField *textFieldUsername;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldHost;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPort;

- (void)test:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)usernameDidEndOnExit:(id)sender;
- (IBAction)passwordDidEndOnExit:(id)sender;
- (IBAction)hostDidEndOnExit:(id)sender;
- (IBAction)portDidEndOnExit:(id)sender;

@end