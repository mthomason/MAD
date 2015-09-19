//
//  MTQueryBuilderSortTypeViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderSortTypeViewController_h
#define Reports_MTQueryBuilderSortTypeViewController_h

#import <UIKit/UIKit.h>
#import <MAD/MADSortOrder.h>

@class MTQueryBuilderSortTypeViewController;

@protocol MTQueryBuilderSortTypeDelegate
- (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller;
- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType;
@end

@interface MTQueryBuilderSortTypeViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderSortTypeDelegate> delegate;
@property (nonatomic, assign) MNSSortOrder initalSortOrder;

@end

#endif
