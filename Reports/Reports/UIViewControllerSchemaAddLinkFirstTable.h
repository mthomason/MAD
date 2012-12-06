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

@class UIViewControllerSchemaAddLinkFirstTable;

@protocol UIViewControllerSchemaAddLinkDelegate
@optional
- (void)viewControllerSchemaAddLinkDidFinishWith:(NSString *)result from:(UIManagedDocumentReport *)document;
@end

@interface UIViewControllerSchemaAddLinkFirstTable : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkDelegate> delegate;

- (IBAction)done:(id)sender;

@end