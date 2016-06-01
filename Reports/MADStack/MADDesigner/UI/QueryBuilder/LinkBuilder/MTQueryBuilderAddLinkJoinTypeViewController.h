//
//  MTQueryBuilderAddLinkJoinTypeViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkJoinTypeViewController_h
#define Reports_MTQueryBuilderAddLinkJoinTypeViewController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADQueryLinkType.h>

@protocol MADQueryBuilderAddLinkJoinTypeDelegate;

@class MTQueryBuilderAddLinkJoinTypeViewController;
@class MADocument;

@interface MTQueryBuilderAddLinkJoinTypeViewController : UITableViewController
    <UITableViewDelegate>

    @property (nonatomic, weak) id <MADQueryBuilderAddLinkJoinTypeDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
