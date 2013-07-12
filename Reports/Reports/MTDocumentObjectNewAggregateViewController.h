//
//  MTDocumentObjectNewAggregateViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MTAggregateFunctionsViewController.h"

extern NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier;

@interface MTDocumentObjectNewAggregateViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggrageFunction;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggregateInput;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggregateGroupBy;

@end
