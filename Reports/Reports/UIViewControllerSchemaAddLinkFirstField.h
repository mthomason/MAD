//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentReport.h"
#import "UITableViewControllerCoreDataResults.h"
#import "RptqTable.h"
#import "RptqField.h"

@class UIViewControllerSchemaAddLinkFirstField;

@protocol UIViewControllerSchemaAddLinkFirstFieldDelegate
- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqField *)result;
@end

@interface UIViewControllerSchemaAddLinkFirstField : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkFirstFieldDelegate> delegate;

@end