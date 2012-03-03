//
//  UIViewControllerSchemaAddTable.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"
#import "UIManagedDocumentQuery.h"
#import "RptqTable.h"

@class UIViewControllerSchemaAddTable;

@protocol UIViewControllerSchemaAddTableDelegate
- (void)viewControllerSchemaAddTableDidFinish:(UIViewControllerSchemaAddTable *)controller;
- (void)viewControllerSchemaAddTableDidSelectTable:(RptqTable *)controller;
@end

@interface UIViewControllerSchemaAddTable : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddTableDelegate> delegate;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;
@property (copy) NSArray *excludeResults;

- (IBAction)done:(id)sender;

@end