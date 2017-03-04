//
//  MADQueryBuilderAddTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryBuilderAddTableViewController_h
#define Reports_MADQueryBuilderAddTableViewController_h

#import "MADTableViewControllerCoreDataResults.h"
#import "MADViewControllerStandardProtocol.h"

@class MADQueryBuilderAddTableViewController;
@class RptqDatabaseSchemaTable;
@class NSManagedObjectID;

@protocol MADQueryBuilderAddTableDelegate
    - (void)viewControllerSchemaAddTableDidSelectTable:(NSManagedObjectID *)objectID;
@end

@interface MADQueryBuilderAddTableViewController : MADTableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

    @property (nonatomic, weak) IBOutlet id <MADQueryBuilderAddTableDelegate,
                                             MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, copy) NSArray *excludeResults;

    - (IBAction)done:(id)sender;

@end

#endif
