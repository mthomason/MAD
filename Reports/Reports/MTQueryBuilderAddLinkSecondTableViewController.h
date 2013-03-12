//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentReport.h"
#import "RptqDatabaseSchemaTable.h"
#import "UITableViewControllerCoreDataResults.h"

@class MTQueryBuilderAddLinkSecondTableViewController;

@protocol MTQueryBuilderAddLinkSecondTableDelegate
- (void)viewControllerDidFinishWithSecondTable:(RptqDatabaseSchemaTable *)result;
@end

@interface MTQueryBuilderAddLinkSecondTableViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkSecondTableDelegate> delegate;

@end