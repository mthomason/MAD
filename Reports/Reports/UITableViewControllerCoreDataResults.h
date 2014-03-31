//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewControllerCoreDataResults_h
#define Reports_UITableViewControllerCoreDataResults_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MUIViewControllerDelegate.h"

@interface UITableViewControllerCoreDataResults : UITableViewController
    <NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) IBOutlet id <MTViewControllerProtocol> delegate;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;
@property BOOL debug;

- (void)performFetch;

@end

#endif
