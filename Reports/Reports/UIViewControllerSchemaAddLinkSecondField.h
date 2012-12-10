//
//  UIViewControllerSchemaAddLink.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentReport.h"
#import "UITableViewControllerCoreDataResults.h"
#import "RptqTable.h"
#import "RptqField.h"

@class UIViewControllerSchemaAddLinkSecondField;

@protocol UIViewControllerSchemaAddLinkSecondFieldDelegate
- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(RptqField *)result;
@end

@interface UIViewControllerSchemaAddLinkSecondField : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkSecondFieldDelegate> delegate;

@end