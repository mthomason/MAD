//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentReport.h"
#import "UITableViewControllerCoreDataResults.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

@class MTQueryBuilderAddLinkFirstFieldViewController;

@protocol MTQueryBuilderAddLinkFirstFieldDelegate
- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqDatabaseSchemaField *)result;
@end

@interface MTQueryBuilderAddLinkFirstFieldViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkFirstFieldDelegate> delegate;

@end