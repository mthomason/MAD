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

@class MADocument;

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;
extern NSString * const NSFetchedResultsCacheName;
extern NSString * const NSFetchedResultsCacheTables;
extern NSString * const NSFetchedResultsCacheLinks;
extern NSString * const NSFetchedResultsCacheGroups;
extern NSString * const NSFetchedResultsCachePredicates;

@interface MADQueryViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MADocument *document;

@property BOOL debug;

- (void)reloadDocument:(MADocument *)documentReport animated:(BOOL)animated;

- (IBAction)edit:(id)sender;

@end

#endif
