//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkFirstTableViewController_h
#define Reports_MTQueryBuilderAddLinkFirstTableViewController_h

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "MTQueryBuilderAddLinkFirstTableViewController.h"

@class MTQueryBuilderAddLinkFirstTableViewController, RptqQueryTable;

@protocol MTQueryBuilderAddLinkFirstTableDelegate
@optional
- (void)viewControllerDidFinishWithTable:(RptqQueryTable *)result;
@end

@interface MTQueryBuilderAddLinkFirstTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddLinkFirstTableDelegate> delegate;

- (IBAction)done:(id)sender;

@end

#endif
