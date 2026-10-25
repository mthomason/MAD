//
//  MADTableViewControllerCoreDataResults.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADTableViewControllerCoreDataResults_h
#define Reports_MADTableViewControllerCoreDataResults_h

#import <UIKit/UITableViewController.h>

// Was an NSFetchedResultsController-backed table controller.  The store has no live
// query, so it now holds a plain array that subclasses fill and reloads on change
// (docs/project/MAD_STORE_PHASE_C.md §6).
@interface MADTableViewControllerCoreDataResults : UITableViewController

@property (nonatomic, strong) NSArray *results;
@property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

- (void)performFetch;

@end

#endif
