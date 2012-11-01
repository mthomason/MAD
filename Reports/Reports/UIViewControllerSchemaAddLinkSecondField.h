//
//  UIViewControllerSchemaAddLink.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentQuery.h"
#import "UITableViewControllerCoreDataResults.h"

@class UIViewControllerSchemaAddLinkSecondField;

@protocol UIViewControllerSchemaAddLinkSecondFieldDelegate
- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(NSString *)result from:(UIManagedDocumentQuery *)document;
@end

@interface UIViewControllerSchemaAddLinkSecondField : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkSecondFieldDelegate> delegate;

@end