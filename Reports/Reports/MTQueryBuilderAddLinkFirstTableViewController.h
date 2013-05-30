//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqDatabaseSchemaTable.h"
#import "UITableViewControllerCoreDataResults.h"
#import "RptqQueryTable.h"

@class MTQueryBuilderAddLinkFirstTableViewController;

@protocol MTQueryBuilderAddLinkFirstTableDelegate
@optional
- (void)viewControllerDidFinishWithTable:(RptqQueryTable *)result;
@end

@interface MTQueryBuilderAddLinkFirstTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkFirstTableDelegate> delegate;

- (IBAction)done:(id)sender;

@end
