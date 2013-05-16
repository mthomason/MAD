//
//  UITableViewControllerOpperators.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RptqQueryPredicate+Extras.h"

@class UITableViewControllerOpperators;

@protocol UITableViewControllerOpperatorsDelegate
- (void)uITableViewControllerOpperatorsDidSelectOperator:(MNSPredicateOperator)operatorType;
@optional
- (void)uITableViewControllerOpperatorsDidFinish:(UITableViewControllerOpperators *)controller;
@end

@interface UITableViewControllerOpperators : UITableViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerOpperatorsDelegate> delegate;

@end