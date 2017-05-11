//
//  MADTableViewControllerCoreDataResults.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTableViewControllerCoreDataResults_h
#define Reports_MADTableViewControllerCoreDataResults_h

#import <CoreData/NSFetchedResultsController.h>
#import <UIKit/UITableViewController.h>

@interface MADTableViewControllerCoreDataResults : UITableViewController
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
    @property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

    - (void)performFetch;

@end

#endif
