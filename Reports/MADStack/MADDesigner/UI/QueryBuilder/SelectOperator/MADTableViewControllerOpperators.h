//
//  UITableViewControllerOpperators.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewControllerOpperators_h
#define Reports_UITableViewControllerOpperators_h

#import <UIKit/UITableViewController.h>

@protocol MADTableViewControllerOpperatorsDelegate;

@class MADTableViewControllerOpperators;

@interface MADTableViewControllerOpperators : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate>

    @property (nonatomic, weak) IBOutlet id <MADTableViewControllerOpperatorsDelegate> delegate;

@end

#endif
