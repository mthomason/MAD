//
//  MADQueryBuilderAddTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryBuilderAddTableViewController_h
#define Reports_MADQueryBuilderAddTableViewController_h

#import "MADTableViewControllerCoreDataResults.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>

@class MADQueryBuilderAddTableViewController;
@class RptqDatabaseSchemaTable;
@class NSManagedObjectID;
@class NSManagedObjectContext;

@protocol MADQueryBuilderAddTableDelegate
- (void)viewController:(MADQueryBuilderAddTableViewController *)viewController addedQueryTableWithID:(NSManagedObjectID *)objectID;
@end

@interface MADQueryBuilderAddTableViewController : MADTableViewControllerCoreDataResults <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MADQueryBuilderAddTableDelegate, MADViewControllerStandardProtocol> delegate;
@property (nonatomic, copy) NSArray *excludeResults;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

- (IBAction)done:(id)sender;

@end

#endif
