//
//  MADQueryBuilderSortTypeViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryBuilderSortTypeViewController_h
#define Reports_MTQueryBuilderSortTypeViewController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADSortOrder.h>

@protocol MADQueryBuilderSortTypeDelegate;

@interface MADQueryBuilderSortTypeViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MADQueryBuilderSortTypeDelegate> delegate;
@property (nonatomic, assign) MADSortOrder initalSortOrder;

@end

#endif
