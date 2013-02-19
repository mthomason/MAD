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

@class UIViewControllerSchemaAddLinkSecondTable;

@protocol UIViewControllerSchemaAddLinkSecondTableDelegate
- (void)viewControllerDidFinishWithSecondTable:(RptqTable *)result;
@end

@interface UIViewControllerSchemaAddLinkSecondTable : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkSecondTableDelegate> delegate;

@end