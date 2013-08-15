//
//  UITableViewControllerDataSourceSetupMySql.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorMySqlViewController_h
#define Reports_MTDatabaseDriverSelectorMySqlViewController_h

#import <UIKit/UIKit.h>
#import "MTTableViewController.h"
#import "NSError+UserInterface.h"
#import "MTDatabaseConnection.h"
#import "MAReportDocument.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "AppDelegate.h"
#import "NSURL+Document.h"
#import "MTAlertView.h"
#import "UIManagedDocument+FileOperations.h"

@interface MTDatabaseDriverSelectorMySqlViewController : MTTableViewController
    <UITableViewDelegate,
        UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellDocumentName;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellUsername;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellPassword;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellHost;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellPort;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellDatabase;

@property (nonatomic, retain) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;


@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorTestConnection;
@property (nonatomic, retain) IBOutlet UITextField *textFieldUsername;
@property (nonatomic, retain) IBOutlet UITextField *textFieldPassword;
@property (nonatomic, retain) IBOutlet UITextField *textFieldHost;
@property (nonatomic, retain) IBOutlet UITextField *textFieldPort;
@property (nonatomic, retain) IBOutlet UITextField *textFieldDatabase;
@property (nonatomic, retain) IBOutlet UITextField *textFieldReportName;

@property (nonatomic, copy) NSString *databaseType;

- (IBAction)save:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)usernameDidEndOnExit:(id)sender;
- (IBAction)passwordDidEndOnExit:(id)sender;
- (IBAction)hostDidEndOnExit:(id)sender;
- (IBAction)portDidEndOnExit:(id)sender;

@end

#endif
