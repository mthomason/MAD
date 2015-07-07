//
//  MADQueryViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryViewController_h
#define Reports_MADQueryViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"
#import "MADViewController.h"

@class MADocument;

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;
extern NSString * const MADSegueShowSql;

@interface MADQueryViewController : MADTableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

@property BOOL debug;

- (void)reloadDocument:(MADocument *)documentReport animated:(BOOL)animated;

- (IBAction)edit:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)unwindToQueryBuilder:(UIStoryboardSegue *)action;

@end

#endif
