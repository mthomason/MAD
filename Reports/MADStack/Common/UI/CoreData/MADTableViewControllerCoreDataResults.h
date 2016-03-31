//
//  MADTableViewControllerCoreDataResults.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTableViewControllerCoreDataResults_h
#define Reports_MADTableViewControllerCoreDataResults_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MADTableViewControllerCoreDataResults : UITableViewController
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
    @property (nonatomic, assign) bool suspendAutomaticTrackingOfChangesInManagedObjectContext;

    - (void)performFetch;

@end

#endif
