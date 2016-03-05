//
//  UITableViewControllerOpperators.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewControllerOpperators_h
#define Reports_UITableViewControllerOpperators_h

#import <UIKit/UIKit.h>
#import <MAD/RptqQueryPredicate+Extras.h>

@class UITableViewControllerOpperators;

@protocol UITableViewControllerOpperatorsDelegate
- (void)uITableViewControllerOpperatorsDidSelectOperator:(MNSPredicateOperator)operatorType;
@optional
- (void)uITableViewControllerOpperatorsDidFinish:(UITableViewControllerOpperators *)controller;
@end

@interface UITableViewControllerOpperators : UITableViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <UITableViewControllerOpperatorsDelegate> delegate;

@end

#endif
