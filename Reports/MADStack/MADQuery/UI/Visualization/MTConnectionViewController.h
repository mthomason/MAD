//
//  MADConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADConnectionViewController_h
#define MADDesigner_MADConnectionViewController_h

#import <UIKit/UITableViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import <MAD/MADDatabaseConnection.h>

@protocol MADViewControllerStandardProtocol;
@protocol MADSaveFileProtocol;

@interface MADConnectionViewController : UITableViewController
    <UITableViewDelegate,
        UIViewControllerTransitioningDelegate,
        UIViewControllerAnimatedTransitioning,
        UITextFieldDelegate>


    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

    @property (nonatomic, assign) MADDatabaseType databaseType;

    - (IBAction)save:(id)sender;

    - (IBAction)usernameDidEndOnExit:(id)sender;
    - (IBAction)hostDidEndOnExit:(id)sender;
    - (IBAction)portDidEndOnExit:(id)sender;

@end

#endif
