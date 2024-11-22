//
//  UITableViewControllerOpperators.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
