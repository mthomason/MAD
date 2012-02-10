//
//  UITableViewControllerDataSourceSetupSalesforce.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDatabaseSalesForce.h"

@class UITableViewControllerDataSourceSetupSalesforce;

@protocol UITableViewControllerDataSourceSetupSalesforceDelegate
- (void)uITableViewControllerDataSourceSetupSalesforceDidFinish:(UITableViewControllerDataSourceSetupSalesforce *)controller;
@end

@interface UITableViewControllerDataSourceSetupSalesforce : UITableViewController
    <UITableViewDelegate,
        UITextFieldDelegate,
        NSDatabaseSalesForceDelegate>
@property (assign, nonatomic) IBOutlet id <UITableViewControllerDataSourceSetupSalesforceDelegate> delegate;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellNickname;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellConnectionCreate;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorTestConnection;
@property (retain, nonatomic) IBOutlet UITextField *textFieldNickname;

- (void)test:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)nicknameDidEndOnExit:(id)sender;

@end