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
#import "Constants.h"
#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderAddGroupViewController, NSManagedObjectID;

@protocol MTQueryBuilderAddGroupDelegate
- (void)addQueryGroupWithQueryField:(NSManagedObjectID *)queryField andSortOrder:(MNSSortOrder)sortOrder;
@end

@interface MTQueryBuilderAddGroupViewController : UITableViewController
    <UITableViewDelegate,
        MTQueryBuilderSortTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property (nonatomic, assign) IBOutlet id <MTQueryBuilderAddGroupDelegate, MTViewControllerProtocol> delegate;

@property (retain) IBOutlet UITableViewCell *tableViewCellField;
@property (retain) IBOutlet UITableViewCell *tableViewCellSort;

@property (copy) NSString *fieldName;
@property (assign) MNSSortOrder sortOrder;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end

#endif
