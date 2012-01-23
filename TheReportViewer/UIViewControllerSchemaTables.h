//
//  UIViewControllerSchemaTables.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellOverride.h"
#import "UITableViewCellQueryInput.h"

@class UIViewControllerSchemaTables;

@protocol UIViewControllerSchemaTablesDelegate
- (void)uIViewControllerSchemaTablesDelegateDidFinish:(UIViewControllerSchemaTables *)controller;
@end

@interface UIViewControllerSchemaTables : UIViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (retain) NSDictionary *tableMetaData;

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaTablesDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableView *tableViewQueryBuilder;

@property (assign, nonatomic) IBOutlet UITableViewCellInstruction   *uITableViewCellInstruction;
@property (assign, nonatomic) IBOutlet UITableViewCellTableName     *uITableViewCellTableName;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryLink     *uITableViewCellQueryLink;
@property (assign, nonatomic) IBOutlet UITableViewCellOverride      *uITableViewCellOverride;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryInput    *uITableViewCellQueryInput;

- (IBAction)done:(id)sender;

@end