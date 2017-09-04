//
//  MADConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADTdsClient_MADConnectionViewController_h
#define MADTdsClient_MADConnectionViewController_h

#import <UIKit/UITableViewController.h>
#import <MADAPI/MADDatabaseType.h>

@protocol MADViewControllerStandardProtocol, MADSaveFileProtocol;
@class MADDatabaseConnection;

@interface MADConnectionViewController : UITableViewController

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

    @property (nonatomic, assign) MADDatabaseType databaseType;

    @property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

    - (MADDatabaseConnection *)databaseConnection;

    - (void)enableUserInteraction;
    - (void)resetInterface;

@end

#endif
