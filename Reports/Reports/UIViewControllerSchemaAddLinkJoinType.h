//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentReport.h"
#import "RptqQueryLinks+Extras.h"

@class UIViewControllerSchemaAddLinkJoinType;

@protocol UIViewControllerSchemaAddLinkJoinTypeDelegate
- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MTManagedDocumentReport *)document;
@end

@interface UIViewControllerSchemaAddLinkJoinType : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkJoinTypeDelegate> delegate;

@end