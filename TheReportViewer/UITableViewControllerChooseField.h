//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIViewTableSectionHeaderDatabaseTable.h"
#import "UIManagedDocumentQuery.h"
#import "RptqField.h"

@class UITableViewControllerChooseField;

@protocol UITableViewControllerChooseFieldDelegate
- (void)tableViewControllerChooseFieldDidFinish:(UITableViewControllerChooseField *)controller withField:(RptqField *)field;
@end

@interface UITableViewControllerChooseField : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        SectionHeaderViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerChooseFieldDelegate> delegate;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;
@property (retain) NSArray *excludeTables;

@property (nonatomic, assign) IBOutlet UITableViewCell *fieldCells;

@end