//
//  UITableViewControllerSortType.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@class UITableViewControllerSortType;

@protocol UITableViewControllerSortTypeDelegate
- (void)uITableViewControllerSortTypeDidFinish:(UITableViewControllerSortType *)controller;
- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType;
@end

@interface UITableViewControllerSortType : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSortTypeDelegate> delegate;

@end