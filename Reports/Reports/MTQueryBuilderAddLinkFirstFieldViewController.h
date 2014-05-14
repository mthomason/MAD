//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkFirstFieldViewController_h
#define Reports_MTQueryBuilderAddLinkFirstFieldViewController_h

#import <UIKit/UIKit.h>
#import "UITableViewControllerCoreDataResults.h"

@class MTQueryBuilderAddLinkFirstFieldViewController, RptqQueryField;

@protocol MTQueryBuilderAddLinkFirstFieldDelegate
- (void)viewControllerSchemaAddLinkFirstFieldDidFinishWith:(RptqQueryField *)result;
@end

@interface MTQueryBuilderAddLinkFirstFieldViewController : UITableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddLinkFirstFieldDelegate> delegate;

@end

#endif
