//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "RptqDatabaseSchemaField.h"

@class MTQueryBuilderAddLinkSecondFieldViewController;

@protocol MTQueryBuilderAddLinkSecondFieldDelegate
- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(RptqQueryField *)result;
@end

@interface MTQueryBuilderAddLinkSecondFieldViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkSecondFieldDelegate> delegate;

@end
