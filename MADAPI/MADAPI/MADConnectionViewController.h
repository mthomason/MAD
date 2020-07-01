//
//  MADConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAPI_MADConnectionViewController_h
#define MADAPI_MADConnectionViewController_h

#import <UIKit/UIKit.h>

#import <UIKit/UITableViewController.h>
#import <MADAPI/MADDatabaseType.h>

#import <MADCocoaExtensions/MADProgressView.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@protocol MADViewControllerStandardProtocol, MADSaveFileProtocol;
@class MADDatabaseConnection;

@interface MADConnectionViewController : UITableViewController

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

    @property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

    @property (nonatomic, assign) MADDatabaseType databaseType;

    @property (nonatomic, readonly) NSString *displayName;

    - (MADDatabaseConnection *)databaseConnection;  // Build your custom database connection
                                                    //  based on the user input
    - (void)resetInterface;                         // Call super
    - (void)enableUserInteraction;                  // Call super

    - (void)removeKeyboard;
    - (void)disableTextFields;
    - (void)enableTextFields;

@end

#endif
