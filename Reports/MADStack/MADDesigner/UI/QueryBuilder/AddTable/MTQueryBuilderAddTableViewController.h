//
//  MTQueryBuilderAddTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddTableViewController_h
#define Reports_MTQueryBuilderAddTableViewController_h

#import "MADTableViewControllerCoreDataResults.h"
#import "MADViewControllerStandardProtocol.h"

@class MTQueryBuilderAddTableViewController;
@class RptqDatabaseSchemaTable;
@class NSManagedObjectID;

@protocol MTQueryBuilderAddTableDelegate
    - (void)viewControllerSchemaAddTableDidSelectTable:(NSManagedObjectID *)objectID;
@end

@interface MTQueryBuilderAddTableViewController : MADTableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

    @property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddTableDelegate, MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, copy) NSArray *excludeResults;

    - (IBAction)done:(id)sender;

@end

#endif
