//
//  MADTableViewControllerCoreDataResults.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTableViewControllerCoreDataResults_h
#define Reports_MADTableViewControllerCoreDataResults_h

#import <UIKit/UITableViewController.h>

@class NSFetchedResultsController;

@interface MADTableViewControllerCoreDataResults : UITableViewController

    @property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
    @property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

    - (void)performFetch;

@end

#endif
