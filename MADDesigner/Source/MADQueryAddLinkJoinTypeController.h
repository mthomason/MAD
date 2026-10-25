//
//  MADQueryAddLinkJoinTypeController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryAddLinkJoinTypeController_h
#define Reports_MADQueryAddLinkJoinTypeController_h

#import <UIKit/UITableViewController.h>

@protocol MADQueryBuilderAddLinkJoinTypeDelegate;

@class MADocument;

@interface MADQueryAddLinkJoinTypeController : UITableViewController <UITableViewDelegate>

@property (nonatomic, weak) id <MADQueryBuilderAddLinkJoinTypeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
