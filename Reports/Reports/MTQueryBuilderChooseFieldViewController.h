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
#import "MTManagedDocumentReport.h"
#import "RptqField.h"
#import "RptqFieldSelectorManager.h"
#import "RptqTable+Extras.h"

@class MTQueryBuilderChooseFieldViewController;

@protocol MTQueryBuilderChooseFieldDelegate
- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqField *)field;
@end

@interface MTQueryBuilderChooseFieldViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        SectionHeaderViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderChooseFieldDelegate> delegate;
@property (retain) NSArray *excludeTables;
@property (assign) IBOutlet UITableViewCell *fieldCells;

@end