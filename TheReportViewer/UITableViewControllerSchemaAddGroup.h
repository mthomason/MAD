//
//  UITableViewControllerSchemaAddGroup.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerSortType.h"
#import "UITableViewControllerChooseField.h"
#import "RptqQueryGroup.h"
#import "UIManagedDocumentQuery.h"

@class UITableViewControllerSchemaAddGroup;

@protocol UITableViewControllerSchemaAddGroupDelegate
- (void)uITableViewControllerSchemaAddGroupDidFinish:(UITableViewControllerSchemaAddGroup *)controller;
- (void)uITableViewControllerSchemaAddGroupDidAddGroup:(RptqQueryGroup *)group;
- (void)addGroupDidAddGroupWithField:(NSString *)field andSort:(MNSSortOrder)sortOrder;
@end

@interface UITableViewControllerSchemaAddGroup : UITableViewController
    <UITableViewDelegate,
        UITableViewControllerSortTypeDelegate,
        UITableViewControllerChooseFieldDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerSchemaAddGroupDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellField;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellSort;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@property (retain) NSString *field;
@property (assign) MNSSortOrder sortOrder;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end