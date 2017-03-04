//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkFirstTableViewController_h
#define Reports_MTQueryBuilderAddLinkFirstTableViewController_h

#import "MADTableViewControllerCoreDataResults.h"

@class MTQueryBuilderAddLinkFirstTableViewController, RptqQueryTable;

@protocol MTQueryBuilderAddLinkFirstTableDelegate
@optional
    - (void)viewControllerDidFinishWithTable:(RptqQueryTable *)result;
@end

@interface MTQueryBuilderAddLinkFirstTableViewController : MADTableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

    @property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddLinkFirstTableDelegate> delegate;

    - (IBAction)done:(id)sender;

@end

#endif
