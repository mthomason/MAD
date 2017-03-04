//
//  MADQueryAddLinkJoinTypeController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryAddLinkJoinTypeController_h
#define Reports_MADQueryAddLinkJoinTypeController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADQueryLinkType.h>

@protocol MADQueryBuilderAddLinkJoinTypeDelegate;

@class MADocument;

@interface MADQueryAddLinkJoinTypeController : UITableViewController
    <UITableViewDelegate>

    @property (nonatomic, weak) id <MADQueryBuilderAddLinkJoinTypeDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
