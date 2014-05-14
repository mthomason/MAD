//
//  UITableViewControllerSchemaAddGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddGroupViewController_h
#define Reports_MTQueryBuilderAddGroupViewController_h

#import <UIKit/UIKit.h>
#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderAddGroupViewController, NSManagedObjectID;

@protocol MTQueryBuilderAddGroupDelegate
- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryField andSortOrder:(MNSSortOrder)sortOrder;
- (void)viewControllerDidCancel:(id)sender;
@end

@interface MTQueryBuilderAddGroupViewController : UITableViewController
    <UITableViewDelegate,
        MTQueryBuilderSortTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddGroupDelegate> delegate;

@property (weak) IBOutlet UITableViewCell *tableViewCellField;
@property (weak) IBOutlet UITableViewCell *tableViewCellSort;

@property (copy) NSString *fieldName;
@property (assign) MNSSortOrder sortOrder;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end

#endif
