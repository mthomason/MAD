//
//  MTConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTConnectionViewController_h
#define Reports_MTConnectionViewController_h

#import <UIKit/UIKit.h>
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import <MADExplorer/MADExplorer.h>
//#import <MAD/MADConstants.h>
//#import <MAD/MADocument.h>
//#import <MAD/MTKeyChain.h>
//#import <MAD/MTErrorContainer.h>
//#import <MAD/MTDatabaseConnection.h>
//#import <MAD/MTActivityIndicator.h>
#import "MUIViewControllerDelegate.h"
#import "MADViewController.h"

@interface MTConnectionViewController : MADTableViewController
    <UITableViewDelegate,
        UIViewControllerTransitioningDelegate,
        UIViewControllerAnimatedTransitioning,
        UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) IBOutlet id <MADSaveFileProtocol> saveFileDelegate;

@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDocumentName;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellHost;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellPort;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDatabase;

@property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;

@property (nonatomic, weak) IBOutlet UITextField *textFieldHost;
@property (nonatomic, weak) IBOutlet UITextField *textFieldPort;
@property (nonatomic, weak) IBOutlet UITextField *textFieldDatabase;
@property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

@property (nonatomic, copy) NSString *databaseType;

- (IBAction)save:(id)sender;

- (IBAction)usernameDidEndOnExit:(id)sender;
- (IBAction)hostDidEndOnExit:(id)sender;
- (IBAction)portDidEndOnExit:(id)sender;

@end

#endif
