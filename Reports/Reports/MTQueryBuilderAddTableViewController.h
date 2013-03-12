//
//  UIViewControllerSchemaAddTable.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "MTManagedDocumentReport.h"
#import "RptqDatabaseSchemaTable.h"

@class MTQueryBuilderAddTableViewController;

@protocol MTQueryBuilderAddTableDelegate
- (void)viewControllerSchemaAddTableDidFinish:(MTQueryBuilderAddTableViewController *)controller;
- (void)viewControllerSchemaAddTableDidSelectTable:(RptqDatabaseSchemaTable *)controller;
@end

@interface MTQueryBuilderAddTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddTableDelegate> delegate;
@property (copy) NSArray *excludeResults;

- (IBAction)done:(id)sender;

@end