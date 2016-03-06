//
//  MTQueryBuilderLinkBuilderViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderLinkBuilderViewController_h
#define Reports_MTQueryBuilderLinkBuilderViewController_h

#import <UIKit/UIKit.h>
#import <MAD/MAD.h>

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"

#import "MTQueryBuilderChooseFieldDelegate.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderLinkBuilderViewController, RptqQueryLinks;

typedef NS_ENUM(NSUInteger, MNSLinkPart) {
	MNSLinkLeft = 0,
	MNSLinkCenter,
	MNSLinkRight,
	MNSLinkNone
};

@protocol MTQueryBuilderLinkBuilderDelegate
- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)queryLink;
@end

@interface MTQueryBuilderLinkBuilderViewController : UITableViewController
    <UITableViewDataSource, UITableViewDelegate,
        MTQueryBuilderAddLinkJoinTypeDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property (nonatomic, weak) id <MTQueryBuilderLinkBuilderDelegate, MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellJoinType;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

@property (assign) MNSLinkPart currentlyEditingPart;
@property (assign) MNSLinkType linkType;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end

#endif
