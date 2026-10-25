//
//  MADQueryBuilderAddTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryBuilderAddTableViewController_h
#define Reports_MADQueryBuilderAddTableViewController_h

#import "MADTableViewControllerCoreDataResults.h"
#import <MAD/RptqStoreContext.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>

@class MADQueryBuilderAddTableViewController;
@class RptqDatabaseSchemaTable;
@class RptqStoreContext;

@protocol MADQueryBuilderAddTableDelegate
- (void)viewController:(MADQueryBuilderAddTableViewController *)viewController addedQueryTableWithID:(int64_t)objectID;
@end

@interface MADQueryBuilderAddTableViewController : MADTableViewControllerCoreDataResults <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MADQueryBuilderAddTableDelegate, MADViewControllerStandardProtocol> delegate;
@property (nonatomic, copy) NSArray *excludeResults;
@property (nonatomic, weak) RptqStoreContext *managedObjectContext;

- (IBAction)done:(id)sender;

@end

#endif
