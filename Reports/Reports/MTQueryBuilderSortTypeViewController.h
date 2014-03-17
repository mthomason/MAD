//
//  UITableViewControllerSortType.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@class MTQueryBuilderSortTypeViewController;

@protocol MTQueryBuilderSortTypeDelegate
- (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller;
- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType;
@end

@interface MTQueryBuilderSortTypeViewController : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderSortTypeDelegate> delegate;

@end
