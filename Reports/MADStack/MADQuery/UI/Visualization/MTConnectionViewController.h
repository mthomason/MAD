//
//  MADConnectionViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADConnectionViewController_h
#define MADDesigner_MADConnectionViewController_h

#import "MADViewController.h"
#import "MUIViewControllerDelegate.h"
#import <MADExplorer/MADSaveFileProtocol.h>

@interface MADConnectionViewController : MADTableViewController
    <UITableViewDelegate,
        UIViewControllerTransitioningDelegate,
        UIViewControllerAnimatedTransitioning,
        UITextFieldDelegate>


    @property (nonatomic, weak) id <MTViewControllerProtocol> delegate;
    @property (nonatomic, weak) id <MADSaveFileProtocol> saveFileDelegate;

    @property (nonatomic, copy) NSString *databaseType;

    - (IBAction)save:(id)sender;

    - (IBAction)usernameDidEndOnExit:(id)sender;
    - (IBAction)hostDidEndOnExit:(id)sender;
    - (IBAction)portDidEndOnExit:(id)sender;

@end

#endif
