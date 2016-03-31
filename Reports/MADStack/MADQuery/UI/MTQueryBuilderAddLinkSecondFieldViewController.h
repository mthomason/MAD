//
//  MTQueryBuilderAddLinkSecondFieldViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkSecondFieldViewController_h
#define Reports_MTQueryBuilderAddLinkSecondFieldViewController_h

#import <UIKit/UIKit.h>
#import <MAD/MAD.h>
#import "MADTableViewControllerCoreDataResults.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderAddLinkSecondFieldViewController, RptqQueryField;

@protocol MTQueryBuilderAddLinkSecondFieldDelegate
- (void)viewControllerSchemaAddLinkDidSecondFieldFinishWith:(RptqQueryField *)result;
@end

@interface MTQueryBuilderAddLinkSecondFieldViewController : MADTableViewControllerCoreDataResults
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTQueryBuilderAddLinkSecondFieldDelegate> delegate;

@end

#endif
