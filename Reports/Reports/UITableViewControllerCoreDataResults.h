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
#import "MTTableViewController.h"

@interface UITableViewControllerCoreDataResults : MTTableViewController
    <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (void)performFetch;

@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property BOOL debug;

@end

#endif
