//
//  UIViewControllerSchemaAddLink.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqQueryLinks+Extras.h"

@class MTQueryBuilderAddLinkJoinTypeViewController;

@protocol MTQueryBuilderAddLinkJoinTypeDelegate
- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(MAReportDocument *)document;
@end

@interface MTQueryBuilderAddLinkJoinTypeViewController : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderAddLinkJoinTypeDelegate> delegate;

@end
