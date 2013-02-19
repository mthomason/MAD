//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentReport.h"
#import "RptqTable.h"
#import "UITableViewControllerCoreDataResults.h"

@class UIViewControllerSchemaAddLinkFirstTable;

@protocol UIViewControllerSchemaAddLinkDelegate
@optional
- (void)viewControllerDidFinishWithTable:(RptqTable *)result;
@end

@interface UIViewControllerSchemaAddLinkFirstTable : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkDelegate> delegate;

- (IBAction)done:(id)sender;

@end