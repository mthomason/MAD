//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "RptqDatabaseSchemaField+Extras.h"

@class MTQueryBuilderAddLinkFirstFieldViewController;

@protocol MTQueryBuilderAddLinkFirstFieldDelegate
- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqQueryField *)result;
@end

@interface MTQueryBuilderAddLinkFirstFieldViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkFirstFieldDelegate> delegate;

@end
