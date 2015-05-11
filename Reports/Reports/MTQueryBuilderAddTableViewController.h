//
//  MTQueryBuilderAddTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddTableViewController_h
#define Reports_MTQueryBuilderAddTableViewController_h

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderAddTableViewController, RptqDatabaseSchemaTable;

@protocol MTQueryBuilderAddTableDelegate
- (void)viewControllerSchemaAddTableDidSelectTable:(RptqDatabaseSchemaTable *)schemaTable;
@end

@interface MTQueryBuilderAddTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddTableDelegate, MTViewControllerProtocol> delegate;
@property (nonatomic, copy) NSArray *excludeResults;

- (IBAction)done:(id)sender;

@end

#endif
