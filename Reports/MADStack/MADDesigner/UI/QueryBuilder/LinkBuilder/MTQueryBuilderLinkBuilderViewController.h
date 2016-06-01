//
//  MTQueryBuilderLinkBuilderViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderLinkBuilderViewController_h
#define Reports_MTQueryBuilderLinkBuilderViewController_h

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "MADQueryBuilderAddLinkJoinTypeDelegate.h"
#import "MTQueryBuilderChooseFieldDelegate.h"
#import "MUIViewControllerDelegate.h"

#import "MADLinkPart.h"

@class MTQueryBuilderLinkBuilderViewController, RptqQueryLinks;

@protocol MTQueryBuilderLinkBuilderDelegate
    - (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)queryLink;
@end

@interface MTQueryBuilderLinkBuilderViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        MADQueryBuilderAddLinkJoinTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

    @property (nonatomic, weak) id <MTQueryBuilderLinkBuilderDelegate, MTViewControllerProtocol> queryLinkDelegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellJoinType;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

    @property (assign) MADLinkPart currentlyEditingPart;
    @property (assign) MNSLinkType linkType;

    - (IBAction)save:(id)sender;
    - (IBAction)cancel:(id)sender;

@end

#endif
