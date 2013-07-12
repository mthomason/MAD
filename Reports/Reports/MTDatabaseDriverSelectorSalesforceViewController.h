//
//  UITableViewControllerDataSourceSetupSalesforce.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseDriverSelectorSalesforceViewController_h
#define Reports_MTDatabaseDriverSelectorSalesforceViewController_h

#import <UIKit/UIKit.h>
#import "MTTableViewController.h"
#import "Constants.h"
#import "UIColor+EverydayApps.h"
#import "UIDevice+Hack.h"

@interface MTDatabaseDriverSelectorSalesforceViewController : MTTableViewController
    <UITableViewDelegate,
        UITextFieldDelegate>

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellNickname;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellConnectionCreate;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorTestConnection;
@property (nonatomic, retain) IBOutlet UITextField *textFieldNickname;

- (void)test:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)nicknameDidEndOnExit:(id)sender;

@end

#endif
