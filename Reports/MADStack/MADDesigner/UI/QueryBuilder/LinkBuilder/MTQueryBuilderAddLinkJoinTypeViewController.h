//
//  MTQueryBuilderAddLinkJoinTypeViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderAddLinkJoinTypeViewController_h
#define Reports_MTQueryBuilderAddLinkJoinTypeViewController_h

#import <UIKit/UIKit.h>
#import <MAD/MAD.h>
#import <MAD/MTDatabaseConnection.h>

@class MTQueryBuilderAddLinkJoinTypeViewController, MADocument;

@protocol MTQueryBuilderAddLinkJoinTypeDelegate

- (MNSLinkType)initalLinktype;
- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith: (MNSLinkType)result
                                                    from: (MADocument *)document;

@end

@interface MTQueryBuilderAddLinkJoinTypeViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, weak) id <MTQueryBuilderAddLinkJoinTypeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
