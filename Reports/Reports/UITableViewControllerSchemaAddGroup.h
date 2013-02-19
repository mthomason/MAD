//
//  UITableViewControllerSchemaAddGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerSortType.h"
#import "UITableViewControllerChooseField.h"
#import "RptqQueryGroup.h"
#import "RptqField.h"
#import "MTManagedDocumentReport.h"

@class UITableViewControllerSchemaAddGroup;

@protocol UITableViewControllerSchemaAddGroupDelegate
- (void)uITableViewControllerSchemaAddGroupDidFinish:(UITableViewControllerSchemaAddGroup *)controller;
- (void)addGroupDidAddGroupWithField:(RptqField *)fieldName andSort:(MNSSortOrder)sortOrder;
@end

@interface UITableViewControllerSchemaAddGroup : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerSortTypeDelegate,
        UITableViewControllerChooseFieldDelegate>

@property (assign) IBOutlet id <UITableViewControllerSchemaAddGroupDelegate> delegate;

@property (retain) IBOutlet UITableViewCell *tableViewCellField;
@property (retain) IBOutlet UITableViewCell *tableViewCellSort;

@property (copy) NSString *fieldName;
@property (assign) MNSSortOrder sortOrder;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end