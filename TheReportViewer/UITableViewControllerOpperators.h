//
//  UITableViewControllerOpperators.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerOpperators;

@protocol UITableViewControllerOpperatorsDelegate
- (void)uITableViewControllerOpperatorsDidFinish:(UITableViewControllerOpperators *)controller;
- (void)uITableViewControllerOpperatorsDidSelectOperator:(NSPredicateOperatorType)operatorType;
@end

@interface UITableViewControllerOpperators : UITableViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerOpperatorsDelegate> delegate;

@end