//
//  UITableViewControllerLinkBuilder.h
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "MTQueryBuilderAddLinkSecondTableViewController.h"
#import "MTQueryBuilderAddLinkFirstFieldViewController.h"
#import "MTQueryBuilderAddLinkSecondFieldViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryField+Extras.h"
#import "MTTableViewController.h"

@class MTQueryBuilderLinkBuilderViewController;

typedef NS_ENUM(NSUInteger, MNSLinkPart) {
	MNSLinkLeft = 0,
	MNSLinkCenter,
	MNSLinkRight,
	MNSLinkNone
};

@protocol MTQueryBuilderLinkBuilderDelegate
- (void)viewControllerSchemaAddLinkDidAdd:(RptqQueryLinks *)queryLink;
@end

@interface MTQueryBuilderLinkBuilderViewController : MTTableViewController
    <UITableViewDataSource, UITableViewDelegate,
        MTQueryBuilderAddLinkJoinTypeDelegate,
        MTQueryBuilderAddLinkFirstTableDelegate,
        MTQueryBuilderAddLinkFirstFieldDelegate,
        MTQueryBuilderAddLinkSecondTableDelegate,
        MTQueryBuilderAddLinkSecondFieldDelegate,
        MTQueryBuilderChooseFieldDelegate>

@property (assign, nonatomic) IBOutlet id <MTQueryBuilderLinkBuilderDelegate, MTViewControllerProtocol> delegate;

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellJoinType;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellTableOne;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFieldOne;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellTableTwo;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFieldTwo;

@property (assign) MNSLinkPart currentlyEditingPart;
@property (assign) MNSLinkType linkType;

- (IBAction)done:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end