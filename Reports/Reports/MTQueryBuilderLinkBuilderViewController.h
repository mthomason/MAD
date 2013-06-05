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

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellJoinType;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldOne;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellTableTwo;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellFieldTwo;

@property (assign) MNSLinkPart currentlyEditingPart;
@property (assign) MNSLinkType linkType;

- (IBAction)done:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end