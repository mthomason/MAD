//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIViewTableSectionHeaderDatabaseTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqFieldSelectorManager.h"
#import "RptqDatabaseSchemaTable+Extras.h"

@class MTQueryBuilderChooseFieldViewController;

@protocol MTQueryBuilderChooseFieldDelegate
- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field;
@end

@interface MTQueryBuilderChooseFieldViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        SectionHeaderViewDelegate>

@property (nonatomic, assign) IBOutlet id <MTQueryBuilderChooseFieldDelegate> delegate;
@property (assign) IBOutlet UITableViewCell *fieldCells;

@property (nonatomic, retain) RptqQueryField *queryField;
@property (nonatomic, retain) NSArray *excludeTables;

@end
