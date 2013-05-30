//
//  UITableViewControllerSchemaAddGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "RptqQueryGroup.h"
#import "RptqDatabaseSchemaField.h"

@class MTQueryBuilderAddGroupViewController;

@protocol MTQueryBuilderAddGroupDelegate
- (void)uITableViewControllerSchemaAddGroupDidFinish:(MTQueryBuilderAddGroupViewController *)controller;
- (void)addGroupDidAddGroupWithQueryField:(RptqQueryField *)queryField andSort:(MNSSortOrder)sortOrder;
@end

@interface MTQueryBuilderAddGroupViewController : UITableViewController
    <UITableViewDelegate,
        MTQueryBuilderSortTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property (assign) IBOutlet id <MTQueryBuilderAddGroupDelegate> delegate;

@property (retain) IBOutlet UITableViewCell *tableViewCellField;
@property (retain) IBOutlet UITableViewCell *tableViewCellSort;

@property (copy) NSString *fieldName;
@property (assign) MNSSortOrder sortOrder;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
