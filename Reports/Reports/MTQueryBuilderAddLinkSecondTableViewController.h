//
//  MTQueryBuilderAddLinkSecondTableViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkSecondTableViewController_h
#define Reports_MTQueryBuilderAddLinkSecondTableViewController_h

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"

@class MTQueryBuilderAddLinkSecondTableViewController, RptqQueryTable;

@protocol MTQueryBuilderAddLinkSecondTableDelegate
- (void)viewControllerDidFinishWithSecondTable:(RptqQueryTable *)result;
@end

@interface MTQueryBuilderAddLinkSecondTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkSecondTableDelegate> delegate;

@end

#endif
